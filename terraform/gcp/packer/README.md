# GCP custom image builders (Packer)

Packer templates that build the custom GCE images GCP's VM/MIG-tier
composition modules need. These are **not** Terraform modules — they're
never consumed via a `module` block or a `terragrunt source = "git::..."`
ref, so they live here as a sibling to `../modules/`, not nested inside it.
Each template builds an image and hands off a plain image name/self-link;
the consuming composition module takes that as an input variable and knows
nothing about how it was built.

GCP's managed-instance-group model has no userdata-only path the way AWS's
ASG + `custom_userdata` does (see the AWS composition modules of the same
name, which only ever template config into an *already-installed* binary at
boot) — on GCP the binary has to be baked into the image itself, hence a
Packer build step per VM-tier component.

## Image → composition module mapping

| Image dir | Consuming composition module | Terraform input it feeds |
|---|---|---|
| [`envoy-proxy/`](./envoy-proxy) | `../modules/composition/envoy-proxy` | `envoy_image` |
| [`squid-proxy/`](./squid-proxy) | `../modules/composition/squid-proxy` | `squid_image` |

Directory names match the composition module name exactly (not shortened,
e.g. `envoy-proxy` not `envoy`) so the mapping stays 1:1 and greppable.

Add a row here whenever a new VM-tier component gets a Packer-built image.

# Building the Envoy and Squid images

This is the first thing to do on a new GCP project, **before** applying the
stack: `envoy-proxy` and `squid-proxy` will not `apply` until the images
exist. You do not need to deploy the Hyperswitch VPC first.

The stack takes image **names** in `custom_images`
(`terraform/gcp/live/terragrunt.stack.hcl`) and expands each to
`projects/<project_id>/global/images/<name>`, so the images must be in the
same project as the stack.

Time: about 6 minutes, and both builds can run in parallel. Cost: a temporary
`e2-medium` VM per build, deleted automatically.

## Prerequisites

- A GCP project with the Compute Engine API enabled
- `packer` (1.10+), `gcloud` and `jq`
- Permission to create Compute Engine instances and images in the project

```bash
gcloud auth login
gcloud auth application-default login   # Packer reads application default credentials
gcloud config set project <PROJECT_ID>
gcloud services enable compute.googleapis.com
```

## Choose a build network

The build VM needs outbound internet (`apt`, Docker Hub for Envoy, the Vector
package repository) and SSH from your machine.

| Network | Internet | SSH | Use when |
|---|---|---|---|
| **`default` network (recommended)** | temporary public IP | `default-allow-ssh` | the project still has the `default` network |
| Throwaway custom network | temporary public IP | firewall rule you create | the organisation blocks the `default` network |
| The stack's VPC | Cloud NAT from `vpc-network` | IAP | rebuilding in an already-deployed environment |

```bash
gcloud compute networks list
gcloud compute networks subnets list --network default --filter="region:<REGION>"
```

An image is a global project resource and carries no network configuration, so
an image built on `default` works unchanged in the stack's VPC.

If `default` does not exist (usually the `compute.skipDefaultNetworkCreation`
organisation policy), create a throwaway network and delete it afterwards:

```bash
gcloud compute networks create packer-build --subnet-mode=custom
gcloud compute networks subnets create packer-build \
  --network=packer-build --region=<REGION> --range=10.250.0.0/24
gcloud compute firewall-rules create packer-build-ssh \
  --network=packer-build --allow=tcp:22 \
  --source-ranges=<YOUR_PUBLIC_IP>/32 --target-tags=packer-build
```

and use `network = "packer-build"`, `subnetwork = "packer-build"` below. The
templates add the `packer-build` tag automatically when `use_iap = false`.

## Build

```bash
cd terraform/gcp/packer

for c in envoy-proxy squid-proxy; do
  cat > "$c/dev.auto.pkrvars.hcl" <<EOF
project_id  = "<PROJECT_ID>"
zone        = "<REGION>-a"
network     = "default"
subnetwork  = "default"
use_iap     = false
environment = "dev"
EOF
done

(cd envoy-proxy && packer init . && packer build .) &
(cd squid-proxy && packer init . && packer build .) &
wait
```

- `use_iap = false` uses a temporary public IP. The default (`true`) uses an
  IAP tunnel, which does not complete the SSH handshake for Ubuntu images
  ([hashicorp/packer#12169](https://github.com/hashicorp/packer/issues/12169)).
- `environment` becomes part of the image name and family; use the
  environment you will deploy.
- Every other variable has a working default: `ubuntu-2204-lts`, `e2-medium`,
  20 GB `pd-balanced`, Envoy `v1.39.0`.
- Squid bakes in `vector_loki_endpoint` (default `http://loki.hyperswitch.internal`,
  which does not resolve outside Hyperswitch's own network). Set it in
  `squid-proxy/dev.auto.pkrvars.hcl` if you run Loki. Changing it needs a rebuild.
- If you change the module's `http_port`, `https_port` or `mtls_port`, pass
  the matching `envoy_http_port`, `envoy_https_port` and `envoy_mtls_port` so
  `ufw` allows them.

## Get the image names

```bash
jq -r '.builds[-1].artifact_id' envoy-proxy/packer-manifest.json
jq -r '.builds[-1].artifact_id' squid-proxy/packer-manifest.json

gcloud compute images list --no-standard-images \
  --filter="labels.managed_by=packer" \
  --format="table(name,family,status,labels.component)"
```

Both must be `READY`. Put the **full timestamped name** (not the family; the
Envoy module rejects families) into the stack:

```hcl
custom_images = {
  envoy = "hyperswitch-envoy-dev-20261005101429"
  squid = "hyperswitch-squid-dev-20261005101429"
}
```

## Verify (optional)

Boot a throwaway VM from each image and read the result from the serial
console. No SSH and no external IP needed.

```bash
cat > verify.sh <<'EOF'
#!/bin/bash
sleep 25
{
  echo VERIFY-BEGIN
  envoy --version 2>&1 | head -2
  squid -v 2>&1 | head -1
  vector --version 2>&1
  for u in envoy squid vector; do echo "$u enabled=$(systemctl is-enabled $u 2>&1) active=$(systemctl is-active $u 2>&1)"; done
  echo VERIFY-END
} > /dev/ttyS0
EOF

gcloud compute instances create verify-envoy --zone <REGION>-a --machine-type e2-small \
  --network default --subnet default --no-address \
  --image <ENVOY_IMAGE_NAME> --metadata-from-file startup-script=verify.sh
gcloud compute instances create verify-squid --zone <REGION>-a --machine-type e2-small \
  --network default --subnet default --no-address \
  --image <SQUID_IMAGE_NAME> --metadata-from-file startup-script=verify.sh

# after about 90 seconds
for c in envoy squid; do
  gcloud compute instances get-serial-port-output verify-$c --zone <REGION>-a \
    | sed -n '/VERIFY-BEGIN/,/VERIFY-END/p'
done

gcloud compute instances delete verify-envoy verify-squid --zone <REGION>-a --quiet
```

| Image | Expected |
|---|---|
| Envoy | `envoy` binary present, `vector` enabled and `active`, `envoy` enabled and **`activating`** |
| Squid | `Squid Cache: Version 5.9`, `squid` and `vector` enabled and `active` |

Envoy is expected to be `activating`: the image ships no `envoy.yaml`, and the
service restarts on failure until the `envoy-proxy` unit's startup script
downloads the real configuration from its config bucket during `apply`.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Timeout waiting for SSH` | no SSH path to the build VM | use `default` with `use_iap = false`, or open SSH from your IP to the `packer-build` tag |
| IAP handshake never completes | hashicorp/packer#12169 | `use_iap = false` |
| build fails saying the network is not found | no `default` network | use a throwaway network |
| `apt-get` or `docker pull` fails | no outbound internet | the VM needs a public IP or Cloud NAT |
| leftover VM after an interrupted build | Packer was killed | `gcloud compute instances list --filter="name~packer"`, then delete it |

## Rebuilding

Run the build again and update `custom_images` with the new names. Delete old
images once no instance group uses them. Packer deletes its own build VM;
remove the throwaway network and firewall rule if you created them.

Each template's own README describes what that image contains:
[`envoy-proxy/`](./envoy-proxy), [`squid-proxy/`](./squid-proxy).
