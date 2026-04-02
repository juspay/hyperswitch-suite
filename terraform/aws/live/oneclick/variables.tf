variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "hyperswitch"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  type    = list(string)
  default = null
}

variable "cluster_version" {
  type    = string
  default = "1.35"
}

variable "cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "cluster_enabled_log_types" {
  type    = list(string)
  default = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  type    = number
  default = 30
}

variable "addon_versions" {
  type = object({
    vpc_cni            = string
    coredns            = string
    kube_proxy         = string
    ebs_csi            = string
    pod_identity_agent = string
  })
  default = {
    vpc_cni            = "v1.19.0-eksbuild.1"
    coredns            = "v1.13.2-eksbuild.1"
    kube_proxy         = "v1.35.0-eksbuild.2"
    ebs_csi            = "v1.55.0-eksbuild.1"
    pod_identity_agent = "v1.3.2-eksbuild.1"
  }
}

variable "node_group" {
  type = object({
    capacity_type              = string
    instance_types             = list(string)
    desired_size               = number
    min_size                   = number
    max_size                   = number
    max_unavailable_percentage = number
    labels                     = map(string)
  })
  default = {
    capacity_type              = "ON_DEMAND"
    instance_types             = ["t3.medium"]
    desired_size               = 4
    min_size                   = 2
    max_size                   = 10
    max_unavailable_percentage = 33
    labels                     = {}
  }
}

variable "hyperswitch_namespace" {
  type    = string
  default = "hyperswitch"
}

variable "hyperswitch_release_name" {
  type    = string
  default = "hyperswitch"
}

variable "hyperswitch_helm_version" {
  type    = string
  default = null
}

variable "hyperswitch_helm_values" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}
