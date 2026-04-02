variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name (defaults to {environment}-{project_name}-cluster)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones (defaults to first 2 AZs in region)"
  type        = list(string)
  default     = null
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.35"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  description = "List of EKS control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "Number of days to retain EKS cluster logs"
  type        = number
  default     = 30
}

variable "addon_versions" {
  description = "EKS addon versions"
  type = object({
    vpc_cni            = string
    coredns            = string
    kube_proxy         = string
    ebs_csi            = string
    pod_identity_agent = string
  })
  default = {
    vpc_cni            = "v1.19.0-eksbuild.1"
    coredns            = "v1.13.2-eksbuild.1"
    kube_proxy         = "v1.35.0-eksbuild.2"
    ebs_csi            = "v1.55.0-eksbuild.1"
    pod_identity_agent = "v1.3.2-eksbuild.1"
  }
}

variable "node_group" {
  description = "EKS node group configuration"
  type = object({
    capacity_type              = string
    instance_types             = list(string)
    desired_size               = number
    min_size                   = number
    max_size                   = number
    max_unavailable_percentage = number
    labels                     = map(string)
  })
  default = {
    capacity_type              = "ON_DEMAND"
    instance_types             = ["t3.medium"]
    desired_size               = 4
    min_size                   = 2
    max_size                   = 10
    max_unavailable_percentage = 33
    labels                     = {}
  }
}

variable "hyperswitch_namespace" {
  description = "Kubernetes namespace for Hyperswitch"
  type        = string
  default     = "hyperswitch"
}

variable "hyperswitch_release_name" {
  description = "Helm release name for Hyperswitch"
  type        = string
  default     = "hyperswitch"
}

variable "hyperswitch_helm_repo" {
  description = "Helm repository URL for Hyperswitch"
  type        = string
  default     = "https://juspay.github.io/hyperswitch-helm"
}

variable "hyperswitch_helm_chart" {
  description = "Helm chart name for Hyperswitch"
  type        = string
  default     = "hyperswitch-stack"
}

variable "hyperswitch_helm_version" {
  description = "Helm chart version for Hyperswitch"
  type        = string
  default     = null
}

variable "hyperswitch_install_timeout" {
  description = "Timeout in seconds for Helm install/upgrade"
  type        = number
  default     = 600
}

variable "hyperswitch_wait" {
  description = "Wait for Helm release to be ready"
  type        = bool
  default     = true
}

variable "hyperswitch_wait_for_jobs" {
  description = "Wait for Helm release jobs to complete"
  type        = bool
  default     = true
}

variable "hyperswitch_helm_values" {
  description = "Additional Helm values for Hyperswitch"
  type        = map(string)
  default     = {}
}
