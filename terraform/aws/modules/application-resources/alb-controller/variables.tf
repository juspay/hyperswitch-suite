# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "alb_controller_namespace" {
  description = "Namespace ALB Controller is installed on"
  type        = string
  default     = "kube-system"
}

variable "alb_controller_service_account_name" {
  description = "Service Account Name of ALB Controller"
  type        = string
  default     = "aws-load-balancer-controller-sa"
}

variable "create_alb_controller_service_account" {
  description = "Whether to create the ALB Controller Service Account"
  type        = bool
  default     = false
}

variable "create_helm_release" {
  description = "Whether to create the Helm release for ALB Controller"
  type        = bool
  default     = true
}

variable "alb_controller_chart_version" {
  description = "Version of the AWS Load Balancer Controller Helm chart"
  type        = string
  default     = "1.14.0"
}

variable "helm_release_name" {
  description = "Name of the Helm release"
  type        = string
  default     = "aws-load-balancer-controller"
}

variable "helm_chart_repository" {
  description = "Helm chart repository URL"
  type        = string
  default     = "https://aws.github.io/eks-charts"
}

variable "helm_chart_values" {
  description = "Additional values to pass to the Helm chart"
  type        = list(string)
  default     = []
}

variable "helm_values_file" {
  description = "Path to a values.yaml file to use with the Helm chart. If provided, this will be used alongside helm_chart_values"
  type        = string
  default     = ""
}

variable "service_account_labels" {
  description = "Labels to apply to the ALB Controller Service Account"
  type        = map(string)
  default     = {}
}

variable "additional_service_account_annotations" {
  description = "Additional annotations to apply to the ALB Controller Service Account"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
