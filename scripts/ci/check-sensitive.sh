#!/usr/bin/env bash
#
# Sensitive-data gate: fails if internal Juspay identifiers, endpoints or
# credentials-looking strings appear anywhere in the repo.
#
# Usage: scripts/ci/check-sensitive.sh [path]   (default: repo root)
#
# Legitimate hits (public registries, docs links) go in
# scripts/ci/sensitive-allowlist.txt — one substring per line, '#' comments.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(cd "${SCRIPT_DIR}/../.." && pwd)}"
ALLOWLIST="${SCRIPT_DIR}/sensitive-allowlist.txt"

# Internal account IDs, hosts, identifiers and secret-shaped strings.
PATTERN='223655089699|143555788000|211125655926|997208230940|576373346466|bitbucket\.juspay\.net|[a-z0-9.-]*juspay\.net|@juspay\.in|\.gr7\.|C05SDGYKFM1|AWSReservedSSO|InfraMCP|StrongPassword|chpasswd|44\.214\.22\.235|44\.213\.159\.167|vpce-svc-[0-9a-f]+|vpc-hyperswitch'

hits="$(grep -rInE "$PATTERN" "$TARGET" \
    --exclude-dir=.git \
    --exclude-dir=.terragrunt-cache \
    --exclude-dir=img \
    --exclude-dir=node_modules \
    --exclude='*.zip' \
    --exclude='sensitive-allowlist.txt' \
    --exclude='check-sensitive.sh' \
    2>/dev/null || true)"

# Filter out allowlisted substrings
if [[ -n "$hits" && -f "$ALLOWLIST" ]]; then
    while IFS= read -r allow; do
        [[ -z "$allow" || "$allow" == \#* ]] && continue
        hits="$(printf '%s\n' "$hits" | grep -vF "$allow" || true)"
    done <"$ALLOWLIST"
fi

if [[ -n "$hits" ]]; then
    echo "✗ Sensitive/internal data found:" >&2
    printf '%s\n' "$hits" >&2
    echo "" >&2
    echo "Remove the data or, if it is a legitimate public reference, add a line to ${ALLOWLIST}." >&2
    exit 1
fi

echo "✓ No sensitive data found under ${TARGET}"
