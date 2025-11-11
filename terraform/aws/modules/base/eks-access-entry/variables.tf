variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "principal_arn" {
  description = "ARN of the IAM principal (user or role)"
  type        = string
}

variable "kubernetes_groups" {
  description = "List of Kubernetes groups to assign to the principal"
  type        = list(string)
  default     = []
}

variable "type" {
  description = "Type of the access entry. Valid values: STANDARD, FARGATE_LINUX"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "FARGATE_LINUX"], var.type)
    error_message = "Type must be either STANDARD or FARGATE_LINUX"
  }
}

variable "user_name" {
  description = "Username to map to the IAM principal"
  type        = string
  default     = null
}

variable "access_policies" {
  description = "List of access policies to associate with the entry"
  type = list(object({
    policy_arn               = string
    access_scope_type        = string
    access_scope_namespaces  = optional(list(string))
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
