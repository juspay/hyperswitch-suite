# =============================================================================
# EKS Kubernetes Resources - Terragrunt Configuration
# =============================================================================
# This module creates Kubernetes resources that depend on an existing EKS cluster.
# It MUST be applied AFTER the eks-management-01 module completes.
# =============================================================================

# -----------------------------------------------------------------------------
# Include Root Configuration
# -----------------------------------------------------------------------------
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

# -----------------------------------------------------------------------------
# Terragrunt Configuration
# -----------------------------------------------------------------------------
terraform {
  source = "git::https://github.com/juspay/hyperswitch-suite.git//terraform/aws/modules/composition/eks-kubernetes-resources?ref=eks-k8s-v0.1.3"
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------
dependency "eks_cluster" {
  config_path = "../eks-01"

  mock_outputs = {
    cluster_certificate_authority_data = "mock-cluster_certificate_authority_data"
    cluster_endpoint                   = "mock-cluster_endpoint"
    cluster_name                       = "mock-cluster"
    oidc_provider_arn                  = "arn:aws:mock:::123456789012:mock/mock"
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

dependency "efs" {
  config_path = "../../efs"

  mock_outputs = {
    file_system_ids = {
      "superposition-backup" = "mock-file_system_ids-superposition-backup"
    }
  }
  mock_outputs_merge_strategy_with_state = "shallow"
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------
inputs = {
  # ===========================================================================
  # REQUIRED: Cluster Information (from EKS module)
  # ===========================================================================
  cluster_name                       = dependency.eks_cluster.outputs.cluster_name
  cluster_id                         = dependency.eks_cluster.outputs.cluster_name
  cluster_endpoint                   = dependency.eks_cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks_cluster.outputs.cluster_certificate_authority_data
  oidc_provider_arn                  = dependency.eks_cluster.outputs.oidc_provider_arn
  # ===========================================================================
  # ENVIRONMENT
  # ===========================================================================
  project_name = include.root.locals.project_name
  environment  = include.root.locals.environment.short
  region       = include.root.locals.region

  tags = {
    Environment = include.root.locals.environment.short
    Project     = include.root.locals.project_name
    ManagedBy   = "terragrunt"
  }

  # ===========================================================================
  # RBAC CONFIGURATION
  # ===========================================================================
  # Set to false if you want to manage RBAC roles separately
  create_default_rbac_roles = false

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

  # ===========================================================================
  # STORAGE CLASS CONFIGURATION
  # ===========================================================================
  create_default_storage_class = true
  default_storage_class_name   = "ebs-gp3"

  custom_storage_classes = {
    efs-sc = {
      storage_provisioner = "efs.csi.aws.com"
      volume_binding_mode = "Immediate"
      reclaim_policy      = "Retain"
      parameters = {
        provisioningMode = "efs-ap"
        fileSystemId     = dependency.efs.outputs.file_system_ids["superposition-backup"]
        basePath         = "/superposition/backup-config"
        directoryPerms   = "700"
      }
    }
  }

  # ===========================================================================
  # CLUSTER AUTOSCALER CONFIGURATION
  # ===========================================================================
  # Enable to allow automatic node scaling based on pod resource requests
  enable_cluster_autoscaler = true

  # Use default image from public registry (or specify ECR image)
  cluster_autoscaler_image = null

  # Service account name
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

  # ===========================================================================
  # CLUSTER AUTOSCALER ECR CONFIGURATION (Optional)
  # Use this for private VPCs without internet access
  # ===========================================================================
  # Or specify exact image version
  cluster_autoscaler_image_version = "v1.35.0"

  # Source registry for cluster autoscaler images
  cluster_autoscaler_source_registry = "registry.k8s.io"

  # CPU architectures for multi-arch image sync
  cluster_autoscaler_architectures = ["amd64", "arm64"]

  # Set to true to use ECR instead of the public registry
  # Required for private VPCs without internet access
  # (supply cluster_autoscaler_ecr_account via stack values to enable)
  cluster_autoscaler_use_ecr = try(values.cluster_autoscaler_use_ecr, false)

  #   # Custom ECR repository name (auto-generated if null)
  #   cluster_autoscaler_ecr_repo_name = null

  #   # Max images to keep in ECR (lifecycle policy)
  #   cluster_autoscaler_ecr_max_images = 5

  # Use existing ECR repository URL (will sync image to this repo if image_sync is enabled)
  cluster_autoscaler_ecr_repository_url = try(values.cluster_autoscaler_ecr_account, null) != null ? "${values.cluster_autoscaler_ecr_account}.dkr.ecr.${include.root.locals.region}.amazonaws.com/cluster-autoscaler" : null

  # Enable automatic image sync from public registry to ECR
  cluster_autoscaler_enable_image_sync = false


  # ===========================================================================
  # HELM DEPLOYMENT CONFIGURATION
  # ===========================================================================
  # Set to false if using ArgoCD or Flux for deployments
  enable_helm_deployments = false

  # Create ECR registry secret for pulling private images
  create_ecr_registry_secret = try(values.create_ecr_registry_secret, true)

  # ===========================================================================
  # HYPERSWITCH HELM CONFIGURATION
  # Only used when enable_helm_deployments = true
  # ===========================================================================
  hyperswitch_namespace       = "hyperswitch"
  hyperswitch_release_name    = "hyperswitch-stack"
  hyperswitch_helm_repository = "https://juspay.github.io/hyperswitch-helm"
  hyperswitch_helm_chart      = "hyperswitch-stack"
  hyperswitch_chart_version   = null # null = latest
  hyperswitch_values_file     = null # Path to custom values.yaml
  hyperswitch_helm_timeout    = 900  # 15 minutes
}
