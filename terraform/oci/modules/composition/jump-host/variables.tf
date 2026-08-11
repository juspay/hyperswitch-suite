variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  type    = number
  default = 1
}

variable "instance_memory_in_gbs" {
  type    = number
  default = 8
}

variable "image_id" {
  type = string
}

variable "root_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "ssh_authorized_keys" {
  type    = string
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "create_session_log_bucket" {
  description = "Equivalent of AWS create_ssm_s3_bucket - stores session recording logs"
  type        = bool
  default     = true
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
