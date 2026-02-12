variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "hyperswitch"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "hyperswitch"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}