# ============================================================================
# API Gateway Configuration
# ============================================================================
variable "name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "description" {
  description = "Description of the API Gateway"
  type        = string
  default     = "Managed by Terraform"
}

variable "endpoint_type" {
  description = "Endpoint type for the API Gateway (REGIONAL, EDGE, or PRIVATE)"
  type        = string
  default     = "REGIONAL"
}

variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs for PRIVATE endpoint type"
  type        = list(string)
  default     = []
}

# ============================================================================
# Resource Configuration
# ============================================================================
variable "resources" {
  description = "List of API resources to create"
  type = list(object({
    path_part   = string
    parent_path = optional(string, "/") # Parent path, defaults to root
  }))
  default = []
}

# ============================================================================
# Method Configuration
# ============================================================================
variable "methods" {
  description = "List of API methods to create"
  type = list(object({
    resource_path      = string
    http_method        = string
    authorization      = optional(string, "NONE")
    authorizer_id      = optional(string, null)
    api_key_required   = optional(bool, false)
    request_parameters = optional(map(string), {})
  }))
  default = []
}

# ============================================================================
# Lambda Integration Configuration
# ============================================================================
variable "lambda_integrations" {
  description = "List of Lambda integrations to create"
  type = list(object({
    resource_path    = string
    http_method      = string
    lambda_arn       = string
    integration_type = optional(string, "AWS_PROXY")
  }))
  default = []
}

# ============================================================================
# Stage Configuration
# ============================================================================
variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "default"
}

variable "stage_description" {
  description = "Description of the stage"
  type        = string
  default     = ""
}

variable "stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Tags
# ============================================================================
variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
