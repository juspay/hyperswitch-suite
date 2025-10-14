variable "name" {
  description = "Name for the Auto Scaling Group"
  type        = string
}

variable "launch_template_id" {
  description = "ID of the launch template to use"
  type        = string
}

variable "launch_template_version" {
  description = "Launch template version to use"
  type        = string
  default     = "$Latest"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG"
  type        = list(string)
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0
    error_message = "Minimum size must be >= 0"
  }
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
  default     = 3

  validation {
    condition     = var.max_size >= 1
    error_message = "Maximum size must be >= 1"
  }
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
  default     = 1

  validation {
    condition     = var.desired_capacity >= 0
    error_message = "Desired capacity must be >= 0"
  }
}

variable "target_group_arns" {
  description = "List of target group ARNs to attach"
  type        = list(string)
  default     = []
}

variable "health_check_type" {
  description = "Type of health check (EC2 or ELB)"
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "Health check type must be either EC2 or ELB"
  }
}

variable "health_check_grace_period" {
  description = "Time in seconds after instance comes into service before checking health"
  type        = number
  default     = 300
}

variable "default_cooldown" {
  description = "Time in seconds between scaling activities"
  type        = number
  default     = 300
}

variable "enabled_metrics" {
  description = "List of metrics to enable for ASG"
  type        = list(string)
  default = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
}

variable "tags" {
  description = "Map of tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "instance_tags" {
  description = "Additional tags to apply to instances (will be propagated)"
  type        = map(string)
  default     = {}
}

variable "wait_for_capacity_timeout" {
  description = "Maximum duration to wait for capacity"
  type        = string
  default     = "10m"
}

variable "termination_policies" {
  description = "List of policies to use for instance termination"
  type        = list(string)
  default     = ["Default"]
}

variable "suspended_processes" {
  description = "List of processes to suspend"
  type        = list(string)
  default     = []
}
