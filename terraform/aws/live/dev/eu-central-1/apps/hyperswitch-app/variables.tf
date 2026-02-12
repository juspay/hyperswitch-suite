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

variable "custom_trust_statements" {
  description = "Custom trust policy statements for maximum flexibility"
  type        = list(any)
  default     = []
}

variable "oidc_provider_arn" {
  description = "Full OIDC provider ARN from EKS cluster. Found in EKS cluster details under OIDC provider"
  type        = string
  default     = "arn:aws:iam::XXXXXXXXXXXX:oidc-provider/oidc.eks.REGION.amazonaws.com/id/XXXXXXXXXXXXXXXXXXXXXXXXXX"
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
