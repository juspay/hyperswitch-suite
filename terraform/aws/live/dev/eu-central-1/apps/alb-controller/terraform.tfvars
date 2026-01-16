# ============================================================================
# Dev Environment - EU Central 1 - ALB Controller Configuration
# ============================================================================
# This file contains configuration values for the dev environment
# Modify values as needed for your deployment
# ============================================================================

# ============================================================================
# Environment & Project Configuration
# ============================================================================
environment  = "dev"
region       = "eu-central-1"
project_name = "hyperswitch"

# ============================================================================
# ALB Controller Configuration
# ============================================================================
# Namespace where ALB Controller will be installed
alb_controller_namespace = "kube-system"

# Service Account name for ALB Controller
alb_controller_service_account_name = "aws-load-balancer-controller-sa"

# Whether to create the service account
# (service account creation is independent of Helm release to enable role arn attachment)
create_alb_controller_service_account = true

# Optional: Additional labels for the service account
service_account_labels = {}

# Optional: Additional annotations for the service account
additional_service_account_annotations = {}

# Whether to deploy the Helm release (set to true for initial deployment)
create_helm_release = true

# Helm chart version
alb_controller_chart_version = "1.14.0"

# Helm release name
helm_release_name = "aws-load-balancer-controller"

# Optional: Additional Helm values
helm_chart_values = []

# Optional: Path to custom values.yaml file
helm_values_file = ""

# ============================================================================
# Tags
# ============================================================================
common_tags = {
  ManagedBy   = "terraform"
  Environment = "dev"
  Project     = "hyperswitch"
  Component   = "alb-controller"
}
