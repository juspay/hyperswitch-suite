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

variable "keeper_subnet_id" {
  type = string
}

variable "server_subnet_id" {
  type = string
}

variable "lb_subnet_id" {
  description = "Subnet for the internal Load Balancer (equivalent to AWS alb_subnet_ids)"
  type        = string
}

variable "keeper_count" {
  type    = number
  default = 3
}

variable "server_count" {
  type    = number
  default = 3
}

variable "keeper_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "keeper_ocpus" {
  type    = number
  default = 2
}

variable "keeper_memory_in_gbs" {
  type    = number
  default = 16
}

variable "server_shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "server_ocpus" {
  type    = number
  default = 8
}

variable "server_memory_in_gbs" {
  type    = number
  default = 64
}

variable "image_id" {
  type = string
}

variable "keeper_boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "keeper_data_volume_size_in_gbs" {
  type    = number
  default = 200
}

variable "server_boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "server_data_volume_size_in_gbs" {
  type    = number
  default = 1000
}

variable "ssh_authorized_keys" {
  type    = string
  default = null
}

variable "keeper_user_data" {
  type    = string
  default = null
}

variable "server_user_data" {
  type    = string
  default = null
}

variable "clickhouse_port" {
  type    = number
  default = 8123
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
