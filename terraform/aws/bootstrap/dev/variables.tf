variable "region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "eu-central-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
  default     = "hyperswitch-dev-terraform-state"

  # Note: S3 bucket names must be globally unique
  # If this name is taken, add a suffix like: hyperswitch-dev-terraform-state-YOURNAME
}

variable "allow_destroy" {
  description = "Allow destruction of the bucket (should be false for prod)"
  type        = bool
  default     = true  # Dev can be destroyed easily
}
