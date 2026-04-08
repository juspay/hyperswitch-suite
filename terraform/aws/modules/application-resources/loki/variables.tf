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
  default     = "loki"
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
# S3 Bucket Configuration
# =========================================================================

variable "s3" {
  description = "S3 bucket configuration for Loki logs storage. Set to {} to disable. Set create=true to create bucket, or create=false with bucket_arn to use existing."
  type = object({
    create     = optional(bool, false)  # Set true to create S3 bucket, false to use existing
    bucket_arn = optional(string, null) # Existing S3 bucket ARN (used when create=false)

    # Bucket creation settings (used when create=true)
    bucket_name                            = optional(string, null) # Auto-generated if not provided
    force_destroy                          = optional(bool, false)
    versioning_enabled                     = optional(bool, false)
    lifecycle_rules                        = optional(any, [])
    lifecycle_rule                         = optional(any, null)    # Backward-compatible alias
    transition_default_minimum_object_size = optional(string, null) # all_storage_classes_128K | varies_by_storage_class
  })
  default = {}

  validation {
    condition = (
      try(var.s3.transition_default_minimum_object_size, null) == null ||
      contains([
        "all_storage_classes_128K",
        "varies_by_storage_class"
      ], var.s3.transition_default_minimum_object_size)
    )
    error_message = "s3.transition_default_minimum_object_size must be null, 'all_storage_classes_128K', or 'varies_by_storage_class'."
  }

}

# =========================================================================
# Security Group Configuration
# =========================================================================

variable "vpc_id" {
  description = "VPC ID where the security group will be created. Required if create_security_group is true."
  type        = string
  default     = null
}

variable "eks_node_security_group_id" {
  description = "EKS node security group ID. When provided, the module will create ingress rules on the EKS node security group to allow traffic from the Loki LB, and egress rules on the Loki LB to reach EKS nodes."
  type        = string
  default     = null
}

variable "create_security_group" {
  description = "Whether to create a security group for the Loki ALB ingress"
  type        = bool
  default     = false
}

variable "security_group_name" {
  description = "Custom name for the security group. If null, auto-generated as {environment}-{project}-{app}-alb-sg"
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Description for the security group"
  type        = string
  default     = "Security group for Loki ALB ingress"
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), null)
    source_security_group_id = optional(string, null)
    prefix_list_ids          = optional(list(string), null)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the security group"
  type = list(object({
    description              = string
    from_port                = number
    to_port                  = number
    protocol                 = string
    cidr_blocks              = optional(list(string), null)
    source_security_group_id = optional(string, null)
    prefix_list_ids          = optional(list(string), null)
  }))
  default = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
