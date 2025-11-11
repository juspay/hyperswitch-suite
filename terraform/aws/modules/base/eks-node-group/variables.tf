variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
}

variable "node_role_arn" {
  description = "ARN of the IAM role for the node group"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the node group"
  type        = list(string)
}

variable "kubernetes_version" {
  description = "Kubernetes version for the node group"
  type        = string
  default     = null
}

variable "desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_unavailable_percentage" {
  description = "Maximum percentage of nodes unavailable during updates"
  type        = number
  default     = 33
}

variable "ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group"
  type        = string
  default     = "AL2_x86_64"
}

variable "capacity_type" {
  description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
  type        = string
  default     = "ON_DEMAND"
}

variable "disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = null
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "labels" {
  description = "Key-value map of Kubernetes labels"
  type        = map(string)
  default     = {}
}

variable "release_version" {
  description = "AMI version of the EKS Node Group"
  type        = string
  default     = null
}

variable "force_update_version" {
  description = "Force version update if pods are unable to be drained"
  type        = bool
  default     = false
}

variable "launch_template_id" {
  description = "ID of the launch template for the node group"
  type        = string
  default     = null
}

variable "launch_template_version" {
  description = "Version of the launch template to use"
  type        = string
  default     = "$Latest"
}

variable "remote_access_ec2_ssh_key" {
  description = "EC2 SSH key name for remote access to nodes"
  type        = string
  default     = null
}

variable "remote_access_source_sg_ids" {
  description = "Security group IDs allowed for SSH access"
  type        = list(string)
  default     = []
}

variable "taints" {
  description = "List of taints to apply to the node group"
  type = list(object({
    key    = string
    value  = optional(string)
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "node_group_dependencies" {
  description = "List of resources the node group depends on"
  type        = list(any)
  default     = []
}
