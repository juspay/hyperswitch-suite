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

variable "broker_subnet_id" {
  type = string
}

variable "controller_subnet_id" {
  type = string
}

variable "broker_count" {
  type    = number
  default = 3
}

variable "broker_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "broker_ocpus" {
  type    = number
  default = 4
}

variable "broker_memory_in_gbs" {
  type    = number
  default = 32
}

variable "controller_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "controller_ocpus" {
  type    = number
  default = 2
}

variable "controller_memory_in_gbs" {
  type    = number
  default = 16
}

variable "image_id" {
  type = string
}

variable "broker_boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "broker_data_volume_size_in_gbs" {
  type    = number
  default = 1000
}

variable "controller_boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "controller_metadata_volume_size_in_gbs" {
  type    = number
  default = 100
}

variable "ssh_authorized_keys" {
  type    = string
  default = null
}

variable "broker_user_data" {
  type    = string
  default = null
}

variable "controller_user_data" {
  type    = string
  default = null
}

variable "vcn_endpoint_nsg_id" {
  type    = string
  default = null
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
