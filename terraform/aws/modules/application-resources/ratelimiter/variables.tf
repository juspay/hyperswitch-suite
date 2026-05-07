variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "ratelimiter"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# =========================================================================
# EKS OIDC Configuration
# =========================================================================

variable "cluster_service_accounts" {
  description = "Map of EKS cluster names to their respective list of Kubernetes service accounts (namespace and service account name)"
  type = map(list(object({
    namespace = string
    name      = string
  })))
  default = {}
}

variable "additional_assume_role_statements" {
  description = "Additional IAM assume role policy statements to append"
  type        = list(any)
  default     = []
}

# =========================================================================
# IAM Role Configuration
# =========================================================================

variable "role_name" {
  description = "Custom IAM role name. If null, auto-generated as {environment}-{project}-{app}-role"
  type        = string
  default     = null
}

variable "role_description" {
  description = "Custom IAM role description"
  type        = string
  default     = null
}

variable "role_path" {
  description = "IAM role path"
  type        = string
  default     = "/"
}

variable "max_session_duration" {
  description = "Maximum session duration for the role (in seconds)"
  type        = number
  default     = 3600
}

variable "force_detach_policies" {
  description = "Whether to force detaching policies when destroying the role"
  type        = bool
  default     = true
}

# =========================================================================
# Assume Role Principals
# =========================================================================

variable "assume_role_principals" {
  description = "List of AWS principal ARNs allowed to assume this role (e.g., ['arn:aws:iam::123456789012:root'])"
  type        = list(string)
  default     = []
}

# =========================================================================
# Policy Attachments
# =========================================================================

variable "aws_managed_policy_names" {
  description = "List of AWS managed policy names to attach"
  type        = list(string)
  default     = []
}

variable "customer_managed_policy_arns" {
  description = "List of customer managed policy ARNs to attach"
  type        = list(string)
  default     = []
}

# =========================================================================
# Inline Policies
# =========================================================================

variable "inline_policies" {
  description = "Map of inline policies for role-specific permissions"
  type        = map(string)
  default     = {}
}

# =========================================================================
# ElastiCache Configuration
# =========================================================================

variable "elasticache_config" {
  description = "ElastiCache configuration for rate limiter"
  type = object({
    enabled                          = optional(bool, true)
    elasticache_replication_group_id = optional(string, null)
    subnet_ids                       = optional(list(string), [])
    engine                           = optional(string, "valkey")
    engine_version                   = optional(string, "8.2")
    parameter_group_name             = optional(string, "default.valkey8")
    port                             = optional(number, 6379)
    node_type                        = optional(string, "cache.t3.small")
    num_cache_clusters               = optional(number, 2)
    num_node_groups                  = optional(number, null)
    replicas_per_node_group          = optional(number, null)
    cluster_mode                     = optional(string, "disabled")
    automatic_failover_enabled       = optional(bool, true)
    multi_az_enabled                 = optional(bool, true)
    at_rest_encryption_enabled       = optional(bool, true)
    transit_encryption_enabled       = optional(bool, false)
    auth_token                       = optional(string, null)
    create_subnet_group              = optional(bool, true)
    subnet_group_name                = optional(string, null)
    create_security_group            = optional(bool, true)
    existing_security_group_ids      = optional(list(string), [])
    maintenance_window               = optional(string, "sun:05:00-sun:06:00")
    snapshot_window                  = optional(string, "03:00-05:00")
    snapshot_retention_limit         = optional(number, 1)
    apply_immediately                = optional(bool, false)
  })
  default = {
    enabled = false
  }
}

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
  default     = null
}

# =========================================================================
# Load Balancer Security Group Configuration
# =========================================================================

variable "create_lb_security_group" {
  description = "Whether to create a security group for the load balancer"
  type        = bool
  default     = false
}

variable "lb_security_group_name" {
  description = "Name of the load balancer security group"
  type        = string
  default     = null
}

variable "lb_security_group_description" {
  description = "Description for the load balancer security group"
  type        = string
  default     = "Security group for rate limiter load balancer"
}

variable "lb_ingress_rules" {
  description = "Ingress rules for load balancer security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}

variable "lb_egress_rules" {
  description = "Egress rules for load balancer security group"
  type = map(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = {}
}
