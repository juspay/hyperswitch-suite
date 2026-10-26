#!/usr/bin/env bash
#
# Curl-pipeable entry point for the Hyperswitch self-host generator.
#
# generate.sh normally runs from inside a checkout of hyperswitch-suite (it
# sources scripts/self-host/lib/*.sh and reads scripts/self-host/templates/
# and terraform/aws/catalog/ off disk). This wrapper fetches a throwaway
# tarball snapshot of the repo (no git, no history, no persistent checkout),
# runs generate.sh from inside it into your --target-dir, then deletes the
# snapshot — the only thing left on disk afterwards is --target-dir.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/juspay/hyperswitch-suite/main/scripts/self-host/bootstrap.sh \
#     | bash -s -- --target-dir ./my-hyperswitch-infra
#
#   # Pin a specific tag/branch/commit of the generator itself (independent of
#   # the per-unit module tags baked into the catalog):
#   ... | bash -s -- --target-dir ./my-hyperswitch-infra --ref v1.2.3
#
#   # Everything else is forwarded to generate.sh unchanged:
#   ... | bash -s -- --target-dir ./my-hyperswitch-infra --non-interactive --config ./answers.conf
#
# Requires: curl, tar. Does NOT require git to fetch the source (generate.sh
# itself still runs `git init` on --target-dir, since that output directory
# is what you push and point ArgoCD at).

set -euo pipefail

GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
info() { echo -e "${CYAN}▸${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
die() {
    echo -e "${RED}✗${NC} $*" >&2
    exit 1
}

REPO_OWNER="${HYPERSWITCH_SUITE_OWNER:-juspay}"
REPO_NAME="${HYPERSWITCH_SUITE_REPO:-hyperswitch-suite}"
REF="self-host-catalog" # move to main once PR is merged
TARGET_DIR=""
PASSTHROUGH_ARGS=()

usage() {
    sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --ref)
        REF="$2"
        shift 2
        ;;
    --target-dir)
        TARGET_DIR="$2"
        PASSTHROUGH_ARGS+=("--target-dir" "$2")
        shift 2
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        PASSTHROUGH_ARGS+=("$1")
        shift
        ;;
    esac
done

[[ -n "$TARGET_DIR" ]] || die "--target-dir is required (there is no local checkout to default to). See --help."
command -v curl >/dev/null || die "curl is required."
command -v tar >/dev/null || die "tar is required."

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

archive_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/archive/${REF}.tar.gz"
info "Fetching ${REPO_OWNER}/${REPO_NAME}@${REF} (snapshot only, no git history)"
curl -fsSL "$archive_url" -o "${tmp}/src.tar.gz" \
    || die "Failed to download ${archive_url} (check --ref '${REF}' exists)"

tar -xzf "${tmp}/src.tar.gz" -C "$tmp"

extracted="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d -name "${REPO_NAME}-*")"
[[ -n "$extracted" && -d "$extracted" ]] || die "Could not find extracted source tree under ${tmp}"

generator="${extracted}/scripts/self-host/generate.sh"
[[ -f "$generator" ]] || die "Downloaded snapshot has no scripts/self-host/generate.sh (bad --ref?)"

ok "Fetched snapshot; handing off to generate.sh"
bash "$generator" "${PASSTHROUGH_ARGS[@]}"
