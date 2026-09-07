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

source "googlecompute" "socks5" {
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

  # See var.use_iap: false falls back to a temporary public IP for the build
  # only. The built image never gets a public IP - that is a live-layer concern.
  omit_external_ip = var.use_iap
  use_internal_ip  = var.use_iap
  use_iap          = var.use_iap

  ssh_username = "packer"

  # Matches the tag on the temporary direct-SSH firewall rule the envoy and
  # squid image builds already share (tag-based, not image-specific).
  tags = var.use_iap ? [] : ["packer-build"]

  image_labels = {
    environment = var.environment
    project     = var.project_name
    component   = "socks5-proxy"
    managed_by  = "packer"
  }
}

build {
  name    = "socks5-image"
  sources = ["source.googlecompute.socks5"]

  # Step 1: Dante from the Ubuntu archive.
  #
  # `cloud-init status --wait` first, for the same reason the squid build does
  # it: Packer's shell provisioner can start before cloud-init's own first-boot
  # apt activity has finished, and the two race for the dpkg lock.
  #
  # danted.service is masked immediately after install: the package ships it
  # enabled, and the stock /etc/danted.conf has no `external:` interface set,
  # so it would crash-loop during the build before socks5-config-fetch has ever
  # run. It is unmasked and enabled at the end, once the fetch unit exists.
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo cloud-init status --wait",
      "sudo systemctl mask danted.service || true",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq dante-server",
      "dpkg -s dante-server | grep '^Version:'",
    ]
  }

  # Step 2: boot-time config fetch, the equivalent of the squid image's
  # squid-config-fetch.service. Pulls danted.conf from the config bucket named
  # in instance metadata, or renders a no-auth default scoped by the internal
  # LB's source ranges when nothing is published.
  provisioner "file" {
    source      = "${path.root}/scripts/fetch-socks5-config.sh"
    destination = "/tmp/fetch-socks5-config.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/socks5-config-fetch.service"
    destination = "/tmp/socks5-config-fetch.service"
  }

  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo mv /tmp/fetch-socks5-config.sh /usr/local/bin/fetch-socks5-config.sh",
      "sudo chmod +x /usr/local/bin/fetch-socks5-config.sh",
      "sudo mv /tmp/socks5-config-fetch.service /etc/systemd/system/socks5-config-fetch.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable socks5-config-fetch.service",
    ]
  }

  # Step 3: Vector, from the official (Datadog-operated) APT repo - same source
  # and keyring the squid image uses.
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
      # The uploaded file keeps the SSH user's ownership across `mv` and is
      # unreadable by vector.service otherwise - the squid image hit exactly
      # this as a live "Permission denied" failure.
      "sudo chown root:vector /etc/vector/vector.toml",
      "sudo chmod 640 /etc/vector/vector.toml",
      # Vector's shipped unit has no --config flag and defaults to
      # /etc/vector/vector.yaml; VECTOR_CONFIG via its EnvironmentFile is the
      # documented way to point it at a .toml without editing the unit.
      "echo 'VECTOR_CONFIG=/etc/vector/vector.toml' | sudo tee /etc/default/vector",
      "sudo systemctl enable vector.service",
    ]
  }

  # Step 4: unmask danted now that the config-fetch unit is in place, then
  # clean up before imaging.
  provisioner "shell" {
    inline = [
      "set -eux",
      "sudo systemctl unmask danted.service",
      "sudo systemctl enable danted.service",
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
