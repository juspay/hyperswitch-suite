variable "name" {
  description = "Name prefix for the launch template"
  type        = string
}

variable "description" {
  description = "Description of the launch template"
  type        = string
  default     = "Managed by Terraform"
}

variable "ami_id" {
  description = "AMI ID to use for instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
  default     = null
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
  default     = []
}

variable "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  type        = string
  default     = null
}

variable "user_data" {
  description = "User data script (will be base64 encoded)"
  type        = string
  default     = ""
}

variable "user_data_base64" {
  description = "Base64 encoded user data (use this if already encoded)"
  type        = string
  default     = null
}

variable "ebs_optimized" {
  description = "Whether the instance is EBS optimized"
  type        = bool
  default     = true
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "block_device_mappings" {
  description = "Block device mappings"
  type = list(object({
    device_name = string
    ebs = optional(object({
      volume_size           = number
      volume_type           = optional(string, "gp3")
      iops                  = optional(number, null)
      throughput            = optional(number, null)
      delete_on_termination = optional(bool, true)
      encrypted             = optional(bool, true)
      kms_key_id            = optional(string, null)
    }))
  }))
  default = []
}

variable "metadata_options" {
  description = "Metadata options for the instance"
  type = object({
    http_endpoint               = optional(string, "enabled")
    http_tokens                 = optional(string, "required")
    http_put_response_hop_limit = optional(number, 1)
    instance_metadata_tags      = optional(string, "disabled")
  })
  default = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
}

variable "tag_specifications" {
  description = "Tag specifications for resources created by instances"
  type = list(object({
    resource_type = string
    tags          = map(string)
  }))
  default = []
}

variable "tags" {
  description = "Map of tags to apply to the launch template"
  type        = map(string)
  default     = {}
}

variable "update_default_version" {
  description = "Whether to update the default version on each update"
  type        = bool
  default     = true
}
