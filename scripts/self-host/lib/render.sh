# shellcheck shell=bash
# Template rendering: replaces __TOKEN__ placeholders with config/derived
# values using pure bash string substitution (no sed, so values may contain
# any character including / & and newlines).

# All substitutable tokens: prompted config keys plus derived values that
# generate.sh computes before rendering.
TOKEN_KEYS=(
    MERCHANT_NAME
    MERCHANT_REPO_URL
    ENVIRONMENT
    ENV_SHORT
    AWS_ACCOUNT_ID
    AWS_REGION
    STATE_BUCKET
    VPC_ID
    VPC_CIDR
    DB_SUBNET_IDS_HCL
    CACHE_SUBNET_IDS_HCL
    EKS_WORKER_SUBNET_IDS_HCL
    EKS_CP_SUBNET_IDS_HCL
    PUBLIC_SUBNET_IDS_HCL
    ADMIN_ROLE_ARN
    ADMIN_ACCESS_CIDRS_HCL
    ACM_CERT_ARN
    ROUTER_DOMAIN
    SDK_DOMAIN
    CONTROL_CENTER_DOMAIN
    DB_INSTANCE_CLASS
    DB_ENGINE_VERSION
    CACHE_NODE_TYPE
    EKS_VERSION
    EKS_INSTANCE_TYPES_HCL
    EKS_AMI_ID_HCL
    IMAGE_REGISTRY
    HS_CHART_VERSION
    TFSTATE_PLUGIN_IMAGE
    KARPENTER_ENABLED
    ESO_ENABLED
    CONTROL_CENTER_ENABLED
    OPTIONAL_APP_VALUEFILES
)

# render_file <template> <destination>
render_file() {
    local tpl="$1" dest="$2"
    [[ -f "$tpl" ]] || die "Template not found: ${tpl}"
    mkdir -p "$(dirname "$dest")"

    local content key
    content="$(cat "$tpl")"
    for key in "${TOKEN_KEYS[@]}"; do
        content="${content//__${key}__/${!key:-}}"
    done
    printf '%s\n' "$content" >"$dest"
}

# copy_tree <src-dir> <dest-dir> — verbatim copy for static template trees.
copy_tree() {
    local src="$1" dest="$2"
    [[ -d "$src" ]] || die "Static template dir not found: ${src}"
    mkdir -p "$dest"
    cp -R "$src/." "$dest/"
}

# assert_no_tokens <dir> — fail if any __TOKEN__ placeholder survived
# rendering. ArgoCD {{param}} and Terragrunt ${...} pass through untouched;
# only our double-underscore convention is checked.
assert_no_tokens() {
    local dir="$1" leaks
    leaks="$(grep -R -n -E '__[A-Z][A-Z0-9_]*__' "$dir" \
        --include='*.yaml' --include='*.yml' --include='*.hcl' \
        --include='*.sh' --include='*.md' --include='.gitignore' 2>/dev/null || true)"
    if [[ -n "$leaks" ]]; then
        echo "$leaks" >&2
        die "Unrendered __TOKEN__ placeholders remain in generated output (see above)."
    fi
}
