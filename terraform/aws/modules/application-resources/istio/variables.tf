# ============================================================================
# Environment & Project Configuration
# ============================================================================
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

variable "vpc_id" {
  description = "VPC ID where the security group will be created"
  type        = string
}

variable "lb_subnet_ids" {
  description = "Subnet IDs to use for Istio Gateway Load Balancer"
  type = list(string)
  default = []
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "create_lb_security_group" {
  description = "This creates a security group to attach to load-balancer through annotations"
  type = bool
  default = true
}

variable "lb_security_groups" {
  description = "Existing security group to attach to load-balancer"
  type        = list(string)
  default     = []
}

variable "istio_namespace" {
  description = "Namespace to install Istio components"
  type        = string
  default     = "istio-system"
}

variable "create_helm_releases" {
  description = "Whether to create the Helm releases for Istio components"
  type        = bool
  default     = true
}

variable "istio_base" {
  description = "Configurations for Istio Base Chart"
  type = object({
    enabled = bool
    release_name = optional(string)
    chart_repo = optional(string)
    chart_version = optional(string)
    values = optional(list(string), [])
    values_file = optional(string, "")
  })

  default = {
    enabled = true
  }
}

variable "istiod" {
  description = "Configurations for Istiod Chart"
  type = object({
    enabled = bool
    release_name = optional(string)
    chart_repo = optional(string)
    chart_version = optional(string)
    values = optional(list(string), [])
    values_file = optional(string, "")
  })

  default = {
    enabled = true
  }
}

variable "istio_gateway" {
  description = "Configurations for Istio Gateway Chart"
  type = object({
    enabled = bool
    release_name = optional(string)
    chart_repo = optional(string)
    chart_version = optional(string)
    values = optional(list(string), [])
    values_file = optional(string, "")
  })

  default = {
    enabled = true
  }
}

variable "ingress_annotations" {
  description = "Additional annotations to be added to ingress resources"
  type = map(string)
  default = {}
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
