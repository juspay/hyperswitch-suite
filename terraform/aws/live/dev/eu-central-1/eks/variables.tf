variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "vpn_cidr_blocks" {
  description = "CIDR blocks for VPN access to EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_access_entries" {
  description = "Map of IAM principals to grant access to the EKS cluster"
  type        = any
  default     = {}
}

variable "enable_helm_deployments" {
  description = "Enable Helm deployments managed by Terraform. Set to false if using ArgoCD from another cluster"
  type        = bool
  default     = true
}

variable "enable_cluster_autoscaler" {
  description = "Enable Kubernetes Cluster Autoscaler"
  type        = bool
  default     = true
}

variable "argocd_assume_role_principal_arn" {
  description = "ARN of the ArgoCD IAM role that can assume the EKS cluster role"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS cluster"
  type        = list(string)
}

variable "node_groups" {
  description = "EKS managed node groups configuration"
  type        = any
  default     = {}
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "hyperswitch"
    ManagedBy   = "terraform"
  }
}