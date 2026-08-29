#!/usr/bin/env bash
#
# Hyperswitch self-host generator.
#
# Run this from your fork/copy of hyperswitch-suite. It prompts for your
# environment values (AWS account, VPC, domains, sizing, ...) and renders:
#
#   terraform/aws/live/<env>/terragrunt.stack.hcl   (Terragrunt standalone stack)
#   argocd/                                         (ArgoCD app-of-apps bundle)
#   install-argocd.sh                               (cluster bootstrap script)
#   SELF_HOST.md                                    (your runbook)
#   hyperswitch-bootstrap.conf                      (saved answers for reruns)
#
# Your fork becomes the config repo that ArgoCD points at — commit and push
# the rendered files.
#
# Usage:
#   scripts/self-host/generate.sh [--target-dir <path>] [--config <file>]
#                                 [--non-interactive] [--force]
#
#   --target-dir       Render into this directory (default: this repo's root).
#   --config           Answers file (default: <target>/hyperswitch-bootstrap.conf).
#   --non-interactive  No prompts; the config file must be complete.
#   --force            Overwrite previously rendered files.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"
# shellcheck source=lib/render.sh
source "${SCRIPT_DIR}/lib/render.sh"

TARGET_DIR=""
CONFIG_PATH=""
NON_INTERACTIVE=0
FORCE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
    --target-dir)
        TARGET_DIR="$2"
        shift 2
        ;;
    --config)
        CONFIG_PATH="$2"
        shift 2
        ;;
    --non-interactive)
        NON_INTERACTIVE=1
        shift
        ;;
    --force)
        FORCE=1
        shift
        ;;
    -h | --help)
        sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
    *)
        die "Unknown argument: $1 (see --help)"
        ;;
    esac
done

TARGET_DIR="${TARGET_DIR:-$REPO_ROOT}"
mkdir -p "$TARGET_DIR"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

if [[ ! -d "${TARGET_DIR}/.git" ]]; then
    warn "${TARGET_DIR} is not a git repository. ArgoCD reads values from the pushed repo, so this should be your fork of hyperswitch-suite."
fi

if [[ -e "${TARGET_DIR}/argocd" ]]; then
    if [[ "$FORCE" -ne 1 ]]; then
        die "${TARGET_DIR}/argocd already exists. Rerun with --force to overwrite the rendered files."
    fi
    warn "Overwriting previously rendered files in ${TARGET_DIR} (--force)."
fi

CONFIG_PATH="${CONFIG_PATH:-${TARGET_DIR}/${CONFIG_FILE_NAME}}"
load_config "$CONFIG_PATH"

# ---------------------------------------------------------------------------
# Collect inputs
# ---------------------------------------------------------------------------
detected_origin=""
if [[ -d "${TARGET_DIR}/.git" ]]; then
    detected_origin="$(git -C "$TARGET_DIR" remote get-url origin 2>/dev/null || true)"
fi

echo ""
info "Project & repository"
prompt_var MERCHANT_NAME "Project name (lowercase, hyphens; used as project_name/prefix)" "" validate_name
prompt_var MERCHANT_REPO_URL "Git URL of this repo (as ArgoCD will fetch it)" "$detected_origin" validate_git_url
prompt_var ENVIRONMENT "Environment (prod|sandbox)" "prod" validate_environment
if [[ "$ENVIRONMENT" == "prod" ]]; then ENV_SHORT="prd"; else ENV_SHORT="sbx"; fi

echo ""
info "AWS account & network (your existing VPC)"
prompt_var AWS_ACCOUNT_ID "AWS account id" "" validate_account_id
prompt_var AWS_REGION "AWS region" "us-east-1" validate_region
prompt_var STATE_BUCKET "Terraform state S3 bucket (must already exist)" "${MERCHANT_NAME}-${ENV_SHORT}-${AWS_REGION}-terraform-state" validate_s3_bucket
prompt_var VPC_ID "VPC id" "" validate_vpc_id
prompt_var VPC_CIDR "VPC CIDR" "" validate_cidr
prompt_var DB_SUBNET_IDS "Database subnet ids (comma-separated, >=2 AZs)" "" validate_subnet_id_list
prompt_var CACHE_SUBNET_IDS "ElastiCache subnet ids (comma-separated)" "$DB_SUBNET_IDS" validate_subnet_id_list
prompt_var EKS_WORKER_SUBNET_IDS "EKS worker (private) subnet ids (comma-separated)" "" validate_subnet_id_list
prompt_var EKS_CP_SUBNET_IDS "EKS control-plane subnet ids (comma-separated)" "$EKS_WORKER_SUBNET_IDS" validate_subnet_id_list
prompt_var PUBLIC_SUBNET_IDS "Public/load-balancer subnet ids (comma-separated)" "" validate_subnet_id_list

echo ""
info "Access & ingress"
prompt_var ADMIN_ROLE_ARN "IAM role ARN for EKS cluster-admin access" "" validate_role_arn
prompt_var ADMIN_ACCESS_CIDRS "CIDRs allowed to reach the EKS public endpoint (comma-separated)" "" validate_cidr_list
prompt_var ACM_CERT_ARN "ACM certificate ARN for the ingress domains" "" validate_acm_arn
prompt_var ROUTER_DOMAIN "Hyperswitch API (router) domain" "" validate_domain
prompt_var SDK_DOMAIN "SDK (hyperswitch-web) domain" "" validate_domain
prompt_var CONTROL_CENTER_DOMAIN "Control center domain" "" validate_domain

echo ""
info "Sizing"
prompt_var DB_INSTANCE_CLASS "Aurora instance class" "db.r5.large" validate_db_class
prompt_var DB_ENGINE_VERSION "Aurora PostgreSQL engine version" "17.9" validate_nonempty
prompt_var CACHE_NODE_TYPE "ElastiCache node type" "cache.m6g.large" validate_cache_type
prompt_var EKS_VERSION "EKS version" "1.33" validate_eks_version
prompt_var EKS_INSTANCE_TYPES "EKS node instance types (comma-separated)" "t3.xlarge" validate_instance_type_list
prompt_var EKS_AMI_ID "EKS node AMI id (blank = module default AL2023)" "" validate_ami_id

echo ""
info "Images & versions"
prompt_var IMAGE_REGISTRY "Container image registry for hyperswitch images" "docker.juspay.io/juspaydotin" validate_nonempty
prompt_var HS_CHART_VERSION "hyperswitch-helm git tag for the hyperswitch-stack chart" "v0.2.25" validate_nonempty
prompt_var TFSTATE_PLUGIN_IMAGE "helm-terraform-states plugin image (must be pullable from the cluster)" "juspaydotin/helm-terraform-states:v0.4.0" validate_nonempty

echo ""
info "Optional components"
prompt_var ENABLE_KARPENTER "Enable karpenter app skeleton? (y/n)" "n" validate_yes_no
prompt_var ENABLE_ESO "Enable external-secrets-operator? (y/n)" "y" validate_yes_no
prompt_var ENABLE_CONTROL_CENTER "Enable hyperswitch control center? (y/n)" "y" validate_yes_no

# ---------------------------------------------------------------------------
# Derived values for templates
# ---------------------------------------------------------------------------
DB_SUBNET_IDS_HCL="$(to_hcl_list "$DB_SUBNET_IDS")"
CACHE_SUBNET_IDS_HCL="$(to_hcl_list "$CACHE_SUBNET_IDS")"
EKS_WORKER_SUBNET_IDS_HCL="$(to_hcl_list "$EKS_WORKER_SUBNET_IDS")"
EKS_CP_SUBNET_IDS_HCL="$(to_hcl_list "$EKS_CP_SUBNET_IDS")"
PUBLIC_SUBNET_IDS_HCL="$(to_hcl_list "$PUBLIC_SUBNET_IDS")"
ADMIN_ACCESS_CIDRS_HCL="$(to_hcl_list "$ADMIN_ACCESS_CIDRS")"
EKS_INSTANCE_TYPES_HCL="$(to_hcl_list "$EKS_INSTANCE_TYPES")"
if [[ -n "$EKS_AMI_ID" ]]; then EKS_AMI_ID_HCL="\"${EKS_AMI_ID}\""; else EKS_AMI_ID_HCL="null"; fi
KARPENTER_ENABLED="$(to_bool "$ENABLE_KARPENTER")"
ESO_ENABLED="$(to_bool "$ENABLE_ESO")"
CONTROL_CENTER_ENABLED="$(to_bool "$ENABLE_CONTROL_CENTER")"

# Extra valueFiles lines for the root app-of-apps, one per enabled optional app.
OPTIONAL_APP_VALUEFILES=""
if [[ "$ENABLE_ESO" == "y" ]]; then
    OPTIONAL_APP_VALUEFILES+=$'\n'"                - \$values/argocd/apps/infra/external-secrets-operator.yaml"
fi
if [[ "$ENABLE_KARPENTER" == "y" ]]; then
    OPTIONAL_APP_VALUEFILES+=$'\n'"                - \$values/argocd/apps/infra/karpenter.yaml"
fi

# ---------------------------------------------------------------------------
# Generate
# ---------------------------------------------------------------------------
echo ""
info "Rendering self-host bundle into ${TARGET_DIR}"

# 1. Terragrunt: live stack file targeting the in-repo standalone catalog stack
render_file "${TEMPLATES_DIR}/terraform/live/terragrunt.stack.hcl.tpl" \
    "${TARGET_DIR}/terraform/aws/live/${ENVIRONMENT}/terragrunt.stack.hcl"
ok "terraform/aws/live/${ENVIRONMENT}/terragrunt.stack.hcl"

# 2. ArgoCD tree
render_file "${TEMPLATES_DIR}/argocd/argo-apps.yaml.tpl" "${TARGET_DIR}/argocd/argo-apps.yaml"
render_file "${TEMPLATES_DIR}/argocd/bootstrap/argocd.yaml.tpl" "${TARGET_DIR}/argocd/bootstrap/argocd.yaml"
for project in infra hyperswitch monitoring; do
    render_file "${TEMPLATES_DIR}/argocd/projects/${project}.yaml.tpl" "${TARGET_DIR}/argocd/projects/${project}.yaml"
done
for app in alb-controller istio; do
    render_file "${TEMPLATES_DIR}/argocd/apps/infra/${app}.yaml.tpl" "${TARGET_DIR}/argocd/apps/infra/${app}.yaml"
done
if [[ "$ENABLE_ESO" == "y" ]]; then
    render_file "${TEMPLATES_DIR}/argocd/apps/infra/external-secrets-operator.yaml.tpl" \
        "${TARGET_DIR}/argocd/apps/infra/external-secrets-operator.yaml"
fi
if [[ "$ENABLE_KARPENTER" == "y" ]]; then
    render_file "${TEMPLATES_DIR}/argocd/apps/infra/karpenter.yaml.tpl" \
        "${TARGET_DIR}/argocd/apps/infra/karpenter.yaml"
fi
for app in hyperswitch-stack superposition; do
    render_file "${TEMPLATES_DIR}/argocd/apps/hyperswitch/${app}.yaml.tpl" "${TARGET_DIR}/argocd/apps/hyperswitch/${app}.yaml"
done
for app in loki grafana victoria-metrics vector; do
    render_file "${TEMPLATES_DIR}/argocd/apps/monitoring/${app}.yaml.tpl" "${TARGET_DIR}/argocd/apps/monitoring/${app}.yaml"
done
ok "argocd/ app-of-apps, projects and applications"

# 3. infra-configurations + deployment-configs
for app in argocd alb-controller istio hyperswitch-stack superposition loki grafana victoria-metrics vector; do
    render_file "${TEMPLATES_DIR}/infra-configurations/${app}/values.yaml.tpl" \
        "${TARGET_DIR}/infra-configurations/${app}/values.yaml"
done
render_file "${TEMPLATES_DIR}/deployment-configs/hyperswitch-stack/values-dep.yaml.tpl" \
    "${TARGET_DIR}/deployment-configs/hyperswitch-stack/values-dep.yaml"
ok "infra-configurations/ + deployment-configs/"

# 4. Install script + runbook
render_file "${TEMPLATES_DIR}/install-argocd.sh.tpl" "${TARGET_DIR}/install-argocd.sh"
chmod +x "${TARGET_DIR}/install-argocd.sh"
render_file "${TEMPLATES_DIR}/SELF_HOST.md.tpl" "${TARGET_DIR}/SELF_HOST.md"
ok "install-argocd.sh, SELF_HOST.md"

# 5. Ensure gitignore entries (append-only; never clobber an existing .gitignore)
for entry in ".terragrunt-cache/" "*.tfstate" "*.tfstate.backup"; do
    if ! grep -qxF "$entry" "${TARGET_DIR}/.gitignore" 2>/dev/null; then
        echo "$entry" >>"${TARGET_DIR}/.gitignore"
    fi
done
ok ".gitignore entries"

# 6. Save answers + final assertion (rendered dirs only — the repo itself
#    contains __TOKEN__ patterns inside scripts/self-host/templates/)
save_config "${TARGET_DIR}/${CONFIG_FILE_NAME}"
assert_no_tokens "${TARGET_DIR}/argocd"
assert_no_tokens "${TARGET_DIR}/infra-configurations"
assert_no_tokens "${TARGET_DIR}/deployment-configs"
assert_no_tokens "${TARGET_DIR}/terraform/aws/live/${ENVIRONMENT}"
[[ -f "${TARGET_DIR}/install-argocd.sh" ]] && ! grep -qE '__[A-Z][A-Z0-9_]*__' "${TARGET_DIR}/install-argocd.sh" || true

echo ""
ok "Done. Self-host bundle rendered at: ${TARGET_DIR}"
cat <<NEXT

Next steps:
  1. Review the rendered files, then commit and push:
       git add -A && git commit -m 'hyperswitch self-host bootstrap' && git push
     (ArgoCD reads values from the pushed repo: ${MERCHANT_REPO_URL})
  2. Follow SELF_HOST.md:
       - cd terraform/aws/live/${ENVIRONMENT} && terragrunt stack generate
       - terragrunt run-all apply                  (infra, in dependency order)
       - create application secrets               (kubectl snippets in SELF_HOST.md)
       - ./install-argocd.sh                      (ArgoCD bootstrap)
       - sync apps: istio -> monitoring -> superposition -> hyperswitch-stack
NEXT
