# =============================================================================
# Envoy custom image for OCI
# =============================================================================
# Port of terraform/gcp/packer/envoy-proxy/envoy-image.pkr.hcl. Provisioner
# order and content are kept the same wherever the logic is cloud-agnostic -
# docs/multi-cloud-parity/oci/vm-tier-and-images.md section 4 recommends
# porting GCP's templates rather than designing fresh, because GCP already did
# the portable thinking about what this image must contain and why.
#
# WHAT IS GENUINELY DIFFERENT FROM THE GCP TEMPLATE:
#   1. `oracle-oci` source block instead of `googlecompute`.  Here.
#   2. An apt-lock barrier before the first apt call. GCP's `cloud-init status
#      --wait` is necessary and NOT sufficient on OCI - proven by a real build
#      failure on 2026-09-05.  ../shared/scripts/wait-for-apt.sh.
#   3. Config fetch is BACK IN THE IMAGE. GCP deliberately moved it out to a
#      live-layer startup script on 2026-08-20; the OCI composition module has
#      no startup-script seam, so it cannot follow.
#      scripts/fetch-envoy-config.sh argues this at length.
#   4. A fail-closed default envoy.yaml is baked in, where GCP ships none and
#      accepts a crash loop until its startup script lands a real config.
#      scripts/envoy.yaml.default argues this at length.
#   5. /etc/default/metadata is populated by the image, for the same
#      no-startup-script reason as (3).
#      ../shared/scripts/populate-oci-metadata.sh.
#   6. The build asserts Envoy actually runs and serves before capturing the
#      image.  Step 8 below.
# =============================================================================

packer {
  required_plugins {
    # github.com/hashicorp/oracle. Community tier + HCP Ready, and alive:
    # v1.1.2 released 2026-01-16, last push 2026-05-11.
    oracle = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/oracle"
    }
  }
}

locals {
  timestamp  = regex_replace(timestamp(), "[- TZ:]", "")
  image_name = "${var.image_name_prefix}-${var.environment}-${local.timestamp}"
}

source "oracle-oci" "envoy" {
  # `access_cfg_file_account` is the profile selector - see
  # ../squid-proxy/squid-image.pkr.hcl's source block for the full note on the
  # three different names Oracle's tools give this idea, and on why a
  # session-token profile works even though the builder's own
  # `security_token_file` field is vestigial.
  access_cfg_file_account = var.access_cfg_file_account
  region                  = var.region
  compartment_ocid        = var.compartment_ocid
  availability_domain     = var.availability_domain

  # Ubuntu 26.04 (resolute), matching GCP's ubuntu-2604-lts (upgraded from 24.04
  # on 2026-10-09). The `shape` entry in the filter is load-bearing: OCI's
  # aarch64 Ubuntu images report the same operating_system_version string as
  # the x86 ones, so OS + version alone can select an image that will not boot
  # on an E5.Flex shape.
  base_image_ocid = var.base_image_ocid
  dynamic "base_image_filter" {
    for_each = var.base_image_ocid == "" ? [1] : []
    content {
      operating_system         = var.base_image_operating_system
      operating_system_version = var.base_image_operating_system_version
      shape                    = var.shape
    }
  }

  shape = var.shape
  shape_config {
    ocpus         = var.shape_ocpus
    memory_in_gbs = var.shape_memory_in_gbs
  }

  subnet_ocid = var.subnet_ocid

  # Build-instance public IP. There is no `use_iap` analogue to reach for - the
  # plugin has no bastion argument at all - so unlike GCP's squid build this is
  # not a fallback from a broken private path, it is the only path the plugin
  # documents for an operator-run build. ../build-network/create.sh confines it
  # to a disposable VCN with SSH open to a single /32.
  create_vnic_details {
    assign_public_ip = var.assign_public_ip
    display_name     = "${local.image_name}-build-vnic"
  }
  use_private_ip = !var.assign_public_ip

  ssh_username = var.ssh_username

  image_name             = local.image_name
  image_compartment_ocid = var.compartment_ocid

  # `disk_size`, not `boot_volume_size_in_gbs`: the Go field is
  # BootVolumeSizeInGBs but its mapstructure tag is Packer's generic
  # `disk_size`.
  disk_size = var.boot_volume_size_in_gbs

  tags = {
    environment = var.environment
    project     = var.project_name
    component   = "envoy-proxy"
    managed_by  = "packer"
  }

  instance_name = "${local.image_name}-build"
}

build {
  name    = "envoy-image"
  sources = ["source.oracle-oci.envoy"]

  # ---------------------------------------------------------------------------
  # Step 1 - apt-lock barrier
  # ---------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/../shared/scripts/wait-for-apt.sh"
    destination = "/tmp/wait-for-apt.sh"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      # Install to /usr/local/sbin so the barrier survives the Step 2 reboot and
      # can be reused after it (GCP does the same).
      "sudo install -o root -g root -m 0755 /tmp/wait-for-apt.sh /usr/local/sbin/wait-for-apt.sh",
      "rm -f /tmp/wait-for-apt.sh",
      "sudo /usr/local/sbin/wait-for-apt.sh",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 2 - patch, reboot onto the patched kernel, then extract Envoy
  # ---------------------------------------------------------------------------
  # The patch/reboot/old-kernel-purge sub-steps come first (mirroring GCP Step
  # 1) so the vulnerability gate below never scans the old kernel. Then the
  # binary itself, from the OFFICIAL envoyproxy/envoy Docker image. The
  # extraction reasoning, which follows, is entirely about upstream Envoy
  # packaging and therefore cloud-independent:
  #
  # The binary comes from the OFFICIAL envoyproxy/envoy Docker image (published
  # by the Envoy project's own org, not a third-party redistribution). Pulling
  # it validates per-arch content digests as part of the normal docker pull,
  # giving a verifiable chain of custody a bare HTTPS tarball does not have.
  # Docker is installed ONLY for this extraction and purged again in the
  # cleanup step - Envoy runs as a native systemd service, not a container.
  #
  # Three alternatives were tried and rejected by real build failures on
  # 2026-08-19/20 during the GCP port; none of the rejections is GCP-specific:
  #   - apt.envoyproxy.io (Envoy's own apt repo) is explicitly documented as
  #     unmaintained.
  #   - deb.dl.getenvoy.io (the older Tetrate getenvoy-package repo): GPG key
  #     verifies, but no `getenvoy-envoy` package exists for Ubuntu jammy at
  #     all; the GitHub org is archived under "tetratelabs-attic".
  #   - archive.tetratelabs.io: worked, but is a third-party redistribution one
  #     hop further from the source with no checksum sidecar to verify against.
  #
  # This mirrors what the pre-baked AWS AMI already has: an `envoy` systemd
  # service reading /etc/envoy/envoy.yaml, with the AWS live layer's
  # userdata.sh only ever templating config into an already-installed Envoy.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      # Control 12a: dist-upgrade the base image's packages before extracting
      # Envoy, so the captured image does not ship known-fixed CVE packages.
      # dist-upgrade, not upgrade: a new kernel is a NEW package, and `apt-get
      # upgrade` never installs new packages, so the vulnerability gate would
      # flag the old kernel's headers/tools/modules still being installed.
      "sudo /usr/local/sbin/wait-for-apt.sh && sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Options::=--force-confold dist-upgrade",
    ]
  }

  # Reboot onto the patched kernel (oracle-oci reconnects), exactly as GCP does.
  # The old-kernel purge and the CIS tmpfs /tmp below need the new kernel, and
  # the vulnerability gate would flag the old kernel's headers/modules sitting
  # next to the running one if they were left behind.
  provisioner "shell" {
    remote_folder     = "/var/tmp"
    expect_disconnect = true
    inline            = ["sudo systemctl reboot"]
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    pause_before  = "45s"
    inline = [
      "set -eux",
      "uname -r",
      "sudo /usr/local/sbin/wait-for-apt.sh",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq autoremove --purge",
      # autoremove does NOT drop the old kernel: the base image installs its
      # headers/tools/modules by hand, so apt treats them as wanted. Purge every
      # kernel PACKAGE that is not the running version (adapted to OCI's generic
      # `linux-*` package naming - GCP matches `-gcp` kernels). The metapackages
      # (linux-image-generic, linux-generic) do not match the version regex and
      # stay.
      "RUN=$(uname -r); BASE=$(echo \"$RUN\" | sed 's/-generic$//;s/-$//')",
      "OLD=$(dpkg -l | awk '/^ii/ {print $2}' | grep -E '^linux-(image|image-unsigned|headers|modules|modules-extra|tools|buildinfo|cloud-tools)-[0-9]' | grep -v -F -- \"$BASE\" || true)",
      "echo \"running kernel: $RUN; old kernel packages to purge: $OLD\"",
      "if [ -n \"$OLD\" ]; then sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq purge $OLD; fi",
      "sudo update-grub || true",
      # The base image ships snaps whose bundled payloads carried many of the
      # first scan's findings. Refresh them to the vendor's latest; remove LXD (a
      # container hypervisor has no place on a proxy) only if present - `|| true`
      # makes a missing lxd a no-op.
      "sudo snap refresh || true",
      "sudo snap remove --purge lxd || true",
      "snap list",
      # --- Envoy extraction continues here, after the patched kernel is live ---
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq docker.io",
      "sudo systemctl start docker",
      # Fail closed if the digest variable is still the placeholder - a build
      # must never silently pull a mutating tag.
      "case '${var.envoy_image_digest}' in sha256:REPLACE_ME|'') echo 'SELFTEST FAILED: envoy_image_digest is still the placeholder; set it to a real digest before building'; exit 1;; esac",
      "sudo docker pull envoyproxy/envoy@${var.envoy_image_digest}",
      "sudo docker create --name envoy-extract envoyproxy/envoy@${var.envoy_image_digest}",
      "sudo docker cp envoy-extract:/usr/local/bin/envoy /usr/bin/envoy",
      "sudo chmod 0755 /usr/bin/envoy",
      "sudo docker rm envoy-extract",
      "envoy --version",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 3 - system user, directories, ownership
  # ---------------------------------------------------------------------------
  # Same layout the AWS AMI's userdata assumes already exists.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo id envoy || sudo useradd --system --no-create-home --shell /usr/sbin/nologin envoy",
      "sudo mkdir -p /etc/envoy /var/log/envoy",
      "sudo touch /var/log/envoy/access.log",
      # Control 12c: /etc/envoy is root:envoy 0750 so the envoy service can
      # read its config (group read+traverse) but cannot rewrite it. The
      # config installed into it is root:envoy 0640. /var/log/envoy stays
      # envoy:envoy - envoy must be able to append its own logs.
      "sudo chown root:envoy /etc/envoy",
      "sudo chmod 0750 /etc/envoy",
      "sudo chown envoy:envoy /var/log/envoy /var/log/envoy/access.log",
      "sudo chmod 0750 /var/log/envoy",
      "sudo chmod 0640 /var/log/envoy/access.log",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 4 - the OCI CLI
  # ---------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/../shared/scripts/install-oci-cli.sh"
    destination = "/tmp/install-oci-cli.sh"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /tmp/install-oci-cli.sh",
      "/tmp/install-oci-cli.sh",
      "rm -f /tmp/install-oci-cli.sh",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 5 - the fail-closed default config, and envoy.service
  # ---------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/scripts/envoy.yaml.default"
    destination = "/tmp/envoy.yaml.default"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/envoy.service"
    destination = "/tmp/envoy.service"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo install -o root -g envoy -m 0640 /tmp/envoy.yaml.default /etc/envoy/envoy.yaml",
      "sudo install -o root -g root -m 0644 /tmp/envoy.service /etc/systemd/system/envoy.service",
      "rm -f /tmp/envoy.yaml.default /tmp/envoy.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable envoy.service",
      # Prove the baked-in default is a config Envoy will actually accept.
      # --mode validate fully bootstraps the config without binding a listener.
      "sudo -u envoy /usr/bin/envoy -c /etc/envoy/envoy.yaml --mode validate",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 6 - config fetch and instance metadata
  # ---------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/scripts/fetch-envoy-config.sh"
    destination = "/tmp/fetch-envoy-config.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/envoy-config-fetch.service"
    destination = "/tmp/envoy-config-fetch.service"
  }

  provisioner "file" {
    source      = "${path.root}/../shared/scripts/populate-oci-metadata.sh"
    destination = "/tmp/populate-oci-metadata.sh"
  }

  provisioner "file" {
    source      = "${path.root}/../shared/scripts/oci-metadata.service"
    destination = "/tmp/oci-metadata.service"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo install -o root -g root -m 0755 /tmp/fetch-envoy-config.sh /usr/local/bin/fetch-envoy-config.sh",
      "sudo install -o root -g root -m 0755 /tmp/populate-oci-metadata.sh /usr/local/bin/populate-oci-metadata.sh",
      "sudo install -o root -g root -m 0644 /tmp/envoy-config-fetch.service /etc/systemd/system/envoy-config-fetch.service",
      "sudo install -o root -g root -m 0644 /tmp/oci-metadata.service /etc/systemd/system/oci-metadata.service",
      "rm -f /tmp/fetch-envoy-config.sh /tmp/populate-oci-metadata.sh /tmp/envoy-config-fetch.service /tmp/oci-metadata.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable envoy-config-fetch.service",
      "sudo systemctl enable oci-metadata.service",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 7 - Vector
  # ---------------------------------------------------------------------------
  # Installed via Datadog's official setup script (Vector is maintained by
  # Datadog's Community Open Source Engineering team; GPG key rotation via
  # keys.datadoghq.com), same as the GCP envoy image.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      # Vector from Datadog's official APT repository (keyed), the same
      # mechanism the squid image uses - NOT the setup.vector.dev curl-pipe
      # that the previous envoy build fetched from an unpinned script. Only the
      # CURRENT signing key is imported (a fresh image only pulls current
      # package metadata); control 12a/13a hygiene.
      "sudo curl -sL https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | sudo gpg --dearmor -o /usr/share/keyrings/datadog-archive-keyring.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.vector.dev/ stable vector-0' | sudo tee /etc/apt/sources.list.d/vector.list",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq vector",
      "vector --version",
      # Envoy's access log is written by the `envoy` user; Vector's file source
      # runs as `vector` and needs to be able to tail it.
      "sudo usermod -aG envoy vector",
    ]
  }

  provisioner "file" {
    source      = "${path.root}/scripts/vector.toml"
    destination = "/tmp/vector.toml"
  }

  provisioner "file" {
    source      = "${path.root}/../shared/scripts/vector-oci-overrides.conf"
    destination = "/tmp/vector-oci-overrides.conf"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo mkdir -p /etc/vector /etc/systemd/system/vector.service.d",
      # `install` with an explicit owner and mode, not `mv`: an uploaded file
      # keeps the SSH user's ownership and mode 600, which leaves it unreadable
      # by vector.service. Confirmed on GCP by a live "Permission denied".
      "sudo install -o root -g vector -m 0640 /tmp/vector.toml /etc/vector/vector.toml",
      "sudo install -o root -g root -m 0644 /tmp/vector-oci-overrides.conf /etc/systemd/system/vector.service.d/oci-overrides.conf",
      "rm -f /tmp/vector.toml /tmp/vector-oci-overrides.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable vector.service",
      "sudo /usr/bin/vector validate /etc/vector/vector.toml",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 8 - HEALTH ASSERTION, before the image is captured
  # ---------------------------------------------------------------------------
  # No GCP counterpart. GCP's envoy image cannot self-test at all, by design:
  # it ships no envoy.yaml, so the service is expected to crash-loop until a
  # live-layer startup script supplies one, and there is nothing to assert.
  # Because this image ships a real (if deliberately unhealthy-answering)
  # default, it CAN be asserted, and a broken image can never be captured.
  #
  # What is asserted, and why each one:
  #   - envoy.service reaches active. Catches a bad unit file, a missing user,
  #     a permissions mistake on /etc/envoy or /var/log/envoy.
  #   - the admin /ready endpoint answers 200 on loopback. This is Envoy's own
  #     statement that it finished initialising - stronger than "the process is
  #     running", and it is also what vector.toml's prometheus_scrape depends on.
  #   - the admin endpoint is NOT reachable on the instance's own non-loopback
  #     address. The default config binds it to 127.0.0.1 precisely so that the
  #     admin API - which can drain listeners and dump the full config - is not
  #     exposed; an assertion is the only thing that keeps that true across
  #     future edits to envoy.yaml.default.
  #   - the data-plane port answers 503 with the placeholder body. Proves the
  #     listener is bound on the port the load balancer's backend set targets
  #     AND that an instance with no delivered config fails its health check
  #     rather than passing it.
  #   - Vector can read the access log, which is the point of the usermod.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo systemctl start envoy.service",
      "sudo systemctl is-active envoy.service",
      "for i in $(seq 1 30); do if curl -sf -o /dev/null http://127.0.0.1:${var.envoy_admin_port}/ready; then break; fi; sleep 2; done",

      "READY=$(curl -s -o /dev/null -w '%%{http_code}' --max-time 10 http://127.0.0.1:${var.envoy_admin_port}/ready || true)",
      "echo \"admin /ready -> $READY\"",
      "test \"$READY\" = \"200\" || { echo 'SELFTEST FAILED: envoy admin /ready did not return 200'; sudo journalctl -u envoy.service --no-pager -n 80; exit 1; }",

      # Prometheus stats must actually be scrapeable - vector.toml's
      # envoy_prom_metrics source points straight at this path.
      "curl -sf http://127.0.0.1:${var.envoy_admin_port}/stats/prometheus | head -3",

      # The admin listener must be loopback-only. Checked against the real
      # bound socket, not against the config file, so an edit that widens the
      # bind address cannot slip through.
      "sudo ss -lntp | grep ':${var.envoy_admin_port} '",
      "sudo ss -lntp | grep ':${var.envoy_admin_port} ' | grep -q '127.0.0.1:${var.envoy_admin_port}' || { echo 'SELFTEST FAILED: envoy admin listener is not bound to 127.0.0.1'; sudo ss -lntp; exit 1; }",

      # Data plane on the port the load balancer's backend set targets.
      "sudo ss -lntp | grep ':${var.envoy_http_port} '",
      "DATA=$(curl -s -o /tmp/envoy-selftest-body -w '%%{http_code}' --max-time 10 http://127.0.0.1:${var.envoy_http_port}/health || true)",
      "echo \"data plane /health -> $DATA\"",
      "cat /tmp/envoy-selftest-body",
      "test \"$DATA\" = \"503\" || { echo 'SELFTEST FAILED: the baked-in default must answer 503, not '\"$DATA\"'. A 200 here would mean an instance with no delivered config passes its health check and black-holes traffic.'; exit 1; }",
      "grep -q 'no envoy.yaml has been delivered' /tmp/envoy-selftest-body || { echo 'SELFTEST FAILED: 503 body is not the placeholder body - something other than the baked-in default is being served'; exit 1; }",

      "sudo setpriv --reuid=vector --regid=vector --init-groups test -r /var/log/envoy/listener-https-placeholder.log || { echo 'SELFTEST FAILED: vector cannot read the envoy log directory'; id vector; groups vector; sudo -u vector ls -la /var/log/envoy; exit 1; }",

      "sudo systemctl stop envoy.service",
      "rm -f /tmp/envoy-selftest-body",
      "sudo truncate -s 0 /var/log/envoy/access.log || true",
      "sudo rm -f /var/log/envoy/envoy.log /var/log/envoy/listener-https-placeholder.log",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 9 - CIS baseline (UBUNTU24-CIS, Level 1 + 2) and Trivy CVE gate (12a)
  # ---------------------------------------------------------------------------
  # CIS runs here, BEFORE ufw (Step 10): the role ships
  # `ubtu24cis_firewall_package: none`, so it never manages the host firewall -
  # the template configures ufw after, making the hardened rules the last word.
  # The playbook sets `skip_reboot: true` (the kernel was already made current
  # by the Step 2 reboot; the CIS tmpfs /tmp unit applies at the image's first
  # boot).
  provisioner "file" {
    source      = "${path.root}/../shared/cis/ubuntu2404.yml"
    destination = "/var/tmp/ubuntu2404.yml"
  }

  provisioner "file" {
    source      = "${path.root}/../shared/scripts/run-cis-baseline.sh"
    destination = "/var/tmp/run-cis-baseline.sh"
  }

  provisioner "file" {
    source      = "${path.root}/../shared/scripts/trivy-scan.sh"
    destination = "/var/tmp/trivy-scan.sh"
  }

  # Step 9a - run the CIS role, pinned by commit, Level 1 + 2 (no
  # CIS_SQUID_SERVER for envoy).
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /var/tmp/run-cis-baseline.sh",
      "sudo -n /var/tmp/run-cis-baseline.sh bfadae19d51d08e406c2c9327e3c8e510ee49cd7 /var/tmp/ubuntu2404.yml",
    ]
  }

  # Step 9b - restore the envoy config-fetch seam. CIS does not manage our
  # units, but re-assert the service is armed for boot after the role ran (the
  # OCI divergence from GCP: config delivery lives IN this image, so it must
  # survive hardening).
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo systemctl enable envoy.service envoy-config-fetch.service",
      "sudo systemctl is-enabled envoy.service envoy-config-fetch.service || true",
    ]
  }

  # Step 9c - Trivy CVE gate (control 12a): fail on HIGH/CRITICAL with a fix
  # in apt + non-snap software; snap payloads are reported separately, never
  # gating. See shared/scripts/trivy-scan.sh.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /var/tmp/trivy-scan.sh",
      "sudo -n /var/tmp/trivy-scan.sh /var/tmp/trivy-envoy.json",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 10 - ufw
  # ---------------------------------------------------------------------------
  # ufw is the last non-cleanup step ON PURPOSE, mirroring GCP: with it enabled
  # the established build session survives `ufw enable`, but it sits after every
  # CIS/Trivy/selftest step so those never have to reason about the firewall.
  #
  # OCI's NSGs and security lists already gate traffic at the network level,
  # and the envoy-proxy module creates two NSGs for exactly that. This locks
  # down the host as well, matching the AWS AMI/userdata pattern the module
  # mirrors - defence in depth in case an instance ever lands on a
  # less-restrictive network.
  #
  # NOTE what is deliberately NOT opened: the Envoy admin port. It is bound to
  # loopback in the config and has no business being reachable off-box; step 8
  # asserts both halves of that.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      # Only the data-plane port 8080 and Vector's prometheus_exporter (9273,
      # which daily-confirmed something scrapes in this image) are needed
      # inbound. 8443/8444 were removed - the https/mtls listeners exist in the
      # OCI module but nothing binds those ports in this shape, and opening a
      # port nothing serves is how a firewall rule outlives its reason. SSH is
      # restricted to the OCI dev VCN management subnet 10.90.0.0/16, not a
      # bastion /32 that changes on recreation.
      "sudo ufw allow from 10.90.0.0/16 to any port 22 proto tcp",
      "sudo ufw allow ${var.envoy_http_port}/tcp",
      "sudo ufw allow ${var.vector_prometheus_port}/tcp",
      "sudo ufw --force enable",
      "sudo ufw status verbose",
      # Assert rather than trust: `ufw --force enable` succeeding is not the
      # same as ufw being active in the captured image.
      "sudo ufw status | grep -q '^Status: active' || { echo 'SELFTEST FAILED: ufw is not active'; exit 1; }",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 11 - AIDE baseline (section 5b), rebuilt on the FINAL file state
  # ---------------------------------------------------------------------------
  # The CIS role installs aide and builds an early database. Rebuild it here,
  # on the file state that will actually be captured, and enable the daily
  # check, so the first daily run on a new instance does not report the whole
  # build as changes. Mirrors GCP's step-10 aideinit.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "if command -v aide >/dev/null 2>&1; then sudo aideinit --yes --force && sudo cp -f /var/lib/aide/aide.db.new /var/lib/aide/aide.db; fi",
      "sudo systemctl enable aidecheck.timer || true",
      "sudo systemctl start aidecheck.timer || true",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 11b - pull the security reports down to the build host so they survive
  # ---------------------------------------------------------------------------
  # The trivy gate (Step 9c) writes its reports to /var/tmp and Step 12 deletes
  # them before the instance is torn down, which would otherwise make the
  # "save trivy/CIS/AIDE report" requirement a no-op. Download them (plus the
  # CIS ansible log) to ${path.root}/trivy-reports/ on this machine BEFORE the
  # cleanup step removes them from the instance. The file provisioner reads
  # them over the ssh communicator; direction=download pulls rather than pushes.
  provisioner "file" {
    source      = "/var/tmp/trivy-envoy.json"
    destination = "${path.root}/trivy-reports/trivy-envoy.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/tmp/trivy-envoy.json.with-snaps.json"
    destination = "${path.root}/trivy-reports/trivy-envoy.json.with-snaps.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/tmp/trivy-envoy.json.sbom.cdx.json"
    destination = "${path.root}/trivy-reports/trivy-envoy.json.sbom.cdx.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/log/cis-baseline-build.log"
    destination = "${path.root}/trivy-reports/cis-baseline-build.log"
    direction   = "download"
  }

  # ---------------------------------------------------------------------------
  # Step 12 - cleanup before imaging
  # ---------------------------------------------------------------------------
  # docker.io goes with it: it existed only to extract the Envoy binary in
  # step 2 and has no runtime role.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo systemctl stop docker || true",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y -qq docker.io",
      "sudo apt-get autoremove -y -qq",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/* /var/lib/docker",
      "sudo rm -f /etc/envoy/envoy.yaml.old /etc/envoy/envoy.yaml.candidate",
      "sudo rm -f /var/tmp/run-cis-baseline.sh /var/tmp/trivy-scan.sh /var/tmp/trivy-envoy.json /var/tmp/trivy-envoy.json.with-snaps.json /var/tmp/trivy-envoy.json.sbom.cdx.json /var/tmp/ubuntu2404.yml",
      "sudo rm -f /usr/local/sbin/wait-for-apt.sh",
      "sudo cloud-init clean --logs || true",
      "history -c || true",
      # The binary must survive the docker purge - it was copied out of the
      # container image, not installed by the package, but assert it rather
      # than assume it.
      "test -x /usr/bin/envoy && envoy --version",
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
