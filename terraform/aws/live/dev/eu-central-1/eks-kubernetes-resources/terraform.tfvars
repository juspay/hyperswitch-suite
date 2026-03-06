# =============================================================================
# EKS Kubernetes Resources Module - Example tfvars
# =============================================================================
# This file shows all available variables with example values.
# Copy this file and customize for your environment.
# =============================================================================

# -----------------------------------------------------------------------------
# Required Cluster Information
# These MUST be provided from the EKS cluster module outputs
# -----------------------------------------------------------------------------
cluster_name                       = "dev-hyperswitch-cluster-01"
cluster_id                         = "dev-hyperswitch-cluster-01"
cluster_endpoint                   = "https://XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX.gr7.eu-central-1.eks.amazonaws.com"
cluster_certificate_authority_data = "..."
oidc_provider_arn                  = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# -----------------------------------------------------------------------------
# Environment Configuration
# -----------------------------------------------------------------------------
project_name = "hyperswitch"
environment  = "dev"
tags = {
  Project     = "hyperswitch"
  Environment = "dev"
  ManagedBy   = "terraform"
}

# -----------------------------------------------------------------------------
# RBAC Configuration
# -----------------------------------------------------------------------------
# Set to false if you want to manage RBAC roles separately
create_default_rbac_roles = true

# Example: Add custom RBAC roles
# custom_rbac_roles = {
#   monitoring = {
#     rules = [
#       {
#         api_groups = [""]
#         resources  = ["pods", "services", "endpoints"]
#         verbs      = ["get", "list", "watch"]
#       },
#       {
#         api_groups = ["apps"]
#         resources  = ["deployments", "replicasets"]
#         verbs      = ["get", "list", "watch"]
#       }
#     ]
#   }
# }
custom_rbac_roles = {}

# -----------------------------------------------------------------------------
# Storage Class Configuration
# -----------------------------------------------------------------------------
create_default_storage_class = true
default_storage_class_name   = "ebs-gp3"

# -----------------------------------------------------------------------------
# Cluster Autoscaler Configuration
# -----------------------------------------------------------------------------
# Enable to allow automatic node scaling based on pod resource requests
enable_cluster_autoscaler = true

# Use default image from public registry (or specify ECR image)
cluster_autoscaler_image = null

# Service account name (default: cluster-autoscaler)
cluster_autoscaler_service_account_name = null

# Resource limits for cluster autoscaler pod
cluster_autoscaler_resources = {
  requests_cpu    = "100m"
  requests_memory = "600Mi"
  limits_cpu      = "100m"
  limits_memory   = "600Mi"
}

# Log level: 1-5 (higher = more verbose)
cluster_autoscaler_log_level = 4

# Expander strategy: least-waste, most-pods, priority, random
cluster_autoscaler_expander = "least-waste"

# Additional command line arguments
# cluster_autoscaler_extra_args = [
#   "--scale-down-unneeded-time=10m",
#   "--scale-down-delay-after-add=10m"
# ]
cluster_autoscaler_extra_args = []

# Override entire command (rarely needed)
cluster_autoscaler_command = null

# Extra args appended to default command
cluster_autoscaler_command_extra_args = []

# Node scheduling options
cluster_autoscaler_skip_local_storage = false
cluster_autoscaler_skip_system_pods   = false
cluster_autoscaler_node_selector      = {}
cluster_autoscaler_tolerations        = []
cluster_autoscaler_pod_annotations    = {}

# -----------------------------------------------------------------------------
# Cluster Autoscaler ECR Configuration (Optional)
# Use this for private VPCs without internet access
# -----------------------------------------------------------------------------
# Kubernetes cluster version (used to determine autoscaler version)
cluster_autoscaler_cluster_version = "1.35.0"

# Or specify exact image version
cluster_autoscaler_image_version = "v1.35.0"

# Source registry for cluster autoscaler images
cluster_autoscaler_source_registry = "registry.k8s.io"

# CPU architectures for multi-arch image sync
cluster_autoscaler_architectures = ["amd64", "arm64"]

# Set to true to use ECR instead of public registry
# Required for private VPCs without internet access
cluster_autoscaler_use_ecr = true

# Custom ECR repository name (auto-generated if null)
cluster_autoscaler_ecr_repo_name  = "dev-hyperswitch-cluster-autoscaler"

# Max images to keep in ECR (lifecycle policy)
cluster_autoscaler_ecr_max_images = 5

# Use existing ECR repository URL (will sync image to this repo if image_sync is enabled)
cluster_autoscaler_ecr_repository_url = "XXXXXXXXXXXX.dkr.ecr.eu-central-1.amazonaws.com/dev-hyperswitch-cluster-autoscaler"

# Enable automatic image sync from public registry to ECR
cluster_autoscaler_enable_image_sync = true

# AWS region for ECR operations
region = "eu-central-1"

# -----------------------------------------------------------------------------
# Helm Deployment Configuration
# -----------------------------------------------------------------------------
# Set to false if using ArgoCD or Flux for deployments
enable_helm_deployments = false

# Create ECR registry secret for pulling private images
create_ecr_registry_secret = true

# -----------------------------------------------------------------------------
# Hyperswitch Helm Configuration
# Only used when enable_helm_deployments = true
# -----------------------------------------------------------------------------
hyperswitch_namespace       = "hyperswitch"
hyperswitch_release_name    = "hyperswitch-stack"
hyperswitch_helm_repository = "https://juspay.github.io/hyperswitch-helm"
hyperswitch_helm_chart      = "hyperswitch-stack"
hyperswitch_chart_version   = null # null = latest
hyperswitch_values_file     = null # Path to custom values.yaml
hyperswitch_helm_timeout    = 900  # 15 minutes
