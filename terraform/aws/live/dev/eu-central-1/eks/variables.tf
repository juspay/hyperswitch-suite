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

variable "cluster_name_version" {
  description = "Version identifier for the EKS cluster name"
  type        = string
  default     = "v1"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.34"
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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

variable "eks_addon_versions" {
  description = "Map of EKS addon names to their versions"
  type        = map(string)
  default = {
    vpc-cni             = "v1.21.1-eksbuild.1"
    coredns             = "v1.12.4-eksbuild.1"
    kube-proxy          = "v1.34.1-eksbuild.2"
    aws-ebs-csi-driver  = "v1.54.0-eksbuild.1"
    snapshot-controller = "v8.3.0-eksbuild.1"
  }
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