variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

variable "name" {
  description = "Name of the network load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal or external"
  type        = bool
  default     = true
}

variable "subnets" {
  description = "List of subnet IDs to attach to the load balancer"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs to attach to the load balancer"
  type        = list(string)
  default     = []
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the load balancer"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "Enable cross-zone load balancing"
  type        = bool
  default     = true
}

variable "access_logs" {
  description = "Access logs configuration"
  type = object({
    enabled = optional(bool, false)
    bucket  = optional(string, null)
    prefix  = optional(string, null)
  })
  default = {
    enabled = false
  }
}

variable "tags" {
  description = "Map of tags to apply to the load balancer"
  type        = map(string)
  default     = {}
}
