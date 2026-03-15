# =============================================================================
# EKS Kubernetes Resources Module
# =============================================================================
# This module manages Kubernetes resources that require an operational EKS cluster.
# To prevent provider initialization failures, this module must be applied separately
# from the EKS cluster infrastructure, as the Kubernetes provider requires valid
# cluster endpoints and authentication credentials before it can plan resources.
#
# Usage:
#   1. Create EKS cluster using the eks composition module
#   2. Pass cluster endpoint, CA data, and OIDC info to this module
#   3. This module creates RBAC, storage classes, and other K8s resources
# =============================================================================

# -----------------------------------------------------------------------------
# Terraform Configuration
# -----------------------------------------------------------------------------
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}

# -----------------------------------------------------------------------------
# Data source for Kubernetes authentication
# -----------------------------------------------------------------------------
data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# -----------------------------------------------------------------------------
# Terraform data for cluster readiness verification
# This ensures the cluster is accessible before creating K8s resources
# -----------------------------------------------------------------------------
resource "terraform_data" "cluster_ready" {
  triggers_replace = [
    var.cluster_id,
    var.cluster_endpoint,
    var.cluster_certificate_authority_data
  ]

  lifecycle {
    precondition {
      condition     = var.cluster_endpoint != null && var.cluster_endpoint != ""
      error_message = "Cluster endpoint must be provided and non-empty. The EKS cluster must exist before creating Kubernetes resources."
    }
    precondition {
      condition     = var.cluster_certificate_authority_data != null && var.cluster_certificate_authority_data != ""
      error_message = "Cluster certificate authority data must be provided. The EKS cluster must exist before creating Kubernetes resources."
    }
  }
}

# -----------------------------------------------------------------------------
# Kubernetes Provider Configuration
# -----------------------------------------------------------------------------
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# -----------------------------------------------------------------------------
# Helm Provider Configuration
# -----------------------------------------------------------------------------
provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# =============================================================================
# RBAC Resources
# =============================================================================

# -----------------------------------------------------------------------------
# ClusterRole: Developer
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "developer" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "cluster-developer"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "pods/exec", "pods/portforward", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["extensions"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# ClusterRole: ReadOnly
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "readonly" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "cluster-readonly"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses", "networkpolicies"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]
    verbs      = ["get", "list", "watch"]
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# ClusterRole: CI/CD
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "cicd" {
  count = var.create_default_rbac_roles ? 1 : 0

  metadata {
    name = "cluster-cicd"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log", "services", "endpoints", "persistentvolumeclaims", "configmaps", "secrets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "daemonsets", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources  = ["jobs", "cronjobs"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["ingresses"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["get", "list", "watch", "create"]
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# Custom RBAC Roles
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "custom_roles" {
  for_each = var.custom_rbac_roles

  metadata {
    name = "cluster-${each.key}"
  }

  dynamic "rule" {
    for_each = each.value.rules
    content {
      api_groups     = rule.value.api_groups
      resources      = rule.value.resources
      verbs          = rule.value.verbs
      resource_names = try(rule.value.resource_names, [])
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

# =============================================================================
# Storage Class Resources
# =============================================================================

# -----------------------------------------------------------------------------
# Default StorageClass for EBS volumes
# -----------------------------------------------------------------------------
resource "kubernetes_storage_class_v1" "ebs_gp3" {
  count = var.create_default_storage_class ? 1 : 0

  metadata {
    name = var.default_storage_class_name
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = true

  parameters = {
    type      = "gp3"
    encrypted = "true"
    fsType    = "ext4"
  }

  depends_on = [terraform_data.cluster_ready]
}

# =============================================================================
# Cluster Autoscaler ECR Resources (Optional)
# =============================================================================

# -----------------------------------------------------------------------------
# Local values for cluster autoscaler image
# -----------------------------------------------------------------------------
locals {
  # Determine cluster autoscaler image version
  cluster_autoscaler_version = coalesce(
    var.cluster_autoscaler_image_version,
    var.cluster_autoscaler_cluster_version != null ? "v${var.cluster_autoscaler_cluster_version}.0" : null,
    "v1.30.0"  # Default fallback
  )

  # Source image from public registry
  cluster_autoscaler_source_image = "${var.cluster_autoscaler_source_registry}/autoscaling/cluster-autoscaler:${local.cluster_autoscaler_version}"

  # Target ECR repository name (used only if creating new ECR)
  cluster_autoscaler_ecr_repo = coalesce(
    var.cluster_autoscaler_ecr_repo_name,
    "${var.environment}-${var.project_name}-cluster-autoscaler"
  )

  # Determine if we should create ECR repository
  # Don't create if: existing ECR URL provided OR not using ECR
  create_cluster_autoscaler_ecr = var.enable_cluster_autoscaler && var.cluster_autoscaler_use_ecr && var.cluster_autoscaler_ecr_repository_url == null

  # Final image URL:
  # 1. Use explicit image if provided
  # 2. Use existing ECR URL if provided (with version tag appended)
  # 3. Use created ECR if cluster_autoscaler_use_ecr = true
  # 4. Use public registry otherwise
  cluster_autoscaler_final_image = coalesce(
    var.cluster_autoscaler_image,
    var.cluster_autoscaler_ecr_repository_url != null ? "${var.cluster_autoscaler_ecr_repository_url}:${local.cluster_autoscaler_version}" : null,
    local.create_cluster_autoscaler_ecr ? "${aws_ecr_repository.cluster_autoscaler[0].repository_url}:${local.cluster_autoscaler_version}" : null,
    local.cluster_autoscaler_source_image
  )

  # Determine if we should sync image to ECR
  # Sync if: ECR enabled AND image sync enabled (works with both new and existing ECR repos)
  should_sync_cluster_autoscaler_image = var.enable_cluster_autoscaler && var.cluster_autoscaler_use_ecr && var.cluster_autoscaler_enable_image_sync

  # Target ECR URL for image sync (use provided URL or newly created repo)
  cluster_autoscaler_ecr_target_url = var.cluster_autoscaler_ecr_repository_url != null ? var.cluster_autoscaler_ecr_repository_url : (local.create_cluster_autoscaler_ecr ? aws_ecr_repository.cluster_autoscaler[0].repository_url : null)

  # Multi-arch source images for each architecture
  # Format: registry/autoscaling/cluster-autoscaler-<arch>:version
  cluster_autoscaler_multiarch_images = [
    for arch in var.cluster_autoscaler_architectures :
    "${var.cluster_autoscaler_source_registry}/autoscaling/cluster-autoscaler-${arch}:${local.cluster_autoscaler_version}"
  ]

  # AWS region for ECR operations
  ecr_region = coalesce(var.region, "eu-central-1")
}

# =============================================================================
# Cluster Autoscaler IRSA (IAM Role for Service Accounts)
# =============================================================================

module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.44.0"

  count = var.enable_cluster_autoscaler ? 1 : 0

  role_name = "${var.environment}-${var.project_name}-cluster-autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [var.cluster_name]

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler"]
    }
  }

  tags = var.tags
}


# =============================================================================
# ECR Repository (Optional - for private VPCs without internet access)
# =============================================================================

# -----------------------------------------------------------------------------
# ECR Repository for Cluster Autoscaler
# -----------------------------------------------------------------------------
resource "aws_ecr_repository" "cluster_autoscaler" {
  count = local.create_cluster_autoscaler_ecr ? 1 : 0

  name                 = local.cluster_autoscaler_ecr_repo
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(var.tags, {
    Name      = local.cluster_autoscaler_ecr_repo
    Component = "cluster-autoscaler"
    ManagedBy = "terraform"
  })
}

# -----------------------------------------------------------------------------
# ECR Lifecycle Policy - Keep only recent images
# -----------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "cluster_autoscaler" {
  count = local.create_cluster_autoscaler_ecr ? 1 : 0

  repository = aws_ecr_repository.cluster_autoscaler[0].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last ${var.cluster_autoscaler_ecr_max_images} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.cluster_autoscaler_ecr_max_images
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Image Sync: Pull from public registry and push to ECR
# Supports multi-arch images (amd64, arm64) using docker manifest
#
# PREREQUISITES:
#   - Docker must be installed and running
#   - docker manifest command (built into Docker, no separate install needed)
#
# Runs during terraform apply from a machine with internet access
# Fails silently to not block deployment
# -----------------------------------------------------------------------------
resource "terraform_data" "sync_cluster_autoscaler_image" {
  count = local.should_sync_cluster_autoscaler_image ? 1 : 0

  triggers_replace = [
    local.cluster_autoscaler_version,
    local.cluster_autoscaler_ecr_target_url,
    join(",", var.cluster_autoscaler_architectures)
  ]

  provisioner "local-exec" {
    # Fail silently - don't block deployment if sync fails
    on_failure = continue

    command = <<-EOT
      set +e  # Don't exit on error
      
      ECR_URL="${local.cluster_autoscaler_ecr_target_url}"
      VERSION="${local.cluster_autoscaler_version}"
      ARCHS="${join(",", var.cluster_autoscaler_architectures)}"
      REGION="${local.ecr_region}"
      
      echo "=============================================="
      echo "Cluster Autoscaler Image Sync"
      echo "=============================================="
      echo "ECR URL: $ECR_URL"
      echo "Version: $VERSION"
      echo "Architectures: $ARCHS"
      echo "=============================================="
      
      # =========================================
      # Prerequisite Check: Docker must be installed
      # =========================================
      if ! command -v docker &> /dev/null; then
        echo ""
        echo "ERROR: Docker is not installed!"
        echo "=============================================="
        echo "Docker is required to sync images to ECR."
        echo "Please install Docker before running terraform apply."
        echo ""
        echo "Installation guides:"
        echo "  - macOS:   https://docs.docker.com/desktop/install/mac-install/"
        echo "  - Linux:   https://docs.docker.com/engine/install/"
        echo "  - Windows: https://docs.docker.com/desktop/install/windows-install/"
        echo "=============================================="
        echo "SYNC_STATUS=DOCKER_NOT_INSTALLED"
        exit 0
      fi
      
      echo "Docker found: $(docker --version)"
      
      # =========================================
      # Get ECR login
      # =========================================
      echo "Logging in to ECR..."
      aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL
      LOGIN_STATUS=$?
      if [ $LOGIN_STATUS -ne 0 ]; then
        echo "=============================================="
        echo "WARNING: ECR login failed - skipping image sync"
        echo "SYNC_STATUS=LOGIN_FAILED"
        echo "=============================================="
        exit 0
      fi
      echo "ECR login successful"
      
      # =========================================
      # Multi-arch image sync using docker manifest
      # docker manifest is built into Docker (no buildx needed)
      # =========================================
      SYNC_SUCCESS=false
      SYNC_ERRORS=0
      
      echo "Syncing images for architectures: $ARCHS"
      
      # Pull and push each architecture image
      for arch in $(echo $ARCHS | tr "," " "); do
        SOURCE_IMG="${var.cluster_autoscaler_source_registry}/autoscaling/cluster-autoscaler-$arch:$VERSION"
        TARGET_IMG="$ECR_URL:$VERSION-$arch"
        
        echo ""
        echo "Syncing $arch:"
        echo "  Source: $SOURCE_IMG"
        echo "  Target: $TARGET_IMG"
        
        # Pull the architecture-specific image
        docker pull $SOURCE_IMG
        if [ $? -ne 0 ]; then
          echo "  WARNING: Failed to pull $SOURCE_IMG"
          SYNC_ERRORS=$((SYNC_ERRORS + 1))
          continue
        fi
        
        # Tag for ECR
        docker tag $SOURCE_IMG $TARGET_IMG
        if [ $? -ne 0 ]; then
          echo "  WARNING: Failed to tag image"
          SYNC_ERRORS=$((SYNC_ERRORS + 1))
          continue
        fi
        
        # Push to ECR
        docker push $TARGET_IMG
        if [ $? -ne 0 ]; then
          echo "  WARNING: Failed to push $TARGET_IMG"
          SYNC_ERRORS=$((SYNC_ERRORS + 1))
          continue
        fi
        
        echo "  SUCCESS: Synced $arch"
      done
      
      # =========================================
      # Create multi-arch manifest (if all archs synced)
      # =========================================
      if [ $SYNC_ERRORS -eq 0 ]; then
        # Build manifest list
        MANIFEST_IMAGES=""
        for arch in $(echo $ARCHS | tr "," " "); do
          MANIFEST_IMAGES="$MANIFEST_IMAGES $ECR_URL:$VERSION-$arch"
        done
        
        echo ""
        echo "Creating multi-arch manifest: $ECR_URL:$VERSION"
        docker manifest create --amend $ECR_URL:$VERSION $MANIFEST_IMAGES
        if [ $? -eq 0 ]; then
          docker manifest push $ECR_URL:$VERSION
          if [ $? -eq 0 ]; then
            SYNC_SUCCESS=true
            echo ""
            echo "=============================================="
            echo "SUCCESS: Multi-arch image synced!"
            echo "  Image: $ECR_URL:$VERSION"
            echo "  Architectures: $ARCHS"
            echo "SYNC_STATUS=SUCCESS"
            echo "=============================================="
          else
            echo "WARNING: Failed to push manifest"
          fi
        else
          echo "WARNING: Failed to create manifest"
        fi
      else
        echo ""
        echo "WARNING: $SYNC_ERRORS architecture(s) failed to sync"
      fi
      
      # =========================================
      # Fallback: Single-arch sync (if multi-arch failed)
      # =========================================
      if [ "$SYNC_SUCCESS" = "false" ]; then
        echo ""
        echo "Falling back to single-arch sync..."
        
        DEFAULT_ARCH=$(echo $ARCHS | cut -d',' -f1)
        SOURCE_IMG="${var.cluster_autoscaler_source_registry}/autoscaling/cluster-autoscaler-$DEFAULT_ARCH:$VERSION"
        
        echo "Syncing single-arch: $SOURCE_IMG -> $ECR_URL:$VERSION"
        docker pull $SOURCE_IMG
        if [ $? -eq 0 ]; then
          docker tag $SOURCE_IMG $ECR_URL:$VERSION
          docker push $ECR_URL:$VERSION
          if [ $? -eq 0 ]; then
            echo ""
            echo "=============================================="
            echo "SUCCESS: Single-arch image synced"
            echo "  Image: $ECR_URL:$VERSION"
            echo "  Architecture: $DEFAULT_ARCH"
            echo "SYNC_STATUS=SUCCESS_SINGLE_ARCH"
            echo "=============================================="
            SYNC_SUCCESS=true
          fi
        fi
      fi
      
      # =========================================
      # Final status
      # =========================================
      if [ "$SYNC_SUCCESS" = "false" ]; then
        echo ""
        echo "=============================================="
        echo "WARNING: Image sync failed"
        echo "=============================================="
        echo "The deployment will continue, but cluster-autoscaler"
        echo "may fail to start if the image is not available."
        echo ""
        echo "Options:"
        echo "  1. Ensure Docker is installed and running"
        echo "  2. Manually sync the image to ECR"
        echo "  3. Use an existing ECR repo via cluster_autoscaler_ecr_repository_url"
        echo "=============================================="
        echo "SYNC_STATUS=FAILED"
      fi
    EOT
  }

  depends_on = [
    aws_ecr_repository.cluster_autoscaler,
    aws_ecr_lifecycle_policy.cluster_autoscaler
  ]
}


# =============================================================================
# Cluster Autoscaler Kubernetes Resources
# =============================================================================

# -----------------------------------------------------------------------------
# ServiceAccount for Cluster Autoscaler with IRSA
# -----------------------------------------------------------------------------
resource "kubernetes_service_account_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = coalesce(var.cluster_autoscaler_service_account_name, "${var.environment}-${var.project_name}-cluster-autoscaler")
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
    annotations = {
      "eks.amazonaws.com/role-arn" = module.cluster_autoscaler_irsa[0].iam_role_arn
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# ClusterRole for Cluster Autoscaler
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["events", "endpoints"]
    verbs      = ["create", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods/eviction", "pods/status"]
    verbs      = ["update"]
  }

  rule {
    api_groups = [""]
    resources  = ["endpoints"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch", "update", "patch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps", "extensions"]
    resources  = ["daemonsets", "replicasets", "statefulsets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["create"]
  }

  rule {
    api_groups     = ["coordination.k8s.io"]
    resources      = ["leases"]
    verbs          = ["get", "update"]
    resource_names = ["cluster-autoscaler"]
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# ClusterRoleBinding for Cluster Autoscaler
# -----------------------------------------------------------------------------
resource "kubernetes_cluster_role_binding_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name = "cluster-autoscaler"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.cluster_autoscaler[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_cluster_role_v1.cluster_autoscaler
  ]
}

# -----------------------------------------------------------------------------
# Role for kube-system namespace (Cluster Autoscaler)
# -----------------------------------------------------------------------------
resource "kubernetes_role_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["create", "list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    verbs          = ["get", "update"]
    resource_names = ["cluster-autoscaler-status"]
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# RoleBinding for kube-system namespace (Cluster Autoscaler)
# -----------------------------------------------------------------------------
resource "kubernetes_role_binding_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "k8s-addon" = "cluster-autoscaler.addons.k8s.io"
      "app"       = "cluster-autoscaler"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.cluster_autoscaler[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_role_v1.cluster_autoscaler
  ]
}

# -----------------------------------------------------------------------------
# Cluster Autoscaler Deployment
# -----------------------------------------------------------------------------
locals {
  # Build command for cluster autoscaler
  cluster_autoscaler_command = var.cluster_autoscaler_command != null ? var.cluster_autoscaler_command : concat(
    [
      "./cluster-autoscaler",
      "--v=${var.cluster_autoscaler_log_level}",
      "--stderrthreshold=info",
      "--cloud-provider=aws",
      "--skip-nodes-with-local-storage=${var.cluster_autoscaler_skip_local_storage}",
      "--expander=${var.cluster_autoscaler_expander}",
      "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${var.cluster_name}",
      "--balance-similar-node-groups",
      "--skip-nodes-with-system-pods=${var.cluster_autoscaler_skip_system_pods}"
    ],
    var.cluster_autoscaler_extra_args,
    var.cluster_autoscaler_command_extra_args
  )
}

resource "kubernetes_deployment_v1" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  metadata {
    name      = "cluster-autoscaler"
    namespace = "kube-system"
    labels = {
      "app" = "cluster-autoscaler"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        "app" = "cluster-autoscaler"
      }
    }

    template {
      metadata {
        labels = {
          "app" = "cluster-autoscaler"
        }
        annotations = merge(
          {
            "prometheus.io/scrape" = "true"
            "prometheus.io/port"   = "8085"
          },
          var.cluster_autoscaler_pod_annotations
        )
      }

      spec {
        service_account_name = kubernetes_service_account_v1.cluster_autoscaler[0].metadata[0].name

        container {
          name  = "cluster-autoscaler"
          image = local.cluster_autoscaler_final_image

          command = concat(
            ["./cluster-autoscaler"],
            [
              "--v=${var.cluster_autoscaler_log_level}",
              "--stderrthreshold=info",
              "--cloud-provider=aws",
              "--skip-nodes-with-local-storage=false",
              "--expander=${var.cluster_autoscaler_expander}",
              "--leader-elect=false"
            ],
            var.cluster_autoscaler_extra_args
          )

          resources {
            requests = {
              cpu    = coalesce(var.cluster_autoscaler_resources.requests_cpu, "100m")
              memory = coalesce(var.cluster_autoscaler_resources.requests_memory, "600Mi")
            }
            limits = {
              cpu    = coalesce(var.cluster_autoscaler_resources.limits_cpu, "100m")
              memory = coalesce(var.cluster_autoscaler_resources.limits_memory, "600Mi")
            }
          }

          liveness_probe {
            http_get {
              path = "/health-check"
              port = 8085
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health-check"
              port = 8085
            }
            initial_delay_seconds = 15
            period_seconds        = 10
          }
        }

        dynamic "toleration" {
          for_each = var.cluster_autoscaler_tolerations
          content {
            key      = toleration.value.key
            operator = toleration.value.operator
            value    = try(toleration.value.value, null)
            effect   = toleration.value.effect
          }
        }

        node_selector = var.cluster_autoscaler_node_selector
      }
    }
  }

  depends_on = [
    kubernetes_service_account_v1.cluster_autoscaler,
    kubernetes_cluster_role_binding_v1.cluster_autoscaler,
    kubernetes_role_binding_v1.cluster_autoscaler
  ]
}

# =============================================================================
# Kubernetes Namespace Resources
# =============================================================================

# -----------------------------------------------------------------------------
# Kubernetes Namespaces
# -----------------------------------------------------------------------------
resource "kubernetes_namespace_v1" "hyperswitch" {
  count = var.enable_helm_deployments ? 1 : 0

  metadata {
    name = var.hyperswitch_namespace

    labels = {
      name        = var.hyperswitch_namespace
      environment = var.environment
    }
  }

  depends_on = [terraform_data.cluster_ready]
}

# -----------------------------------------------------------------------------
# ECR Registry Secret for pulling images
# -----------------------------------------------------------------------------
data "aws_ecr_authorization_token" "token" {
  count = var.enable_helm_deployments && var.create_ecr_registry_secret ? 1 : 0
}

resource "kubernetes_secret_v1" "ecr_registry" {
  count = var.enable_helm_deployments && var.create_ecr_registry_secret ? 1 : 0

  metadata {
    name      = "ecr-registry-secret"
    namespace = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${data.aws_ecr_authorization_token.token[0].proxy_endpoint}" = {
          auth = data.aws_ecr_authorization_token.token[0].authorization_token
        }
      }
    })
  }

  depends_on = [kubernetes_namespace_v1.hyperswitch]
}

# -----------------------------------------------------------------------------
# Hyperswitch Helm Release
# -----------------------------------------------------------------------------
resource "helm_release" "hyperswitch_stack" {
  count = var.enable_helm_deployments ? 1 : 0

  name       = var.hyperswitch_release_name
  repository = var.hyperswitch_helm_repository
  chart      = var.hyperswitch_helm_chart
  namespace  = kubernetes_namespace_v1.hyperswitch[0].metadata[0].name
  version    = var.hyperswitch_chart_version

  values = var.hyperswitch_values_file != null ? [
    file(var.hyperswitch_values_file)
  ] : []

  wait          = true
  wait_for_jobs = true
  timeout       = var.hyperswitch_helm_timeout

  depends_on = [
    terraform_data.cluster_ready,
    kubernetes_namespace_v1.hyperswitch,
    kubernetes_secret_v1.ecr_registry,
    kubernetes_storage_class_v1.ebs_gp3
  ]
}
