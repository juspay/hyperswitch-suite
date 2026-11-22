# =============================================================================
# ClickHouse custom image for OCI
# =============================================================================
# Clone of ../envoy-proxy/envoy-image.pkr.hcl (the 12-step canonical VM-tier
# template - ../README.md records what the port had to solve once) with the
# deltas plan W2 of .omo/plans/oci-kafka-clickhouse-images.md specifies:
#
#   Step 2:  the version-pinned official packages.clickhouse.com LTS deb triple
#            instead of the envoy docker-extraction.
#   Step 3:  the two data-volume mountpoints (AWS layout parity) - the
#            `clickhouse` user comes with the debs.
#   Step 5:  clickhouse-bootstrap.service + the Requires= drop-in that gates
#            the deb's own clickhouse-server.service (kept as shipped).
#   Step 6:  /usr/local/bin/clickhouse-bootstrap.sh - the config-delivery
#            mechanism, reading the plan section 4 contract from IMDS v2
#            user_data (the analogue of envoy's Object Storage fetch, which
#            cannot work here for the identity reasons ../README.md records).
#   Step 8:  selftest: the fail-closed gate, then /ping + SELECT 1 against the
#            shipped default config.
#   Step 10: ufw 8123/9000/9181 (+ SSH from the prod VCN CIDR).
#
# Everything else - the apt-lock barrier, the patch/reboot/old-kernel purge,
# the OCI CLI, Vector, CIS (pinned role), the Trivy gate, AIDE, the report
# downloads, the cleanup - is kept provisioner-for-provisioner identical to
# the envoy recipe, which the envoy and squid builds proved end to end.
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

source "oracle-oci" "clickhouse" {
  # `access_cfg_file_account` is the profile selector - see
  # ../squid-proxy/squid-image.pkr.hcl's source block for the full note on the
  # three different names Oracle's tools give this idea, and on why a
  # session-token profile works even though the builder's own
  # `security_token_file` field is vestigial.
  access_cfg_file_account = var.access_cfg_file_account
  region                  = var.region
  compartment_ocid        = var.compartment_ocid
  availability_domain     = var.availability_domain

  # Ubuntu 26.04 (resolute), matching the envoy/squid images. The `shape`
  # entry in the filter is load-bearing: OCI's aarch64 Ubuntu images report
  # the same operating_system_version string as the x86 ones, so OS + version
  # alone can select an image that will not boot on an E5.Flex shape.
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

  # Build-instance public IP - the only path the plugin documents for an
  # operator-run build (../build-network/create.sh confines it to a disposable
  # VCN with SSH open to a single /32). See ../README.md item 1.
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
    component   = "clickhouse"
    managed_by  = "packer"
  }

  instance_name = "${local.image_name}-build"
}

build {
  name    = "clickhouse-image"
  sources = ["source.oracle-oci.clickhouse"]

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
  # Step 2 - patch, reboot onto the patched kernel, then install the pinned
  #          ClickHouse LTS deb triple
  # ---------------------------------------------------------------------------
  # The patch/reboot/old-kernel-purge sub-steps come first (mirroring GCP Step
  # 1 and the envoy recipe) so the vulnerability gate below never scans the old
  # kernel. Then ClickHouse itself, from the OFFICIAL packages.clickhouse.com
  # LTS deb repository, whose metadata is signed by the vendor key fetched over
  # HTTPS from packages.clickhouse.com and pinned by `signed-by=` - the same
  # chain-of-custody argument as the envoy image's digest pin, adapted to a
  # signed apt repository. Versions are pinned EXACTLY (the plan's gate
  # decision 1: current LTS patch line - recorded 2026-11-17 as 26.8.39.19 in
  # var.clickhouse_version) so the image is reproducible and a repo-side
  # rebuild cannot silently move it.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      # Control 12a: dist-upgrade the base image's packages before installing
      # ClickHouse, so the captured image does not ship known-fixed CVE
      # packages. dist-upgrade, not upgrade: a new kernel is a NEW package, and
      # `apt-get upgrade` never installs new packages, so the vulnerability
      # gate would flag the old kernel's headers/tools/modules still being
      # installed.
      "sudo /usr/local/sbin/wait-for-apt.sh && sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Options::=--force-confold dist-upgrade",
    ]
  }

  # Reboot onto the patched kernel (oracle-oci reconnects), exactly as GCP does.
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
      # The envoy purge above only covers the generic naming style. OCI's
      # Ubuntu 26.04 base runs the ORACLE kernel flavor, whose per-version
      # packages are named linux-oracle-<headers|tools|...>-<abi> (no trailing
      # flavor suffix), so they dodge the pattern and survived autoremove -
      # build-proven 2026-11-17: Trivy gate failed on linux-oracle-headers-
      # 7.0.0-1015 / linux-oracle-tools-7.0.0-1015 leftovers after the 1016
      # kernel bump. Second pass keyed on the ABI token (uname -r minus the
      # flavor suffix and any upload revision), which matches BOTH naming
      # styles. Latent gap in the shared recipe - worth backporting there.
      "ABI=$(echo \"$RUN\" | sed 's/-[a-z]*$//; s/\\.[0-9]*$//')",
      "OLD2=$(dpkg -l | awk '/^ii/ {print $2}' | grep -E '^linux-[a-z0-9-]+-[0-9]' | grep -v -F -- \"$ABI\" || true)",
      "echo \"running kernel ABI: $ABI; remaining old kernel packages to purge: $OLD2\"",
      "if [ -n \"$OLD2\" ]; then sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq purge $OLD2; fi",
      "sudo update-grub || true",
      # The base image ships snaps whose bundled payloads carried many of the
      # first scan's findings. Refresh them to the vendor's latest; remove LXD (a
      # container hypervisor has no place on a database node) only if present -
      # `|| true` makes a missing lxd a no-op.
      "sudo snap refresh || true",
      "sudo snap remove --purge lxd || true",
      "snap list",
      # --- ClickHouse install continues here, after the patched kernel is live ---
      # Official deb repo (packages.clickhouse.com/docs Debian/Ubuntu
      # instructions): prerequisite transport packages, the vendor signing key
      # into a dedicated keyring, then the LTS channel pinned by signed-by.
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https ca-certificates curl gnupg",
      "curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=amd64] https://packages.clickhouse.com/deb lts main\" | sudo tee /etc/apt/sources.list.d/clickhouse.list",
      "sudo apt-get update -qq",
      # Version-pinned install (plus the common-static dependency at the same
      # version - upstream is explicit that all packages must match when
      # pinning). Fail closed: an unresolvable pin must fail the build, never
      # float to whatever the repo serves today.
      #
      # NOTE (build-proven 2026-11-17, supersedes the plan's "triple" wording):
      # the clickhouse-keeper deb CONFLICTS with clickhouse-server ("Reached two
      # conflicting assignments ... clickhouse-keeper:amd64 Conflicts
      # clickhouse-server") and cannot be installed alongside it - the keeper
      # deb is a 167 MB standalone build for keeper-ONLY nodes. Upstream's own
      # install docs say it outright: keeper "is included with ClickHouse
      # server". Inspected the debs to confirm what that means: the server deb
      # ships /usr/bin/clickhouse-keeper, clickhouse-keeper-client,
      # clickhouse-keeper-converter (symlinks into the multi-call clickhouse
      # binary from common-static), the clickhouse-keeper.service unit and
      # /etc/clickhouse-keeper/keeper_config.xml. So server + client at the
      # pinned version delivers the full keeper capability - including the
      # documented keeper scale-up path (plan gate decision 3: keeper_count=0
      # today, same image OCID feeds keeper nodes later) - and the step-8
      # `clickhouse-keeper --version` assertion below runs against a real
      # binary shipped by these packages.
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq clickhouse-server=${var.clickhouse_version} clickhouse-client=${var.clickhouse_version} clickhouse-common-static=${var.clickhouse_version}",
      # Assert the pinned versions actually landed.
      "clickhouse-server --version",
      "clickhouse-server --version | grep -F '${var.clickhouse_version}'",
      "clickhouse-client --version | grep -F '${var.clickhouse_version}'",
      "clickhouse-keeper --version | grep -F '${var.clickhouse_version}'",
      # The deb's postinst starts the server with the shipped default config;
      # stop it so no test state accrues while the rest of the image is built.
      # (It is re-armed properly in Step 5, gated on the bootstrap.)
      "sudo systemctl stop clickhouse-server.service || true",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 3 - data-volume mountpoints
  # ---------------------------------------------------------------------------
  # The `clickhouse` user and /var/lib/clickhouse come with the debs. What the
  # deb does not know about is the AWS layout this deployment mirrors: every
  # node carries TWO persistent data volumes, mounted at /var/lib/clickhouse/
  # data and data2 (plan section 4's dataPaths). The empty directories here are
  # the mountpoints; clickhouse-bootstrap.sh mounts the real volumes by
  # filesystem LABEL at first boot (format-if-blank, fail-fast if absent).
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "id clickhouse",
      "sudo mkdir -p /var/lib/clickhouse/data /var/lib/clickhouse/data2",
      "sudo chown clickhouse:clickhouse /var/lib/clickhouse/data /var/lib/clickhouse/data2",
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
      # The pinned oci-cli wheel drags in transitive deps that age; Trivy
      # flagged certifi 2025.11.12 (CRITICAL, fixable) in this venv on the
      # 2026-11-17 build. Re-resolve the SAME oci-cli version with an eager
      # dependency upgrade so the whole tree lands at current compatible
      # releases - the CLI version stays exactly what ../shared/scripts/
      # install-oci-cli.sh pinned, only its dependency tree is refreshed.
      "OCI_CLI_VER=$(/opt/oci-cli/bin/pip show oci-cli | awk '/^Version:/{print $2}')",
      "sudo /opt/oci-cli/bin/pip install --index-url https://pypi.org/simple --upgrade --upgrade-strategy eager \"oci-cli==$${OCI_CLI_VER}\"",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 5 - the fail-closed service gate
  # ---------------------------------------------------------------------------
  # The deb's clickhouse-server.service is kept exactly as shipped; the gate is
  # a drop-in (scripts/clickhouse-server-bootstrap.conf) adding
  # `Requires=clickhouse-bootstrap.service`, plus the bootstrap unit itself
  # (Before=clickhouse-server.service). A node with no delivered user_data - or
  # a bad one - therefore never serves: the bootstrap fails and the server's
  # start is dropped. That is the plan's section 4 fail-closed contract, and
  # Step 8 asserts it against the real (empty) IMDS of the build instance.
  provisioner "file" {
    source      = "${path.root}/scripts/clickhouse-bootstrap.service"
    destination = "/tmp/clickhouse-bootstrap.service"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/clickhouse-server-bootstrap.conf"
    destination = "/tmp/clickhouse-server-bootstrap.conf"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo install -o root -g root -m 0644 /tmp/clickhouse-bootstrap.service /etc/systemd/system/clickhouse-bootstrap.service",
      "sudo mkdir -p /etc/systemd/system/clickhouse-server.service.d",
      "sudo install -o root -g root -m 0644 /tmp/clickhouse-server-bootstrap.conf /etc/systemd/system/clickhouse-server.service.d/bootstrap.conf",
      "rm -f /tmp/clickhouse-bootstrap.service /tmp/clickhouse-server-bootstrap.conf",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable clickhouse-bootstrap.service",
      # Assert the gate is wired: the server unit must now Requires= the
      # bootstrap. Assert rather than trust - a dropped drop-in is silent.
      "systemctl show clickhouse-server.service -p Requires --value | grep -q 'clickhouse-bootstrap.service' || { echo 'SELFTEST FAILED: clickhouse-server does not require clickhouse-bootstrap'; systemctl show clickhouse-server.service -p Requires; exit 1; }",
      "systemctl show clickhouse-bootstrap.service -p Before --value | grep -q 'clickhouse-server.service' || { echo 'SELFTEST FAILED: clickhouse-bootstrap is not ordered before clickhouse-server'; exit 1; }",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 6 - the bootstrap script and instance metadata
  # ---------------------------------------------------------------------------
  # clickhouse-bootstrap.sh is this image's analogue of envoy's
  # fetch-envoy-config.sh: config delivery lives IN the image because the OCI
  # composition module has no startup-script seam (../README.md item 4). The
  # difference is the source: this one reads the plan section 4 contract from
  # IMDS v2 user_data rather than an Object Storage object - which also means
  # it works TODAY, with no instance principal involved.
  provisioner "file" {
    source      = "${path.root}/scripts/clickhouse-bootstrap.sh"
    destination = "/tmp/clickhouse-bootstrap.sh"
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
      "sudo install -o root -g root -m 0755 /tmp/clickhouse-bootstrap.sh /usr/local/bin/clickhouse-bootstrap.sh",
      "sudo install -o root -g root -m 0755 /tmp/populate-oci-metadata.sh /usr/local/bin/populate-oci-metadata.sh",
      "sudo install -o root -g root -m 0644 /tmp/oci-metadata.service /etc/systemd/system/oci-metadata.service",
      "rm -f /tmp/clickhouse-bootstrap.sh /tmp/populate-oci-metadata.sh /tmp/oci-metadata.service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable oci-metadata.service",
      # Syntax-level sanity: the script must at least parse. Its real contract
      # test is Step 8's fail-closed assertion and the first boot.
      "sudo bash -n /usr/local/bin/clickhouse-bootstrap.sh",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 7 - Vector
  # ---------------------------------------------------------------------------
  # Installed via Datadog's official APT repository (keyed), the same
  # mechanism the envoy and squid images use. scripts/vector.toml keeps the
  # shared VM-tier skeleton (host metrics + metadata tags + a
  # prometheus_exporter on 9273) with ClickHouse inputs instead of Envoy's.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo curl -sL https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | sudo gpg --dearmor -o /usr/share/keyrings/datadog-archive-keyring.gpg",
      "echo 'deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.vector.dev/ stable vector-0' | sudo tee /etc/apt/sources.list.d/vector.list",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq vector",
      "vector --version",
      # ClickHouse's server logs under /var/log/clickhouse-server are
      # clickhouse-owned 0750; Vector's file source runs as `vector`.
      "sudo usermod -aG clickhouse vector",
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
  # Step 8 - HEALTH ASSERTIONS, before the image is captured
  # ---------------------------------------------------------------------------
  # Three assertions, each catching a different class of broken image:
  #
  #   1. The FAIL-CLOSED GATE, against the real IMDS. The build instance has
  #      IMDS but no user_data - exactly the first-boot failure mode of a node
  #      launched without the contract JSON. `systemctl start clickhouse-server`
  #      must FAIL (the bootstrap fails and the Requires= drop-in drops the
  #      server start) and the server must stay inactive. Without this, a
  #      dropped drop-in or a bootstrap that fails open would capture an image
  #      that silently serves from its root disk.
  #
  #   2. The SHIPPED DEFAULT CONFIG SMOKE (plan W2 step 8): boot the config the
  #      debs ship, locally - /ping must answer `Ok.`, `SELECT 1` must return 1,
  #      and the keeper binary must be present. This runs the server binary
  #      directly rather than through the systemd unit on purpose: the unit is
  #      correctly gated on user_data (assertion 1), and the point of THIS
  #      assertion is the software itself, not the boot contract.
  #
  #   3. Clean state: no test database content is left in /var/lib/clickhouse
  #      for the image to carry. The mountpoint dirs from Step 3 are recreated.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      # --- 1. fail-closed gate ---
      "if sudo systemctl start clickhouse-server.service; then echo 'SELFTEST FAILED: clickhouse-server started on an instance with no user_data - the fail-closed gate is broken'; sudo journalctl -u clickhouse-bootstrap.service --no-pager -n 40; exit 1; fi",
      "ACTIVE=$(systemctl is-active clickhouse-server.service || true)",
      "echo \"clickhouse-server after ungated start attempt: $ACTIVE\"",
      "test \"$ACTIVE\" != \"active\" || { echo 'SELFTEST FAILED: clickhouse-server is active without user_data'; exit 1; }",
      "sudo journalctl -u clickhouse-bootstrap.service --no-pager -n 20",

      # --- 2. shipped default config smoke ---
      "sudo systemctl stop clickhouse-server.service || true",
      "sudo -u clickhouse /usr/bin/clickhouse-server --config-file=/etc/clickhouse-server/config.xml --pid-file=/var/tmp/ch-selftest.pid --daemon",
      "for i in $(seq 1 30); do if curl -sf http://127.0.0.1:8123/ping; then break; fi; sleep 2; done",
      "PING=$(curl -s --max-time 10 http://127.0.0.1:8123/ping || true)",
      "echo \"GET /ping -> $PING\"",
      "test \"$PING\" = \"Ok.\" || { echo 'SELFTEST FAILED: /ping did not answer Ok.'; sudo journalctl --no-pager -n 60; exit 1; }",
      "ONE=$(clickhouse-client --query 'SELECT 1')",
      "echo \"SELECT 1 -> $ONE\"",
      "test \"$ONE\" = \"1\" || { echo 'SELFTEST FAILED: SELECT 1 did not return 1'; exit 1; }",
      "clickhouse-keeper --version",
      "clickhouse-keeper --version | grep -F '${var.clickhouse_version}'",

      # --- 3. stop and clean state ---
      # The daemon writes its pid file with a restrictive umask - read it
      # once with sudo and reuse the shell variable (the inline block runs
      # as one script, so variables persist across these lines).
      "SELFTEST_PID=$(sudo cat /var/tmp/ch-selftest.pid)",
      "echo \"selftest pid: $SELFTEST_PID\"",
      "sudo kill \"$SELFTEST_PID\"",
      "for i in $(seq 1 30); do if ! sudo kill -0 \"$SELFTEST_PID\" 2>/dev/null; then break; fi; sleep 2; done",
      "sudo kill -9 \"$SELFTEST_PID\" 2>/dev/null || true",
      "rm -f /var/tmp/ch-selftest.pid",
      "sudo rm -rf /var/lib/clickhouse/store /var/lib/clickhouse/metadata /var/lib/clickhouse/flags /var/lib/clickhouse/tmp /var/lib/clickhouse/user_files /var/lib/clickhouse/access /var/lib/clickhouse/format_schemas /var/lib/clickhouse/coordination /var/lib/clickhouse/status",
      "sudo rm -rf /var/lib/clickhouse/data/* /var/lib/clickhouse/data2/* /var/log/clickhouse-server/*",
      "sudo mkdir -p /var/lib/clickhouse/data /var/lib/clickhouse/data2",
      "sudo chown clickhouse:clickhouse /var/lib/clickhouse/data /var/lib/clickhouse/data2",
      "sudo systemctl is-active clickhouse-server.service && { echo 'SELFTEST FAILED: server still active after selftest stop'; exit 1; } || true",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 9 - CIS baseline (UBUNTU24-CIS, Level 1 + 2) and Trivy CVE gate (12a)
  # ---------------------------------------------------------------------------
  # Identical to the envoy recipe: CIS runs BEFORE ufw (Step 10) because the
  # role ships `ubtu24cis_firewall_package: none` and never manages the host
  # firewall - the template's ufw config is the last word. Same pinned role
  # commit; the 26.04-base seam the plan's risk section flags is already
  # resolved by the envoy/squid builds having run this exact role on this
  # exact base.
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

  # Step 9a - run the CIS role, pinned by commit, Level 1 + 2.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /var/tmp/run-cis-baseline.sh",
      "sudo -n /var/tmp/run-cis-baseline.sh bfadae19d51d08e406c2c9327e3c8e510ee49cd7 /var/tmp/ubuntu2404.yml",
    ]
  }

  # Step 9b - re-assert our service seam after hardening (the OCI divergence
  # from GCP: config delivery lives IN this image, so it must survive CIS).
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo systemctl enable clickhouse-bootstrap.service clickhouse-server.service oci-metadata.service",
      "sudo systemctl is-enabled clickhouse-bootstrap.service clickhouse-server.service || true",
    ]
  }

  # Step 9c - Trivy scan (ADVISORY, user direction 2026-11-17: stop iterating
  # on CVE cleanliness - 100% hardening is never achievable and each rebuild
  # churns the tenancy's instance quota). The scan still runs and its reports
  # are archived in trivy-reports/ as a deliverable, but findings do NOT fail
  # the build. This is a deliberate deviation from the envoy recipe's gate.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /var/tmp/trivy-scan.sh",
      "sudo -n /var/tmp/trivy-scan.sh /var/tmp/trivy-clickhouse.json || echo 'trivy scan: findings recorded in the archived report (advisory-only gate)'",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 10 - ufw
  # ---------------------------------------------------------------------------
  # ufw is the last non-cleanup step ON PURPOSE, mirroring GCP/envoy: with it
  # enabled the established build session survives `ufw enable`, but it sits
  # after every CIS/Trivy/selftest step so those never have to reason about
  # the firewall. OCI's NSGs and security lists gate traffic at the network
  # level (the clickhouse composition module creates server/keeper NSGs and
  # the security-rules unit fills them); this locks down the host as well -
  # defence in depth.
  #
  # Ports (plan W2 step 10):
  #   8123  HTTP  - /ping and the LB health check
  #   9000  native - client + interserver
  #   9181  keeper - UNUSED in the single-node cut (keeper_count = 0), open
  #         for the documented scale-up so that path needs no image rebuild
  #   22    SSH, from the prod VCN CIDR only (10.91.0.0/16 -
  #         values.vcn_cidr_prefix = "10.91"; the envoy recipe used the dev
  #         VCN's 10.90.0.0/16 the same way)
  #
  # Deliberately NOT open: 9273 (Vector's prometheus_exporter). The envoy
  # image opens it because something was confirmed scraping it there; nothing
  # scrapes a clickhouse node yet, and opening a port nothing serves is how a
  # firewall rule outlives its reason.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "sudo ufw allow from ${var.prod_vcn_cidr} to any port 22 proto tcp",
      "sudo ufw allow ${var.clickhouse_http_port}/tcp",
      "sudo ufw allow ${var.clickhouse_tcp_port}/tcp",
      "sudo ufw allow ${var.clickhouse_keeper_port}/tcp",
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
  provisioner "file" {
    source      = "/var/tmp/trivy-clickhouse.json"
    destination = "${path.root}/trivy-reports/trivy-clickhouse.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/tmp/trivy-clickhouse.json.with-snaps.json"
    destination = "${path.root}/trivy-reports/trivy-clickhouse.json.with-snaps.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/tmp/trivy-clickhouse.json.sbom.cdx.json"
    destination = "${path.root}/trivy-reports/trivy-clickhouse.json.sbom.cdx.json"
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
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo apt-get autoremove -y -qq",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
      "sudo rm -f /var/tmp/run-cis-baseline.sh /var/tmp/trivy-scan.sh /var/tmp/trivy-clickhouse.json /var/tmp/trivy-clickhouse.json.with-snaps.json /var/tmp/trivy-clickhouse.json.sbom.cdx.json /var/tmp/ubuntu2404.yml",
      "sudo rm -f /usr/local/sbin/wait-for-apt.sh",
      "sudo cloud-init clean --logs || true",
      "history -c || true",
      # The pinned software must survive the cleanup - assert rather than
      # assume, and assert the fail-closed state one last time: no user_data,
      # no running server.
      "clickhouse-server --version | grep -F '${var.clickhouse_version}'",
      "clickhouse-client --version | grep -F '${var.clickhouse_version}'",
      "clickhouse-keeper --version | grep -F '${var.clickhouse_version}'",
      "test -x /usr/local/bin/clickhouse-bootstrap.sh",
      "systemctl is-active clickhouse-server.service && { echo 'SELFTEST FAILED: clickhouse-server active in the captured image'; exit 1; } || true",
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
