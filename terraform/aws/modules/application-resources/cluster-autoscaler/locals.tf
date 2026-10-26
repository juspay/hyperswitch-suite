locals {
  name_prefix = "${var.environment}-${var.project_name}-cluster-autoscaler"

  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "cluster-autoscaler"
      "ManagedBy"   = "terraform"
    },
    var.common_tags
  )

  role_name = coalesce(var.role_name, "${local.name_prefix}")

  # Service account the IRSA trust policy is scoped to. The Kubernetes side of
  # this (ServiceAccount, RBAC, Deployment) is managed by ArgoCD via the
  # upstream cluster-autoscaler Helm chart.
  service_account_subject = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}
