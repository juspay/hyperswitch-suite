#!/usr/bin/env bash
#
# GCP catalog pin gate: every `?ref=` in terraform/gcp/catalog must point at a
# tag that actually exists in this repository.
#
# A catalog is only consumable if its pins resolve. A unit pinned to a branch
# (or to a tag nobody cut) silently changes under its consumers, or fails at
# `terragrunt init` with a confusing "couldn't find remote ref" error.
#
# Usage: scripts/ci/check-gcp-pins.sh
#
# Requires a checkout with tags fetched (actions/checkout needs fetch-depth: 0
# and fetch-tags: true).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CATALOG="${REPO_ROOT}/terraform/gcp/catalog"

if [[ ! -d "$CATALOG" ]]; then
    echo "✗ ${CATALOG} not found" >&2
    exit 1
fi

missing=()
branch_pins=()
checked=0

while IFS= read -r line; do
    file="${line%%:*}"
    ref="${line##*\?ref=}"
    ref="${ref%%\"*}"
    checked=$((checked + 1))

    # A pin that isn't a tag is a bug regardless of whether it resolves.
    if ! [[ "$ref" =~ ^gcp-[a-z0-9-]+-v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        branch_pins+=("${file#"${REPO_ROOT}/"} -> ${ref}")
        continue
    fi

    if ! git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/${ref}" >/dev/null; then
        missing+=("${file#"${REPO_ROOT}/"} -> ${ref}")
    fi
done < <(grep -rn '?ref=' "$CATALOG" --include='*.hcl' | sed 's/^\([^:]*\):[0-9]*:/\1:/')

status=0

if ((${#branch_pins[@]})); then
    echo "✗ Non-tag pins found (expected gcp-<module>-vX.Y.Z):" >&2
    printf '    %s\n' "${branch_pins[@]}" >&2
    echo "" >&2
    status=1
fi

if ((${#missing[@]})); then
    echo "✗ Pinned tags that do not exist in this repository:" >&2
    printf '    %s\n' "${missing[@]}" >&2
    echo "" >&2
    echo "  Cut the missing module tags (see terraform/gcp/catalog/README.md)" >&2
    echo "  or correct the pin." >&2
    status=1
fi

if ((status == 0)); then
    echo "✓ All ${checked} GCP catalog pins resolve to existing tags"
fi

exit "$status"
