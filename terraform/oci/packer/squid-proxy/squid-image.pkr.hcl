# =============================================================================
# Squid custom image for OCI
# =============================================================================
# Port of terraform/gcp/packer/squid-proxy/squid-image.pkr.hcl. The provisioner
# steps are deliberately kept in the same order and, where the logic is
# cloud-agnostic, with the same content - `docs/multi-cloud-parity/oci/
# vm-tier-and-images.md` section 4 recommends porting GCP's templates rather
# than designing fresh, precisely because GCP already did the hard, portable
# thinking about what this image must contain.
#
# WHAT IS GENUINELY DIFFERENT, all four items, and where each is argued:
#   1. `oracle-oci` source block instead of `googlecompute`.  Here.
#   2. Config fetch is `oci os object get`, which needs the OCI CLI installed
#      and an instance principal that does not exist yet.
#      ../shared/scripts/install-oci-cli.sh and
#      scripts/fetch-squid-config.sh.
#   3. A fail-closed default squid.conf is BAKED IN (GCP relied on the apt
#      default).  scripts/squid.conf.default.
#   4. The build asserts Squid's real behaviour before capturing the image.
#      Step 6 below.
# =============================================================================

packer {
  required_plugins {
    # github.com/hashicorp/oracle, not .../googlecompute. Community tier +
    # HCP Ready on developer.hashicorp.com, and alive: v1.1.2 released
    # 2026-01-16, last push 2026-05-11 (checked against the GitHub API, not
    # the registry page - see vm-tier-and-images.md section 4).
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

source "oracle-oci" "squid" {
  # ---------------------------------------------------------------------------
  # Auth
  # ---------------------------------------------------------------------------
  # `access_cfg_file_account` is the profile selector. The name is worth
  # noticing because three different Oracle tools spell the same idea three
  # ways: the Terraform provider calls it `config_file_profile`, the CLI calls
  # it `--profile`, and this builder calls it `access_cfg_file_account`
  # (builder/oci/config.go: mapstructure:"access_cfg_file_account", defaulting
  # to "DEFAULT").
  #
  # SESSION-TOKEN AUTH WORKS, AND NOT BY THE OBVIOUS ROUTE. The `devuser`
  # profile has no `user` key and authenticates with `security_token_file`
  # (`oci session authenticate`). The builder exposes a `security_token_file`
  # mapstructure field, but reading config.go shows that field is declared and
  # never read - it is vestigial. What actually makes this work is that the
  # builder delegates to the OCI Go SDK's
  # `ConfigurationProviderFromFileWithProfile`, whose file provider returns an
  # "ST$<token>" key ID when the profile carries `security_token_file`. The
  # builder's own validation confirms it expects that path: it emits
  # "'security_token_file' must be correctly specified" if the SDK's KeyID()
  # call fails. So the token is picked up from the config FILE, not from any
  # argument here - which is also why refreshing the session
  # (`oci session refresh --profile devuser`) is all that is needed when a long
  # build outlives it.
  access_cfg_file_account = var.access_cfg_file_account
  region                  = var.region
  compartment_ocid        = var.compartment_ocid
  availability_domain     = var.availability_domain

  # ---------------------------------------------------------------------------
  # Base image
  # ---------------------------------------------------------------------------
  # Ubuntu 26.04 (resolute), matching GCP's ubuntu-2604-lts exactly (upgraded
  # from 22.04 on 2026-10-09). That is the reason the provisioner scripts need
  # no OS-level changes: same apt archive, same `squid` package, same Vector
  # .deb, same ufw.
  #
  # base_image_filter rather than a hardcoded OCID so the template does not rot
  # when Canonical publishes a new build. The `shape` entry is doing real work
  # and is not decoration: OCI reports the aarch64 Ubuntu images with the same
  # operating_system_version "26.04" as the x86 ones (only the display name
  # differs), so filtering on OS + version alone can select an ARM image that
  # will not boot on an E5.Flex shape. Filtering on shape resolves it.
  base_image_ocid = var.base_image_ocid
  dynamic "base_image_filter" {
    for_each = var.base_image_ocid == "" ? [1] : []
    content {
      operating_system         = var.base_image_operating_system
      operating_system_version = var.base_image_operating_system_version
      shape                    = var.shape
    }
  }

  # ---------------------------------------------------------------------------
  # Build instance
  # ---------------------------------------------------------------------------
  shape = var.shape
  shape_config {
    ocpus         = var.shape_ocpus
    memory_in_gbs = var.shape_memory_in_gbs
  }

  subnet_ocid = var.subnet_ocid

  # A public IP on the BUILD instance only. There is no `use_iap` equivalent to
  # reach for here - the plugin has no bastion argument at all (see
  # var.assign_public_ip's description) - so this is not the "IAP was broken so
  # we fell back" story GCP's squid build tells, it is the only documented path
  # the plugin offers for an operator-run build. ../build-network/create.sh
  # confines the exposure to a disposable VCN with SSH open to one /32.
  create_vnic_details {
    assign_public_ip = var.assign_public_ip
    display_name     = "${local.image_name}-build-vnic"
  }
  use_private_ip = !var.assign_public_ip

  ssh_username = var.ssh_username

  # ---------------------------------------------------------------------------
  # Resulting image
  # ---------------------------------------------------------------------------
  # No image_family equivalent exists on OCI, so the consuming unit takes an
  # OCID, not a name. That is a real ergonomic loss versus GCE's
  # "newest image in family" resolution and it is why
  # terraform/oci/live/terragrunt.stack.hcl has to carry literal OCIDs in
  # values.custom_images rather than a family string.
  image_name             = local.image_name
  image_compartment_ocid = var.compartment_ocid

  # `disk_size`, not `boot_volume_size_in_gbs`. The Go field IS called
  # BootVolumeSizeInGBs, but its mapstructure tag is `disk_size` - the field is
  # named after the OCI concept and the HCL argument after Packer's generic
  # one. Getting this wrong is a silent "unsupported argument" at validate
  # time, not a runtime surprise, but it costs a round trip.
  disk_size = var.boot_volume_size_in_gbs

  tags = {
    environment = var.environment
    project     = var.project_name
    component   = "squid-proxy"
    managed_by  = "packer"
  }

  instance_name = "${local.image_name}-build"
}

build {
  name    = "squid-image"
  sources = ["source.oracle-oci.squid"]

  # ---------------------------------------------------------------------------
  # Step 1 - patch, reboot onto the patched kernel, then install Squid
  # ---------------------------------------------------------------------------
  # The patch/reboot/old-kernel-purge sub-steps come first (mirroring GCP Step
  # 1) so the vulnerability gate below never scans the old kernel. Then Squid
  # itself - unlike Envoy there is no first-party upstream repo to pin a version
  # from; Ubuntu 26.04's `squid` package is also what the AWS AMI is built on
  # (the AWS live layer's userdata.sh only ever templates config into an
  # already-installed Squid, it never installs it).
  #
  # An apt-lock barrier comes first. GCP's template uses a bare
  # `cloud-init status --wait` here, having learned from a real failure that
  # Packer's shell provisioner can start before first-boot package activity has
  # finished. That guard is necessary on OCI and PROVEN INSUFFICIENT: the first
  # real OCI build of this template failed with cloud-init reporting `done` and
  # an unrelated `apt` (PID 1953) still holding /var/lib/apt/lists/lock -
  # Canonical's OCI images run apt-daily/unattended-upgrades on their own
  # timers. ../shared/scripts/wait-for-apt.sh waits for both conditions and
  # explains the difference in full.
  provisioner "file" {
    source      = "${path.root}/../shared/scripts/wait-for-apt.sh"
    destination = "/tmp/wait-for-apt.sh"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      # Install to /usr/local/sbin so the barrier survives the Step 1 reboot and
      # can be reused after it (GCP does the same).
      "sudo install -o root -g root -m 0755 /tmp/wait-for-apt.sh /usr/local/sbin/wait-for-apt.sh",
      "rm -f /tmp/wait-for-apt.sh",
      "sudo /usr/local/sbin/wait-for-apt.sh",
      # Control 13a: dist-upgrade the base image's packages to the latest
      # patched builds before installing anything, so the captured image does
      # not ship with known fixed vulnerabilities. dist-upgrade, not upgrade: a
      # new kernel is a NEW package, and `apt-get upgrade` never installs new
      # packages, so the vulnerability gate would flag the old kernel's
      # headers/tools/modules still being installed. `-qq -y` keeps it
      # non-interactive.
      "sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get -y -qq -o Dpkg::Options::=--force-confold dist-upgrade",
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
      # --- Squid install continues here, after the patched kernel is live ---
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq squid",
      "squid -v",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 2 - the OCI CLI (the one net-new OS-level step versus GCP)
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
  # Step 3 - the fail-closed default config and an empty allowlist
  # ---------------------------------------------------------------------------
  # GCP's image shipped no default and leaned on Ubuntu's stock squid.conf.
  # That is worse than it sounds: the stock config's ACL set is not this
  # platform's, so an instance whose config fetch failed was running a
  # DIFFERENT policy from the intended one rather than a stricter version of
  # it. Baking the real shape in, with an empty allowlist, makes the
  # fetch-failed state a strict subset of the fetch-succeeded state.
  #
  # This is load-bearing right now, not hypothetical: the fetch cannot possibly
  # succeed today because no instance principal exists (see
  # scripts/fetch-squid-config.sh's header).
  provisioner "file" {
    source      = "${path.root}/scripts/squid.conf.default"
    destination = "/tmp/squid.conf.default"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo install -o root -g root -m 0644 /tmp/squid.conf.default /etc/squid/squid.conf",
      "rm -f /tmp/squid.conf.default",
      # The allowlist file must EXIST before squid parses a config that
      # references it - `acl ... dstdomain \"/etc/squid/squid.allowed.sites.txt\"`
      # is a hard error against a missing file, so without this the image
      # cannot start Squid at all until a fetch succeeds.
      "sudo touch /etc/squid/squid.allowed.sites.txt",
      "sudo chown proxy:proxy /etc/squid/squid.allowed.sites.txt",
      "sudo chmod 0644 /etc/squid/squid.allowed.sites.txt",
      "sudo squid -k parse -f /etc/squid/squid.conf",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 3b - run Squid as non-root (control 13c)
  # ---------------------------------------------------------------------------
  # A systemd drop-in that makes the squid master process run as user/group
  # `proxy` (Ubuntu's stock unit leaves the master as root; only the workers
  # drop to proxy). RuntimeDirectory gives systemd ownership of /run/squid as
  # proxy:proxy, which is where squid.conf.default now puts the pid file
  # (pid_filename /run/squid/squid.pid). The perms of /var/log/squid and
  # /var/spool/squid are fixed here too - squid writes both as `proxy`.
  provisioner "file" {
    source      = "${path.root}/scripts/squid.service.d/hardening.conf"
    destination = "/tmp/squid-hardening.conf"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo mkdir -p /etc/systemd/system/squid.service.d",
      "sudo install -o root -g root -m 0644 /tmp/squid-hardening.conf /etc/systemd/system/squid.service.d/hardening.conf",
      "rm -f /tmp/squid-hardening.conf",
      # Create /run/squid now (systemd would at runtime, but the build's own
      # `sudo squid -k parse` also needs the pid dir to exist), owned proxy:proxy.
      "sudo mkdir -p /run/squid",
      "sudo chown proxy:proxy /run/squid",
      "sudo chmod 0750 /run/squid",
      # squid's log and swap directories must be writable by the `proxy` user.
      "sudo mkdir -p /var/log/squid /var/spool/squid",
      "sudo chown -R proxy:proxy /var/log/squid /var/spool/squid",
      # The drop-in only takes effect on service start; parsing the config as
      # the future runtime user proves the pid path is resolvable and owned.
      "sudo squid -k parse -f /etc/squid/squid.conf",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 4 - config-fetch and allowlist-refresh units
  # ---------------------------------------------------------------------------
  provisioner "file" {
    source      = "${path.root}/scripts/fetch-squid-config.sh"
    destination = "/tmp/fetch-squid-config.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/update-squid-whitelist.sh"
    destination = "/tmp/update-squid-whitelist.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/squid-config-fetch.service"
    destination = "/tmp/squid-config-fetch.service"
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
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo install -o root -g root -m 0755 /tmp/fetch-squid-config.sh /usr/local/bin/fetch-squid-config.sh",
      "sudo install -o root -g root -m 0755 /tmp/update-squid-whitelist.sh /usr/local/bin/update-squid-whitelist.sh",
      "sudo install -o root -g root -m 0644 /tmp/squid-config-fetch.service /etc/systemd/system/squid-config-fetch.service",
      "sudo install -o root -g root -m 0644 /tmp/squid-whitelist-fetch.service /etc/systemd/system/squid-whitelist-fetch.service",
      # `cron` ships active-by-default on this base image, same as GCP's - no
      # explicit apt-get install is needed, just a file in /etc/cron.d.
      "sudo install -o root -g root -m 0644 /tmp/squid-whitelist-update.cron /etc/cron.d/squid-whitelist-update",
      "rm -f /tmp/fetch-squid-config.sh /tmp/update-squid-whitelist.sh /tmp/squid-config-fetch.service /tmp/squid-whitelist-fetch.service /tmp/squid-whitelist-update.cron",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable squid-config-fetch.service",
      "sudo systemctl enable squid-whitelist-fetch.service",
      "sudo systemctl enable squid.service",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 5 - Vector
  # ---------------------------------------------------------------------------
  # Installed from Vector's official (Datadog-operated) APT repository, key
  # from keys.datadoghq.com, exactly as the GCP squid image does - only the
  # CURRENT signing key is imported, since a fresh image only ever pulls
  # current package metadata.
  provisioner "shell" {
    remote_folder = "/var/tmp"
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

  provisioner "file" {
    source      = "${path.root}/../shared/scripts/vector-oci-overrides.conf"
    destination = "/tmp/vector-oci-overrides.conf"
  }

  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo mkdir -p /etc/vector /etc/systemd/system/vector.service.d",
      # The uploaded file keeps the SSH user's ownership and mode 600 across a
      # bare `mv`, which leaves it unreadable by the vector.service user -
      # confirmed on GCP by a live "Permission denied" failure. `install` with
      # explicit owner/mode is the fix, not a `mv` plus a follow-up chown.
      "sudo install -o root -g vector -m 0640 /tmp/vector.toml /etc/vector/vector.toml",
      "sudo install -o root -g root -m 0644 /tmp/vector-oci-overrides.conf /etc/systemd/system/vector.service.d/oci-overrides.conf",
      "rm -f /tmp/vector.toml /tmp/vector-oci-overrides.conf",
      # Vector's .deb runs as system user `vector`; squid's package runs as
      # user/group `proxy` and access.log inherits that ownership. Without this
      # the file source silently tails nothing.
      "sudo usermod -aG proxy vector",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable vector.service",
      "sudo /usr/bin/vector validate /etc/vector/vector.toml",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 6 - HEALTH ASSERTION, before the image is captured
  # ---------------------------------------------------------------------------
  # This step has no GCP counterpart and is the most valuable thing in this
  # template. GCP's squid image was health-tested by hand on a launched
  # instance AFTER the build (the results are quoted in the squid-proxy unit's
  # comments: "squid -k parse clean, CONNECT github.com:443 -> TCP_TUNNEL/200,
  # CONNECT example.org:443 -> TCP_DENIED/403", 2026-08-20). Doing the same
  # assertions inside the build means a broken image can never be captured at
  # all, rather than being captured and then discovered broken.
  #
  # It reproduces that exact allowed/denied pair, then restores the empty
  # allowlist so the captured image ships no domain permissions. `set -eux`
  # plus explicit `exit 1`s mean any failure fails the whole build.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",

      # Temporarily allow one domain, leaving the other off the list.
      "echo '${var.selftest_allowlist_domain}' | sudo tee /etc/squid/squid.allowed.sites.txt",
      "sudo chown proxy:proxy /etc/squid/squid.allowed.sites.txt",

      "sudo squid -k parse -f /etc/squid/squid.conf",
      "sudo systemctl restart squid.service",
      "sudo systemctl is-active squid.service",
      # Squid binds a moment after the unit reports active; poll rather than sleep.
      "for i in $(seq 1 30); do if sudo ss -lntp | grep -q ':${var.squid_port} '; then break; fi; sleep 1; done",
      "sudo ss -lntp | grep ':${var.squid_port} '",

      # W3 (control 13c): NO squid process - master OR worker - may run as
      # root. With the non-root drop-in applied, every 'squid' comm entry must
      # be owned by `proxy`; the presence of a `root` row means the drop-in did
      # not apply (or the master failed to drop privileges) and must fail the
      # build. `sort -u` collapses the worker rows; the set must reduce to
      # exactly one distinct user, `proxy`.
      "SQUID_USERS=$(sudo ps -o user= -C squid | sort -u | tr -d ' ')",
      "echo \"squid processes run as: $SQUID_USERS\"",
      "test \"$SQUID_USERS\" = \"proxy\" || { echo 'SELFTEST FAILED: squid is not running as user proxy (control 13c)'; sudo ps -o user=,pid,cmd -C squid; exit 1; }",

      # W3 (control 13c): the pid file must resolve under /run/squid (as set by
      # pid_filename /run/squid/squid.pid) and be owned by proxy, not root.
      "sudo test -f /run/squid/squid.pid || { echo 'SELFTEST FAILED: squid pid file not at /run/squid/squid.pid'; exit 1; }",
      "sudo ls -l /run/squid/squid.pid",

      # ALLOWED: expect an established CONNECT tunnel and a 200 from the origin.
      "ALLOW_CODE=$(curl -s -o /dev/null -w '%%{http_code}' --max-time 30 -x http://127.0.0.1:${var.squid_port} https://${var.selftest_allowlist_domain}/ || true)",
      "echo \"allowed ${var.selftest_allowlist_domain} -> $ALLOW_CODE\"",
      "test \"$ALLOW_CODE\" = \"200\" || { echo 'SELFTEST FAILED: allowlisted CONNECT did not return 200'; sudo tail -50 /var/log/squid/access.log; exit 1; }",

      # DENIED. NOT asserted with %{http_code}, and the reason is worth
      # recording because the obvious version of this check silently tests the
      # wrong thing. `curl -x <proxy> https://…` issues a CONNECT; when the
      # PROXY refuses it, no tunnel is ever established, so there is no HTTP
      # response for curl to report a status for and %{http_code} is "000".
      # The first version of this step asserted "403" there and failed the
      # build even though Squid was behaving perfectly - the real 2026-09-05
      # run logged `TCP_TUNNEL/200 CONNECT github.com:443` and
      # `TCP_DENIED/403 CONNECT example.org:443` in the very same output that
      # reported `denied example.org -> 000`.
      #
      # Assert the three things that ARE true instead: curl fails, curl names
      # the proxy's 403 on stderr, and Squid logs the denial itself.
      "set +e; DENY_ERR=$(curl -sS -o /dev/null --max-time 30 -x http://127.0.0.1:${var.squid_port} https://${var.selftest_denied_domain}/ 2>&1); DENY_RC=$?; set -e",
      "echo \"denied ${var.selftest_denied_domain} -> rc=$DENY_RC err=$DENY_ERR\"",
      "test \"$DENY_RC\" != \"0\" || { echo 'SELFTEST FAILED: non-allowlisted CONNECT SUCCEEDED - the allowlist is not being enforced'; sudo tail -50 /var/log/squid/access.log; exit 1; }",
      # Match BOTH curl phrasings. Ubuntu 22.04 ships curl 7.81, which says
      #   curl: (56) Received HTTP code 403 from proxy after CONNECT
      # while curl >= 7.87 says
      #   curl: (56) CONNECT tunnel failed, response 403
      # Pinning to either one alone makes this assertion fail on a base-image
      # bump for a reason that has nothing to do with Squid - which is exactly
      # what happened on the 2026-09-05 run that only matched the newer text.
      "echo \"$DENY_ERR\" | grep -Eq '(response 403|HTTP code 403)' || { echo 'SELFTEST FAILED: CONNECT failed, but not with the proxy 403 that means the ACL fired'; sudo tail -50 /var/log/squid/access.log; exit 1; }",

      # And prove it in Squid's own vocabulary, not just curl's. TCP_TUNNEL vs
      # TCP_DENIED is the distinction that says the ACL fired, and it is the
      # exact pair the GCP squid image was live-validated on.
      #
      # MIND THE `.*`. Squid's native access.log format is
      #   <ts> <elapsed> <client> <code>/<status> <BYTES> <method> <url> …
      # so the response SIZE sits between the status and the method:
      #   TCP_TUNNEL/200 586171 CONNECT github.com:443 - HIER_DIRECT/20.207.73.82
      # A pattern written as "TCP_TUNNEL/200 CONNECT github.com:443" - which is
      # how the GCP result was written down in prose, and how the first version
      # of this assertion was written - matches nothing. That is a summary of
      # the log line, not a substring of it.
      "sudo grep -Eq 'TCP_TUNNEL/200 .* CONNECT ${var.selftest_allowlist_domain}:443' /var/log/squid/access.log || { echo 'SELFTEST FAILED: no TCP_TUNNEL/200 for the allowlisted domain'; sudo cat /var/log/squid/access.log; exit 1; }",
      "sudo grep -Eq 'TCP_DENIED/403 .* CONNECT ${var.selftest_denied_domain}:443' /var/log/squid/access.log || { echo 'SELFTEST FAILED: no TCP_DENIED/403 for the non-allowlisted domain'; sudo cat /var/log/squid/access.log; exit 1; }",
      "echo '--- squid access.log during selftest ---'",
      "sudo cat /var/log/squid/access.log",

      # Vector must be able to actually read that log, which is the whole point
      # of the usermod above. Checked as the vector user, not as root.
      "sudo -u vector test -r /var/log/squid/access.log || { echo 'SELFTEST FAILED: vector cannot read squid access.log'; exit 1; }",

      # Restore the shipped state: empty allowlist, squid stopped, logs cleared.
      "sudo systemctl stop squid.service",
      "sudo truncate -s 0 /etc/squid/squid.allowed.sites.txt",
      "sudo truncate -s 0 /var/log/squid/access.log || true",
      "sudo rm -f /var/log/squid/cache.log",
      "sudo squid -k parse -f /etc/squid/squid.conf",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 7 - CIS baseline (UBUNTU24-CIS, Level 1 + 2) and Trivy CVE gate (13a)
  # ---------------------------------------------------------------------------
  # CIS runs here, BEFORE ufw (Step 8): the role ships
  # `ubtu24cis_firewall_package: none`, so it never manages the host firewall -
  # the template configures ufw after, making the hardened rules the last word.
  # The playbook sets `skip_reboot: true` (the kernel was already made current
  # by the Step 1 reboot; the CIS tmpfs /tmp unit applies at the image's first
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

  # Step 7a - run the CIS role, pinned by commit, Level 1 + 2. CIS_SQUID_SERVER
  # is set so rule 2.1.17 does not remove squid.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /var/tmp/run-cis-baseline.sh",
      "sudo -n env CIS_SQUID_SERVER=true /var/tmp/run-cis-baseline.sh bfadae19d51d08e406c2c9327e3c8e510ee49cd7 /var/tmp/ubuntu2404.yml",
    ]
  }

  # Step 7b - restore the squid config-fetch/allowlist-refresh seam. CIS does
  # not manage our units, but re-assert the services are armed for boot after
  # the role ran.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo systemctl enable squid.service squid-config-fetch.service squid-whitelist-fetch.service",
      "sudo systemctl is-enabled squid.service squid-config-fetch.service squid-whitelist-fetch.service || true",
    ]
  }

  # Step 7c - Trivy CVE gate (control 13a): fail on HIGH/CRITICAL with a fix
  # in apt + non-snap software; snap payloads are reported separately, never
  # gating. See shared/scripts/trivy-scan.sh.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "chmod +x /var/tmp/trivy-scan.sh",
      "sudo -n /var/tmp/trivy-scan.sh /var/tmp/trivy-squid.json",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 8 - ufw
  # ---------------------------------------------------------------------------
  # ufw is the last non-cleanup step ON PURPOSE, mirroring GCP: with it enabled
  # the established build session survives `ufw enable`, but it sits after every
  # CIS/Trivy/selftest step so those never have to reason about the firewall.
  #
  # ADDED HERE, NOT PORTED. The GCP squid template has no ufw step at all -
  # only its envoy sibling does - and the first OCI squid image inherited that
  # omission. A real boot test of that image reported `ufw Status: inactive`,
  # which is how it was caught.
  #
  # The asymmetry was never argued for on the GCP side; it reads as an
  # oversight rather than a decision, and it is the wrong way round if either
  # image is going to have only one. This is the tier every outbound call from
  # a card-data environment is forced through so it can be allowlisted and
  # logged (the squid-proxy unit's own header). A host-level default-deny costs
  # nothing and is the same defence-in-depth argument the AWS AMI/userdata
  # pattern already makes on both proxies.
  #
  # Only two ports: 22 and the proxy port. Note what is NOT opened - unlike the
  # envoy image there is no 9273 rule, because this image's vector.toml has a
  # loki sink and no prometheus_exporter sink, so nothing listens there.
  # Opening a port nothing serves is how a firewall rule outlives its reason.
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw",
      "sudo ufw default deny incoming",
      "sudo ufw default allow outgoing",
      "sudo ufw allow 22/tcp",
      "sudo ufw allow ${var.squid_port}/tcp",
      "sudo ufw --force enable",
      "sudo ufw status verbose",
      # Assert rather than trust: `ufw --force enable` succeeding is not the
      # same as ufw being active in the captured image.
      "sudo ufw status | grep -q '^Status: active' || { echo 'SELFTEST FAILED: ufw is not active'; exit 1; }",
    ]
  }

  # ---------------------------------------------------------------------------
  # Step 9 - AIDE baseline (section 5b), rebuilt on the FINAL file state
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
  # Step 9b - pull the security reports down to the build host so they survive
  # ---------------------------------------------------------------------------
  # The trivy gate (Step 7) writes its reports to /var/tmp and Step 10 deletes
  # them before the instance is torn down, which would otherwise make the
  # "save trivy/CIS/AIDE report" requirement a no-op. Download them (plus the
  # CIS ansible log) to ${path.root}/trivy-reports/ on this machine BEFORE the
  # cleanup step removes them from the instance.
  provisioner "file" {
    source      = "/var/tmp/trivy-squid.json"
    destination = "${path.root}/trivy-reports/trivy-squid.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/tmp/trivy-squid.json.with-snaps.json"
    destination = "${path.root}/trivy-reports/trivy-squid.json.with-snaps.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/tmp/trivy-squid.json.sbom.cdx.json"
    destination = "${path.root}/trivy-reports/trivy-squid.json.sbom.cdx.json"
    direction   = "download"
  }
  provisioner "file" {
    source      = "/var/log/cis-baseline-build.log"
    destination = "${path.root}/trivy-reports/cis-baseline-build.log"
    direction   = "download"
  }

  # ---------------------------------------------------------------------------
  # Step 10 - cleanup before imaging
  # ---------------------------------------------------------------------------
  provisioner "shell" {
    remote_folder = "/var/tmp"
    inline = [
      "set -eux",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
      # Squid's swap directory is rebuilt on first start; leaving a
      # build-machine-specific one in the image is pure noise.
      "sudo rm -rf /var/spool/squid/*",
      "sudo rm -f /etc/squid/squid.conf.old /etc/squid/squid.allowed.sites.txt.old",
      "sudo rm -f /var/tmp/run-cis-baseline.sh /var/tmp/trivy-scan.sh /var/tmp/trivy-squid.json /var/tmp/trivy-squid.json.with-snaps.json /var/tmp/trivy-squid.json.sbom.cdx.json /var/tmp/ubuntu2404.yml",
      "sudo rm -f /usr/local/sbin/wait-for-apt.sh",
      "sudo cloud-init clean --logs || true",
      "history -c || true",
    ]
  }

  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
