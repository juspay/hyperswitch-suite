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
  type        = list(string)
  default     = []
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "create_lb_security_group" {
  description = "This creates a security group to attach to load-balancer through annotations"
  type        = bool
  default     = true
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
    enabled       = bool
    release_name  = optional(string)
    chart_repo    = optional(string)
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })

  default = {
    enabled = true
  }
}

variable "istiod" {
  description = "Configurations for Istiod Chart"
  type = object({
    enabled       = bool
    release_name  = optional(string)
    chart_repo    = optional(string)
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })

  default = {
    enabled = true
  }
}

variable "istio_gateway" {
  description = "Configurations for Istio Gateway Chart"
  type = object({
    enabled       = bool
    release_name  = optional(string)
    chart_repo    = optional(string)
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })

  default = {
    enabled = true
  }
}

variable "ingress_annotations" {
  description = "Additional annotations to be added to ingress resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Application Load Balancer (ALB) Configuration
# ============================================================================
variable "alb" {
  description = "Configuration for optional Application Load Balancer using terraform-aws-modules/alb/aws"
  type = object({
    enabled                             = optional(bool, false)
    name                                = optional(string, null)
    internal                            = optional(bool, false)
    enable_deletion_protection          = optional(bool, true)
    enable_http2                        = optional(bool, true)
    enable_waf_fail_open                = optional(bool, false)
    drop_invalid_header_fields          = optional(bool, true)
    idle_timeout                        = optional(number, 60)
    ip_address_type                     = optional(string, null)
    access_logs                         = optional(any, null)
    connection_logs                     = optional(any, null)
    health_check_logs                   = optional(any, null)
    listeners                           = optional(any, {})
    target_groups                       = optional(any, null)
    additional_target_group_attachments = optional(any, null)
    route53_records                     = optional(any, null)
    associate_web_acl                   = optional(bool, false)
    web_acl_arn                         = optional(string, null)
    desync_mitigation_mode              = optional(string, null)
    preserve_host_header                = optional(bool, null)
    xff_header_processing_mode          = optional(string, null)
    client_keep_alive                   = optional(number, null)
    tags                                = optional(map(string), {})
  })
  default = {
    enabled = false
  }
}

# ============================================================================
# Tags
# ============================================================================
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
