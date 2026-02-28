variable "create" {
  description = "Controls if resources should be created"
  type        = bool
  default     = true
}

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

# =========================================================================
# Instance Refresh Configuration
# =========================================================================
variable "enable_instance_refresh" {
  description = "Enable automatic instance refresh when launch template changes"
  type        = bool
  default     = false
}

variable "instance_refresh_preferences" {
  description = "Preferences for instance refresh behavior"
  type = object({
    min_healthy_percentage       = optional(number, 50)
    instance_warmup              = optional(number, 300)
    max_healthy_percentage       = optional(number, 100)
    checkpoint_percentages       = optional(list(number), [50])
    checkpoint_delay             = optional(number, 300)
    scale_in_protected_instances = optional(string, "Ignore")
    standby_instances            = optional(string, "Ignore")
  })
  default = {
    min_healthy_percentage       = 50
    instance_warmup              = 300
    max_healthy_percentage       = 100
    checkpoint_percentages       = [50]
    checkpoint_delay             = 300
    scale_in_protected_instances = "Ignore"
    standby_instances            = "Ignore"
  }
}

variable "instance_refresh_triggers" {
  description = "List of triggers that will start an instance refresh. Note: launch_template changes always trigger refresh automatically."
  type        = list(string)
  default     = []  # Empty - launch_template triggers are automatic
}

# =========================================================================
# Mixed Instances Policy (Spot + On-Demand)
# =========================================================================
variable "enable_mixed_instances_policy" {
  description = "Enable mixed instances policy for spot and on-demand instances"
  type        = bool
  default     = false
}

variable "mixed_instances_policy" {
  description = "Configuration for mixed instances policy (spot + on-demand)"
  type = object({
    on_demand_base_capacity                  = optional(number, 0)
    on_demand_percentage_above_base_capacity = optional(number, 50)
    spot_allocation_strategy                 = optional(string, "capacity-optimized")
    spot_instance_pools                      = optional(number, 2)
    spot_max_price                           = optional(string, "")
  })
  default = {
    on_demand_base_capacity                  = 0
    on_demand_percentage_above_base_capacity = 50
    spot_allocation_strategy                 = "capacity-optimized"
    spot_instance_pools                      = 2
    spot_max_price                           = ""
  }
}

variable "max_instance_lifetime" {
  description = "Maximum lifetime of instances in seconds (0 = no limit)"
  type        = number
  default     = 0
}

variable "capacity_rebalance" {
  description = "Enable capacity rebalancing for spot instances"
  type        = bool
  default     = false
}

# =========================================================================
# Auto Scaling Policies
# =========================================================================
variable "enable_scaling_policies" {
  description = "Enable auto-scaling policies for dynamic scaling based on CPU and Memory"
  type        = bool
  default     = false
}

variable "scaling_policies" {
  description = "Configuration for auto-scaling policies using built-in AWS metrics"
  type = object({
    # CPU-based target tracking
    cpu_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70.0) # Target CPU utilization %
    }), {})

    # Memory-based target tracking (requires CloudWatch agent on instances)
    memory_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70.0) # Target Memory utilization %
    }), {})
  })
  default = {
    cpu_target_tracking = {
      enabled      = false
      target_value = 70.0
    }
    memory_target_tracking = {
      enabled      = false
      target_value = 70.0
    }
  }
}
