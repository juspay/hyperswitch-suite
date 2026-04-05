# =============================================================================
# Provider Configuration
# =============================================================================

provider "aws" {
  region = "eu-central-1"
}

terraform {
  # Backend Configuration
  backend "s3" {
    bucket  = "hyperswitch-dev-terraform-state"
    key     = "dev/eu-central-1/eks-kubernetes-resources/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.1"
    }
  }
}
