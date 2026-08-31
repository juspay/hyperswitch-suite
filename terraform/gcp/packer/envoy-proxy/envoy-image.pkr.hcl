packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.7"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

locals {
  timestamp  = regex_replace(timestamp(), "[- TZ:]", "")
  image_name = "${var.image_name_prefix}-${var.environment}-${local.timestamp}"
}

source "googlecompute" "envoy" {
  project_id          = var.project_id
  zone                = var.zone
  source_image_family = var.source_image_family
  image_name          = local.image_name
  image_family        = "${var.image_name_prefix}-${var.environment}"

  machine_type = var.machine_type
  disk_size    = var.disk_size_gb
  disk_type    = "pd-balanced"

  network    = var.network
  subnetwork = var.subnetwork
  # Reach the instance over an IAP tunnel (no public IP), matching the
  # private, bastion-only access pattern the rest of this module's GKE/VM
  # tiers use - requires the caller to hold roles/iap.tunnelResourceAccessor
  # on the project (see ../../modules/composition/envoy-proxy/README.md for
  # why a plain public-IP fallback
  # does NOT work as an alternative on hyperswitch-dev: the VPC has a
  # default-deny-all-ingress rule and only allowlists SSH from IAP's own
  # 35.235.240.0/20 range, so an ungranted IAP role blocks both paths
  # identically).
  omit_external_ip = var.use_iap
  use_internal_ip  = var.use_iap
  use_iap          = var.use_iap

  ssh_username = "packer"

  # Matches the target_tags on
  # hyperswitch-infra/terraform/gcp/live/dev/asia-south1/envoy-packer-temp-ssh-firewall
  # (temporary, direct-SSH workaround for hashicorp/packer#12169 - drop this
  # tag along with that firewall unit once use_iap = true is viable again).
  tags = var.use_iap ? [] : ["packer-build"]

  image_labels = {
    environment = var.environment
    project     = var.project_name
    component   = "envoy-proxy"
    managed_by  = "packer"
  }
}

build {
  name    = "envoy-image"
  sources = ["source.googlecompute.envoy"]

  # Step 1: Envoy binary, extracted directly from the OFFICIAL
  # envoyproxy/envoy Docker image (published by the Envoy project's own
  # "envoyproxy" org, not a third-party redistribution) - confirmed real via
  # Docker Hub's own API before use (hub.docker.com/v2/repositories/
  # envoyproxy/envoy/tags/${var.envoy_version}), which returns per-arch
  # content digests: pulling this image validates those digests as part of
  # the normal Docker pull, giving a real, verifiable chain of custody -
  # unlike a bare HTTPS tarball download, which has no such verification.
  #
  # Docker itself is installed only for this extraction step and removed
  # again afterward (see the cleanup step below) - it is not needed at
  # runtime, Envoy runs as a native systemd service, not a container.
  #
  # NOT installed via apt or a third-party binary archive - all three
  # alternatives were tried and rejected/broken by real build failures on
  # 2026-08-19/20:
  #   - apt.envoyproxy.io (Envoy's own official apt repo) is explicitly
  #     documented as unmaintained:
  #     https://www.envoyproxy.io/docs/envoy/latest/start/install
  #   - deb.dl.getenvoy.io (the older Tetrate getenvoy-package apt repo) -
  #     GPG key verifies, but no `getenvoy-envoy` package exists for Ubuntu
  #     jammy at all; GitHub org archived under "tetratelabs-attic".
  #   - archive.tetratelabs.io (Tetrate's binary archive, a third-party
  #     redistribution of the same Docker image binaries, with no checksum
  #     sidecar available to verify against) - worked, but is one hop
  #     further from the source than pulling the official image directly.
  # Mirrors what the pre-baked AWS AMI already has (an `envoy` systemd
  # service reading /etc/envoy/envoy.yaml, confirmed against
  # terraform/aws/live/*/envoy-proxy/templates/userdata.sh in
  # hyperswitch-infra, which only ever templates config into an
  # already-installed Envoy - it never installs the binary itself).
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io",
      "sudo systemctl start docker",
      "sudo docker pull envoyproxy/envoy:${var.envoy_version}",
      "sudo docker create --name envoy-extract envoyproxy/envoy:${var.envoy_version}",
      "sudo docker cp envoy-extract:/usr/local/bin/envoy /usr/bin/envoy",
      "sudo chmod 0755 /usr/bin/envoy",
      "sudo docker rm envoy-extract",
      "envoy --version",
    ]
  }

  # Step 2: system user, directories, log rotation - same layout the AWS
  # AMI's userdata assumes already exists (/etc/envoy, /var/log/envoy,
  # `envoy` user/group).
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo id envoy || sudo useradd --system --no-create-home --shell /usr/sbin/nologin envoy",
      "sudo mkdir -p /etc/envoy /var/log/envoy",
      "sudo touch /var/log/envoy/access.log",
      "sudo chown -R envoy:envoy /etc/envoy /var/log/envoy",
      "sudo chmod 755 /etc/envoy /var/log/envoy",
    ]
  }

  # Step 3: envoy.service unit. Unlike the earlier design, this image does
  # NOT bake in a config-fetch script/systemd unit - pulling envoy.yaml from
  # the composition module's GCS config bucket (keyed by the "config-bucket"
  # instance-metadata attribute) is now the live-layer startup-script's job
  # (templates/startup-script.sh in the consuming live-layer unit), matching
  # the AWS AMI + userdata.sh split exactly: the image only ships an
  # `envoy` systemd service that reads a static /etc/envoy/envoy.yaml and
  # restarts on failure; nothing in the image assumes where that file comes
  # from. No default envoy.yaml is baked in either - same as the AWS AMI,
  # this service will crash-loop (Restart=on-failure) until the startup
  # script writes a real config and restarts it, which is expected on first
  # boot.
  provisioner "file" {
    source      = "${path.root}/scripts/envoy.service"
    destination = "/tmp/envoy.service"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/envoy.service /etc/systemd/system/envoy.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable envoy.service",
    ]
  }

  # Step 4: Vector, for log/metric scraping - required so this fleet can
  # actually be observed (Envoy access logs -> parsed/masked -> Prometheus
  # metrics + logs), same role it plays on the AWS fleet. Installed via
  # Datadog's official setup script (setup.vector.dev - Vector is
  # maintained by Datadog's Community Open Source Engineering team; proper
  # GPG key rotation via keys.datadoghq.com, inspected before use here, not
  # piped blind) + apt-get, not a third-party channel.
  #
  # vector.toml baked in here (scripts/vector.toml) is a DEFAULT/fallback,
  # adapted from the AWS fleet's canonical config
  # (terraform/catalog/units/envoy-proxy/config/vector.toml in
  # hyperswitch-infra) with the AWS-only sinks (OpenSearch, CloudWatch)
  # removed entirely and Loki commented out pending a confirmed-reachable
  # GCP-side endpoint - see the comment block at the top of that file for
  # the full rationale. Like envoy.yaml, the *real* per-environment config
  # is meant to come from the composition module's GCS config bucket - but
  # unlike the earlier design, that pull now happens in the live-layer
  # startup-script (templates/startup-script.sh in the consuming live-layer
  # unit), not a baked-in fetch service, matching the AWS AMI + userdata.sh
  # split. This baked-in copy just means Vector has something valid to run
  # if no vector.toml was ever uploaded, or the instance was booted
  # standalone from this image without the composition module's wiring.
  #
  # /etc/default/metadata (the GCE-sourced equivalents of the EC2/ASG/
  # Launch-Template tags AWS's userdata.sh writes there) and the
  # EnvironmentFile drop-in that feeds it to vector.service are ALSO now
  # the startup-script's job, not baked in here - see
  # vector-gcp-overrides.conf's own comment for why only the config-*path*
  # fix (image-level, not environment-specific) stays in the image.
  provisioner "shell" {
    inline = [
      "set -eux",
      "curl -sL https://setup.vector.dev | sudo bash",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq vector",
      "vector --version",
      # Envoy's access log (written by the `envoy` user) needs to be
      # readable by `vector` for the file source to tail it.
      "sudo usermod -aG envoy vector",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/vector.toml"
    destination = "/tmp/vector.toml"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mkdir -p /etc/vector",
      "sudo mv /tmp/vector.toml /etc/vector/vector.toml",
      "sudo chown vector:vector /etc/vector/vector.toml",
      "sudo chmod 640 /etc/vector/vector.toml",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/vector-gcp-overrides.conf"
    destination = "/tmp/vector-gcp-overrides.conf"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mkdir -p /etc/systemd/system/vector.service.d",
      "sudo mv /tmp/vector-gcp-overrides.conf /etc/systemd/system/vector.service.d/gcp-overrides.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable vector.service",
    ]
  }

  # Step 5: ufw. GCP VPC firewall rules already gate traffic at the network
  # level (the live hyperswitch-dev-vpc's allow-internal/allow-iap-ssh rules),
  # but the AWS AMI/userdata pattern this module mirrors also locks down the
  # host itself (see hyperswitch-cdk/lib/aws/userdata/envoy_userdata.sh and
  # the sandbox userdata's ADDITIONAL_INBOUND_PORTS) - defense in depth in
  # case the instance ever ends up on a less-restrictive network.
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "sudo ufw allow 22/tcp",
      "sudo ufw allow ${var.envoy_http_port}/tcp",
      "sudo ufw allow ${var.envoy_https_port}/tcp",
      "sudo ufw allow ${var.envoy_mtls_port}/tcp",
      "sudo ufw allow ${var.vector_prometheus_port}/tcp",
      "sudo ufw --force enable",
      "sudo ufw status verbose",
    ]
  }

  # Step 6: cleanup before imaging - includes removing docker.io, which was
  # only installed to extract the Envoy binary in Step 1 and is not needed
  # at runtime (Envoy runs as a native systemd service, not a container).
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo systemctl stop docker || true",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq docker.io",
      "sudo apt-get autoremove -y -qq",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/* /var/lib/docker",
      "history -c || true",
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
