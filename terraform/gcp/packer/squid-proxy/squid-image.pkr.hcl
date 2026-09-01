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

source "googlecompute" "squid" {
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
  # Reach the instance over an IAP tunnel (no public IP) when possible - see
  # ../envoy-proxy/envoy-image.pkr.hcl for the full rationale.
  # use_iap = true is currently broken for Ubuntu source images
  # (hashicorp/packer#12169 - IAP tunnel connects but the SSH handshake
  # never completes); set use_iap = false to fall back to a temporary
  # public IP for the build only (the built image itself never gets a
  # public IP - that's a live-layer concern, not this build's).
  omit_external_ip = var.use_iap
  use_internal_ip  = var.use_iap
  use_iap          = var.use_iap

  ssh_username = "packer"

  # Matches the target_tags on
  # hyperswitch-infra/terraform/gcp/live/dev/asia-south1/envoy-packer-temp-ssh-firewall
  # (temporary, direct-SSH workaround for hashicorp/packer#12169, shared
  # across both the Envoy and Squid image builds since the firewall rule is
  # tag-based, not image-specific - drop this tag along with that firewall
  # unit once use_iap = true is viable again).
  tags = var.use_iap ? [] : ["packer-build"]

  image_labels = {
    environment = var.environment
    project     = var.project_name
    component   = "squid-proxy"
    managed_by  = "packer"
  }
}

build {
  name    = "squid-image"
  sources = ["source.googlecompute.squid"]

  # Step 1: Squid from the Ubuntu apt repo. Unlike Envoy there's no
  # first-party upstream repo to pin a version from - Ubuntu 22.04's
  # `squid` package is what ../../../aws/modules/composition/squid-proxy's
  # AMI is built on too (see hyperswitch-infra's squid-proxy userdata.sh,
  # which only ever templates config into an already-installed Squid).
  #
  # `cloud-init status --wait` first: confirmed via a real failed build
  # (`E: Unable to correct problems, you have held broken packages`,
  # reproduced twice) that Packer's shell provisioner can start running
  # before cloud-init's own first-boot apt/dpkg activity on this image has
  # finished, racing for the dpkg lock. A manual SSH session a few minutes
  # into boot never hit this - only the tight Packer timing did. Waiting
  # for cloud-init to fully settle avoids the race instead of masking it
  # with a lock-retry loop.
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo cloud-init status --wait",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq squid",
      "squid -v",
    ]
  }

  # Step 2: config-fetch script + systemd unit. The composition module
  # (../../modules/composition/squid-proxy/main.tf) writes the rendered
  # squid.conf into a GCS config bucket and
  # passes its name via instance metadata key "config-bucket" - this script
  # pulls that object at boot, the GCP equivalent of the AWS AMI's userdata
  # `aws s3 cp .../squid.conf` step.
  provisioner "file" {
    source      = "${path.root}/scripts/fetch-squid-config.sh"
    destination = "/tmp/fetch-squid-config.sh"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/fetch-squid-config.sh /usr/local/bin/fetch-squid-config.sh",
      "sudo chmod +x /usr/local/bin/fetch-squid-config.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/squid-config-fetch.service"
    destination = "/tmp/squid-config-fetch.service"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/squid-config-fetch.service /etc/systemd/system/squid-config-fetch.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable squid-config-fetch.service",
      "sudo systemctl enable squid.service",
    ]
  }

  # Step 2b: whitelist-fetch script + cron, matching the AWS AMI's
  # userdata.sh `update_whitelist.sh` + `*/15 * * * * root
  # /etc/squid/update_whitelist.sh` cron line - pulls allowedlist.txt from
  # the same config bucket and runs `squid -k reconfigure`, so a whitelist
  # edit (squid_allowlist_content on the live-layer unit) takes effect on
  # a live fleet without an instance replacement/refresh. `cron` ships
  # active-by-default on this base image (confirmed via the base install
  # log: "Started Regular background program processing daemon" - cron's
  # own systemd unit description) - no explicit `apt-get install cron`
  # needed, just drop a file into /etc/cron.d/.
  provisioner "file" {
    source      = "${path.root}/scripts/update-squid-whitelist.sh"
    destination = "/tmp/update-squid-whitelist.sh"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/update-squid-whitelist.sh /usr/local/bin/update-squid-whitelist.sh",
      "sudo chmod +x /usr/local/bin/update-squid-whitelist.sh",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/squid-whitelist-fetch.service"
    destination = "/tmp/squid-whitelist-fetch.service"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/squid-whitelist-update.cron"
    destination = "/tmp/squid-whitelist-update.cron"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/squid-whitelist-fetch.service /etc/systemd/system/squid-whitelist-fetch.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable squid-whitelist-fetch.service",
      "sudo mv /tmp/squid-whitelist-update.cron /etc/cron.d/squid-whitelist-update",
      "sudo chown root:root /etc/cron.d/squid-whitelist-update",
      "sudo chmod 644 /etc/cron.d/squid-whitelist-update",
    ]
  }

  # Step 3: Vector - ships squid's access.log to Loki, matching the AWS
  # sandbox's vector.toml (config/vector.toml in this repo's AWS live
  # layer). Installed from Vector's official APT repository (now
  # Datadog-operated - confirmed live via https://setup.vector.dev's
  # redirect target on 2026-08-20, not guessed): key from
  # keys.datadoghq.com, keyring at
  # /usr/share/keyrings/datadog-archive-keyring.gpg, repo line
  # `https://apt.vector.dev/ stable vector-0`. Only the "CURRENT" signing
  # key is imported here (the official setup script also imports two older
  # rotated keys for compatibility with already-signed old package
  # metadata - not needed for a fresh image pulling latest packages).
  #
  # The vector.toml written below is NOT a live-layer-configurable value
  # the way squid.conf is (no config-bucket fetch) - var.vector_loki_endpoint
  # is baked in at Packer build time. See that variable's description: the
  # default endpoint (matching AWS's loki.hyperswitch.internal) will NOT
  # resolve from this GCP VPC as of 2026-08-20 - no interconnect exists
  # between this project and the AWS VPC that hostname actually lives in.
  # Vector still starts and tails the log file correctly either way (see
  # vector.toml.pkrtpl.hcl's healthcheck.enabled = false); only the Loki
  # sink will fail to deliver until real connectivity exists.
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo curl -sL https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | sudo gpg --dearmor -o /usr/share/keyrings/datadog-archive-keyring.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.vector.dev/ stable vector-0' | sudo tee /etc/apt/sources.list.d/vector.list",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq vector",
      "vector --version",
    ]
  }

  provisioner "file" {
    content     = templatefile("${path.root}/scripts/vector.toml.pkrtpl.hcl", { loki_endpoint = var.vector_loki_endpoint, environment = var.environment })
    destination = "/tmp/vector.toml"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/vector.toml /etc/vector/vector.toml",
      # The uploaded file keeps the SSH user's (packer:packer, mode 600)
      # ownership across `mv` - unreadable by the vector.service user
      # otherwise. Confirmed via a live failure: vector.service failed
      # with "Permission denied" reading its own config until this fix.
      "sudo chown root:vector /etc/vector/vector.toml",
      "sudo chmod 640 /etc/vector/vector.toml",
      # Vector's shipped systemd unit has no --config flag and defaults to
      # the "deprecated" path /etc/vector/vector.yaml (confirmed via
      # `vector --help` on this exact image, not from stale docs) - it
      # never looks at vector.toml on its own. VECTOR_CONFIG, read via the
      # unit's existing `EnvironmentFile=-/etc/default/vector`, is Vector's
      # own documented mechanism for pointing at a specific file/format
      # without touching the shipped unit.
      "echo 'VECTOR_CONFIG=/etc/vector/vector.toml' | sudo tee /etc/default/vector",
      # Vector's .deb package runs as system user `vector`; squid's own
      # package runs as user/group `proxy` and access.log inherits that
      # ownership. Add vector to the proxy group so it can read the log -
      # confirmed via a live read/tail test on the built image.
      "sudo usermod -aG proxy vector",
      "sudo systemctl enable vector.service",
    ]
  }

  # Step 4: cleanup before imaging.
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
      "history -c || true",
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
