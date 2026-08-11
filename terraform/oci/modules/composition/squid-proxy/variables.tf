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

variable "proxy_subnet_id" {
  type = string
}

variable "lb_subnet_id" {
  type = string
}

variable "availability_domain" {
  description = "AD for instance-pool placement (equivalent of AWS ASG spreading across AZs - OCI instance pools take an explicit list of ADs; single-AD here for simplicity, extend placement_configurations for multi-AD)"
  type        = string
}

variable "shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  type    = number
  default = 2
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

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "size" {
  description = "Desired instance pool size (equivalent to AWS desired_capacity)"
  type        = number
  default     = 2
}

variable "squid_port" {
  type    = number
  default = 3128
}

variable "create_nlb" {
  type    = bool
  default = true
}

variable "ssh_authorized_keys" {
  type    = string
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

variable "create_config_bucket" {
  type    = bool
  default = true
}

variable "create_logs_bucket" {
  type    = bool
  default = true
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
