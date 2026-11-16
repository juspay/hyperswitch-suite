#!/bin/bash
set -euxo pipefail

# =============================================================================
# The OCI CLI, installed into the image so boot-time scripts can read Object
# Storage. This is the single piece of net-new OS-level work the OCI port
# needs that the GCP port did not.
# =============================================================================
# WHY IT IS NEEDED. GCP's images call `gsutil`, which is preinstalled on every
# GCE Ubuntu image and authenticates automatically as the instance's attached
# service account. Neither half of that is true on OCI: Canonical's OCI
# platform images do not ship the OCI CLI, and there is no ambient credential.
# `docs/multi-cloud-parity/oci/vm-tier-and-images.md` section 4 predicted
# exactly one OS-level delta for this port - "only the config-fetch mechanism
# at the very end changes (`oci os object get` via the OCI CLI instead of
# `gsutil cp`/`aws s3 cp`)" - and this script is that delta, made explicit.
#
# WHY THE PINNED WHEEL AND NOT THE OFFICIAL INSTALLER.
#   * There is no `oci-cli` package in Ubuntu's archive, and none in a
#     first-party Oracle apt repo for Ubuntu (Oracle publishes RPMs for Oracle
#     Linux only). So apt is not an option.
#   * Oracle's own installer (raw.githubusercontent.com/oracle/oci-cli/master),
#     the URL Oracle's install docs publish, is UNPINNED AND UNCHECKSUMMED: it
#     downloads from the `master` branch. Control 12a/13a (build hygiene) wants
#     a reproducible install, so this script pins a specific release instead.
#     The installer itself takes no version argument, so the supported
#     alternative from the hardening workplan is a venv + pip install of a
#     PINNED oci-cli wheel.
#   * A venv keeps the CLI's dependency tree out of Ubuntu's PEP-668
#     externally-managed system Python on 22.04+.
#
# The CLI is pinned to oci-cli==3.94.2 (released 2026-10-06). Releasing a newer
# version is downstream maintenance, not something this script guesses at.
#
# The install is pinned to a directory rather than to $HOME so it belongs to
# the image, not to whichever user Packer happened to connect as - the boot
# scripts that use it run as root from systemd, not as `ubuntu`.
# =============================================================================

OCI_CLI_INSTALL_DIR=/opt/oci-cli
OCI_CLI_BIN_DIR=/usr/local/bin
OCI_CLI_VERSION=3.94.2

sudo mkdir -p "${OCI_CLI_INSTALL_DIR}"

# Build a self-contained venv. The distro `python3-venv` metapackage is what
# provides pip/ensurepip (python3.12-venv on 24.04, python3.14-venv on 26.04);
# OCI's 26.04 base does not ship it, so install it explicitly for both.
if ! dpkg -s python3-venv >/dev/null 2>&1; then
  sudo apt-get install -y -qq python3-venv
fi
sudo python3 -m venv "${OCI_CLI_INSTALL_DIR}"
if [ ! -x "${OCI_CLI_INSTALL_DIR}/bin/pip" ]; then
  sudo "${OCI_CLI_INSTALL_DIR}/bin/python" -m ensurepip --upgrade || sudo python3 -m ensurepip --upgrade
fi

sudo "${OCI_CLI_INSTALL_DIR}/bin/pip" install --index-url https://pypi.org/simple --upgrade "oci-cli==${OCI_CLI_VERSION}"

# Symlink the CLI in to a directory every systemd unit's default PATH can see.
# systemd services get PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/
# sbin:/bin with no shell profile sourced, so /usr/local/bin is the only
# sensible target; an install under /root/bin or /home/ubuntu/lib would be
# invisible to the boot-time fetch units that are this CLI's only consumer.
sudo ln -sf "${OCI_CLI_INSTALL_DIR}/bin/oci" "${OCI_CLI_BIN_DIR}/oci"

# Prove it landed somewhere every systemd unit's default PATH can see.
sudo test -x "${OCI_CLI_BIN_DIR}/oci"
/usr/local/bin/oci --version
