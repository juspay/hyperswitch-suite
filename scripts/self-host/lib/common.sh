# shellcheck shell=bash
# Shared helpers for the merchant bootstrap generator: colors, prompts, validators.

CYAN='\033[0;36m'
GREEN='\033[0;32m'
GREY='\033[0;90m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${CYAN}▸${NC} $*"; }
ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}!${NC} $*" >&2; }
die() {
    echo -e "${RED}✗${NC} $*" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Validators. Each takes the candidate value and returns 0/1.
# ---------------------------------------------------------------------------

validate_name() { [[ "$1" =~ ^[a-z][a-z0-9-]{1,20}$ ]]; }
validate_account_id() { [[ "$1" =~ ^[0-9]{12}$ ]]; }
validate_region() { [[ "$1" =~ ^[a-z]{2}(-[a-z]+)+-[0-9]$ ]]; }
validate_vpc_id() { [[ "$1" =~ ^vpc-[0-9a-f]{8,17}$ ]]; }
validate_subnet_id() { [[ "$1" =~ ^subnet-[0-9a-f]{8,17}$ ]]; }
validate_ami_id() { [[ -z "$1" || "$1" =~ ^ami-[0-9a-f]{8,17}$ ]]; }
validate_cidr() { [[ "$1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[12][0-9]|3[0-2])$ ]]; }
validate_role_arn() { [[ "$1" =~ ^arn:aws:iam::[0-9]{12}:role/.+$ ]]; }
validate_acm_arn() { [[ "$1" =~ ^arn:aws:acm:[a-z0-9-]+:[0-9]{12}:certificate/.+$ ]]; }
validate_domain() { [[ "$1" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]]; }
validate_git_url() { [[ "$1" =~ ^(https://|http://|git@|ssh://).+ ]]; }
validate_s3_bucket() { [[ "$1" =~ ^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$ ]]; }
validate_environment() { [[ "$1" == "prod" || "$1" == "sandbox" ]]; }
validate_yes_no() { [[ "$1" == "y" || "$1" == "n" ]]; }
validate_db_class() { [[ "$1" =~ ^db\.[a-z0-9]+\.[a-z0-9]+$ ]]; }
validate_cache_type() { [[ "$1" =~ ^cache\.[a-z0-9]+\.[a-z0-9]+$ ]]; }
validate_eks_version() { [[ "$1" =~ ^1\.[0-9]{2}$ ]]; }
validate_nonempty() { [[ -n "$1" ]]; }
validate_anything() { return 0; }

# Comma-separated list validators
validate_subnet_id_list() {
    local item
    IFS=',' read -r -a _items <<<"$1"
    [[ ${#_items[@]} -ge 1 ]] || return 1
    for item in "${_items[@]}"; do
        validate_subnet_id "$item" || return 1
    done
}

validate_cidr_list() {
    local item
    IFS=',' read -r -a _items <<<"$1"
    [[ ${#_items[@]} -ge 1 ]] || return 1
    for item in "${_items[@]}"; do
        validate_cidr "$item" || return 1
    done
}

validate_instance_type_list() {
    local item
    IFS=',' read -r -a _items <<<"$1"
    [[ ${#_items[@]} -ge 1 ]] || return 1
    for item in "${_items[@]}"; do
        [[ "$item" =~ ^[a-z0-9]+\.[a-z0-9]+$ ]] || return 1
    done
}

# ---------------------------------------------------------------------------
# prompt_var VAR_NAME "Prompt text" "default" validator_fn
#
# Reads into the named variable. In non-interactive mode the variable must
# already hold a valid value (from the config file) or we fail. Interactive
# mode pre-fills the default from any existing value, then the given default.
# ---------------------------------------------------------------------------
prompt_var() {
    local var_name="$1" prompt_text="$2" default_value="$3" validator="$4"
    local current="${!var_name:-}"
    [[ -n "$current" ]] && default_value="$current"

    if [[ "${NON_INTERACTIVE:-0}" == "1" ]]; then
        if ! "$validator" "$default_value"; then
            die "Non-interactive mode: config value for ${var_name} ('${default_value}') is missing or invalid."
        fi
        printf -v "$var_name" '%s' "$default_value"
        return 0
    fi

    # Read from the controlling terminal explicitly, not inherited stdin.
    # When this runs at the end of `curl ... | bash`, stdin IS the pipe from
    # curl — by the time execution reaches here, that pipe is already at EOF
    # (bash consumed it all just reading the script), so a plain `read` here
    # would silently return failure on every prompt and, under `set -e`,
    # kill the whole run without printing anything.
    if [[ ! -r /dev/tty ]]; then
        die "No interactive terminal available to prompt for '${var_name}' (stdin isn't a TTY — e.g. running via 'curl | bash'). Re-run with --non-interactive --config <file>, or download the script first: curl -fsSL <url> -o generate.sh && bash generate.sh ..."
    fi

    local answer
    while true; do
        if [[ -n "$default_value" ]]; then
            echo -en "${CYAN}◆${NC} ${prompt_text} ${GREY}[${default_value}]${NC}: "
        else
            echo -en "${CYAN}◆${NC} ${prompt_text}: "
        fi
        read -r answer </dev/tty
        answer="${answer:-$default_value}"
        if "$validator" "$answer"; then
            printf -v "$var_name" '%s' "$answer"
            return 0
        fi
        warn "Invalid value: '${answer}' (validator: ${validator#validate_})"
    done
}

# Convert "a,b,c" to an HCL list string: ["a", "b", "c"]
to_hcl_list() {
    local out="[" item first=1
    IFS=',' read -r -a _items <<<"$1"
    for item in "${_items[@]}"; do
        [[ $first -eq 0 ]] && out+=", "
        out+="\"${item}\""
        first=0
    done
    out+="]"
    printf '%s' "$out"
}

# Convert y/n to true/false
to_bool() { [[ "$1" == "y" ]] && printf 'true' || printf 'false'; }
