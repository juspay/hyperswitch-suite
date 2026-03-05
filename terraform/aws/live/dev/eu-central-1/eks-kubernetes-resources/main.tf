# =============================================================================
# EKS Kubernetes Resources Module - Wrapper
# =============================================================================
# This is a wrapper module that sources the implementation from the backup
# directory. This pattern allows for:
#   - Centralized implementation in one place
#   - Easy updates and maintenance
#   - Optional wrapper-specific customizations/defaults
#
# The actual implementation is in: backup/eks-kubernetes-resources/
# =============================================================================

# -----------------------------------------------------------------------------
# Source the implementation module
# -----------------------------------------------------------------------------
module "eks_kubernetes_resources" {
  source = "../../../../modules/composition/eks-kubernetes-resources"

  # Required Cluster Information
  cluster_name                       = var.cluster_name
  cluster_id                         = var.cluster_id
  cluster_endpoint                   = var.cluster_endpoint
  cluster_certificate_authority_data = var.cluster_certificate_authority_data
  oidc_provider_arn                  = var.oidc_provider_arn

  # Environment Configuration
  project_name = var.project_name
  environment  = var.environment
  tags         = var.tags

  # RBAC Configuration
  create_default_rbac_roles = var.create_default_rbac_roles
  custom_rbac_roles         = var.custom_rbac_roles

  # Storage Class Configuration
  create_default_storage_class = var.create_default_storage_class
  default_storage_class_name   = var.default_storage_class_name

  # Cluster Autoscaler Configuration
  enable_cluster_autoscaler               = var.enable_cluster_autoscaler
  cluster_autoscaler_image                = var.cluster_autoscaler_image
  cluster_autoscaler_service_account_name = var.cluster_autoscaler_service_account_name
  cluster_autoscaler_resources            = var.cluster_autoscaler_resources
  cluster_autoscaler_log_level            = var.cluster_autoscaler_log_level
  cluster_autoscaler_expander             = var.cluster_autoscaler_expander
  cluster_autoscaler_extra_args           = var.cluster_autoscaler_extra_args
  cluster_autoscaler_command              = var.cluster_autoscaler_command
  cluster_autoscaler_command_extra_args   = var.cluster_autoscaler_command_extra_args
  cluster_autoscaler_skip_local_storage   = var.cluster_autoscaler_skip_local_storage
  cluster_autoscaler_skip_system_pods     = var.cluster_autoscaler_skip_system_pods
  cluster_autoscaler_node_selector        = var.cluster_autoscaler_node_selector
  cluster_autoscaler_tolerations          = var.cluster_autoscaler_tolerations
  cluster_autoscaler_pod_annotations      = var.cluster_autoscaler_pod_annotations

  # Cluster Autoscaler ECR Configuration
  cluster_autoscaler_cluster_version    = var.cluster_autoscaler_cluster_version
  cluster_autoscaler_image_version      = var.cluster_autoscaler_image_version
  cluster_autoscaler_source_registry    = var.cluster_autoscaler_source_registry
  cluster_autoscaler_architectures      = var.cluster_autoscaler_architectures
  cluster_autoscaler_use_ecr            = var.cluster_autoscaler_use_ecr
  cluster_autoscaler_ecr_repo_name      = var.cluster_autoscaler_ecr_repo_name
  cluster_autoscaler_ecr_max_images     = var.cluster_autoscaler_ecr_max_images
  cluster_autoscaler_ecr_repository_url = var.cluster_autoscaler_ecr_repository_url
  cluster_autoscaler_enable_image_sync  = var.cluster_autoscaler_enable_image_sync
  region                                = var.region

  # Helm Deployment Configuration
  enable_helm_deployments    = var.enable_helm_deployments
  create_ecr_registry_secret = var.create_ecr_registry_secret

  # Hyperswitch Helm Configuration
  hyperswitch_namespace       = var.hyperswitch_namespace
  hyperswitch_release_name    = var.hyperswitch_release_name
  hyperswitch_helm_repository = var.hyperswitch_helm_repository
  hyperswitch_helm_chart      = var.hyperswitch_helm_chart
  hyperswitch_chart_version   = var.hyperswitch_chart_version
  hyperswitch_values_file     = var.hyperswitch_values_file
  hyperswitch_helm_timeout    = var.hyperswitch_helm_timeout
}
