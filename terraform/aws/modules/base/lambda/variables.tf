# ============================================================================
# Function Configuration
# ============================================================================
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Managed by Terraform"
}

variable "runtime" {
  description = "Runtime environment for the Lambda function"
  type        = string
}

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
}

variable "source_code_path" {
  description = "Path to the source code file or directory"
  type        = string
  default     = null
}

variable "source_code_content" {
  description = "Inline source code content (alternative to source_code_path)"
  type        = string
  default     = null
}

variable "source_code_filename" {
  description = "Filename for inline source code (required if using source_code_content)"
  type        = string
  default     = "index.js"
}

variable "timeout" {
  description = "Function execution timeout in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Amount of memory in MB allocated to the function"
  type        = number
  default     = 128
}

# ============================================================================
# IAM Configuration
# ============================================================================
variable "iam_role_arn" {
  description = "ARN of the IAM role for the Lambda function (if using existing role)"
  type        = string
  default     = null
}

variable "create_iam_role" {
  description = "Whether to create a new IAM role for the Lambda function"
  type        = bool
  default     = true
}

variable "iam_role_name" {
  description = "Name of the IAM role to create (if create_iam_role is true)"
  type        = string
  default     = null
}

variable "iam_role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IAM role for Lambda function"
}

variable "managed_policy_arns" {
  description = "List of managed policy ARNs to attach to the IAM role"
  type        = list(string)
  default     = []
}

variable "inline_policies" {
  description = "Map of inline policies to attach to the IAM role"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Environment Configuration
# ============================================================================
variable "environment_variables" {
  description = "Map of environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Network Configuration
# ============================================================================
variable "vpc_id" {
  description = "VPC ID for the Lambda function (for VPC-enabled functions)"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Lambda function"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs for the Lambda function"
  type        = list(string)
  default     = []
}

# ============================================================================
# Logging Configuration
# ============================================================================
variable "create_log_group" {
  description = "Whether to create a CloudWatch log group for the Lambda function"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for CloudWatch log group encryption"
  type        = string
  default     = null
}

# ============================================================================
# Tags
# ============================================================================
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
