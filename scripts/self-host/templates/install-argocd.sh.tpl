#!/usr/bin/env bash
#
# ArgoCD bootstrap for the self-hosted Hyperswitch cluster.
#
# Reads the release/version/values definitions from the argocd/ app files (the
# single source of truth) and installs, in order:
#   1. aws-load-balancer-controller   (argocd/apps/infra/alb-controller.yaml)
#   2. argo-cd                        (argocd/bootstrap/argocd.yaml)
#   3. argocd-apps root app-of-apps   (argocd/argo-apps.yaml)
#
# After step 3, ArgoCD self-manages everything from the git repo.
#
# Requirements: kubectl context pointing at the cluster, helm, yq (v4).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

ALB_APP_FILE="argocd/apps/infra/alb-controller.yaml"
ARGOCD_APP_FILE="argocd/bootstrap/argocd.yaml"
ARGOAPPS_APP_FILE="argocd/argo-apps.yaml"

for tool in kubectl helm yq; do
    command -v "$tool" >/dev/null || { echo "✗ $tool is required" >&2; exit 1; }
done

# Extract release name, chart version, namespace and valueFiles from an
# argocd-apps values file (applications.* or applicationsets.* entry).
get_app_values() {
    local app_file="$1" kind key path
    kind="applications"
    key="$(yq e '.applications | keys | .[0]' "$app_file" 2>/dev/null)"
    if [[ -z "$key" || "$key" == "null" ]]; then
        kind="applicationsets"
        key="$(yq e '.applicationsets | keys | .[0]' "$app_file")"
    fi

    if [[ "$kind" == "applications" ]]; then
        path=".${kind}.[\"$key\"]"
        yq e "${path}.sources[0].helm.releaseName // \"$key\"" "$app_file"
        yq e "${path}.sources[0].targetRevision" "$app_file"
        yq e "${path}.destination.namespace" "$app_file"
        yq e "(${path}.sources[0].helm.valueFiles // [])[]" "$app_file" | sed 's|^\$values/||' | tr '\n' ' '
        echo ""
    else
        # applicationsets: pull from the template + first generator element
        path=".${kind}.[\"$key\"]"
        yq e "${path}.generators[0].list.elements[0].releaseName // \"$key\"" "$app_file"
        yq e "${path}.generators[0].list.elements[0].chartVersion" "$app_file"
        yq e "${path}.generators[0].list.elements[0].namespace" "$app_file"
        yq e "(${path}.template.spec.sources[0].helm.valueFiles // [])[]" "$app_file" \
            | sed 's|^\$values/||' \
            | sed "s|{{infraValues}}|$(yq e "${path}.generators[0].list.elements[0].infraValues" "$app_file")|" \
            | tr '\n' ' '
        echo ""
    fi
}

confirm() {
    local prompt="$1" answer
    read -r -p "${prompt} [y/N/skip] " answer
    case "$answer" in
    y | Y | yes) return 0 ;;
    skip | s) return 1 ;;
    *) echo "Aborted."; exit 0 ;;
    esac
}

echo "Cluster: $(kubectl config current-context)"

# ---------------------------------------------------------------------------
# 1. AWS Load Balancer Controller
# ---------------------------------------------------------------------------
if confirm "Install AWS Load Balancer Controller?"; then
    { read -r alb_release; read -r alb_version; read -r alb_namespace; read -r alb_value_files; } \
        < <(get_app_values "$ALB_APP_FILE")
    helm repo add eks https://aws.github.io/eks-charts >/dev/null 2>&1 || true
    helm repo update eks >/dev/null
    # shellcheck disable=SC2086
    helm upgrade --install "$alb_release" eks/aws-load-balancer-controller \
        --version "$alb_version" --namespace "$alb_namespace" --create-namespace --wait \
        $(for f in $alb_value_files; do echo -n "-f $f "; done)
    echo "✓ ALB controller installed"
fi

# ---------------------------------------------------------------------------
# 2. ArgoCD
# ---------------------------------------------------------------------------
if confirm "Install ArgoCD?"; then
    { read -r argocd_release; read -r argocd_version; read -r argocd_namespace; read -r argocd_value_files; } \
        < <(get_app_values "$ARGOCD_APP_FILE")
    helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
    helm repo update argo >/dev/null
    # shellcheck disable=SC2086
    helm upgrade --install "$argocd_release" argo/argo-cd \
        --version "$argocd_version" --namespace "$argocd_namespace" --create-namespace --wait \
        $(for f in $argocd_value_files; do echo -n "-f $f "; done)
    echo "✓ ArgoCD installed"
    echo "  Initial admin password:"
    echo "    kubectl -n ${argocd_namespace} get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
fi

# ---------------------------------------------------------------------------
# 3. Root app-of-apps
# ---------------------------------------------------------------------------
if confirm "Install the root app-of-apps (argocd-apps)?"; then
    { read -r apps_release; read -r apps_version; read -r apps_namespace; read -r apps_value_files; } \
        < <(get_app_values "$ARGOAPPS_APP_FILE")
    helm repo add argo https://argoproj.github.io/argo-helm >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    helm upgrade --install "$apps_release" argo/argocd-apps \
        --version "$apps_version" --namespace "$apps_namespace" --create-namespace --wait \
        $(for f in $apps_value_files; do echo -n "-f $f "; done)
    echo "✓ Root app-of-apps installed — ArgoCD now self-manages from git."
    echo "  If this repo is private, register credentials first:"
    echo "    argocd repo add __MERCHANT_REPO_URL__ --username <user> --password <token>"
fi

echo ""
echo "Next: sync applications in order (istio -> monitoring -> hyperswitch)."
echo "See SELF_HOST.md."
