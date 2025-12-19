variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
  validation {
    condition     = contains(["dev", "integ", "prod"], var.environment)
    error_message = "Environment must be one of: dev, integ, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN for encryption/decryption"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN for EKS cluster"
  type        = string
}

variable "oidc_provider_id" {
  description = "OIDC provider ID for EKS cluster (e.g., oidc.eks.region.amazonaws.com/id/XXXXX)"
  type        = string
}

variable "service_accounts" {
  description = "List of Kubernetes service accounts that can assume the role (format: system:serviceaccount:namespace:service-account-name)"
  type        = list(string)
  default = [
    "system:serviceaccount:router:router-role",
    "system:serviceaccount:hyperswitch-sandbox:hyperswitch-router-role"
  ]
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket. If not provided, a unique name will be generated"
  type        = string
  default     = null
}

variable "enable_s3_versioning" {
  description = "Enable versioning for S3 bucket"
  type        = bool
  default     = true
}

variable "s3_force_destroy" {
  description = "Allow deletion of S3 bucket even if it contains objects"
  type        = bool
  default     = false
}