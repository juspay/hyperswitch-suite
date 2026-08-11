variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "display_name" {
  type    = string
  default = null
}

variable "software_version" {
  description = "Equivalent to AWS engine_version"
  type        = string
  default     = "2.11.0"
}

variable "vcn_id" {
  type = string
}

variable "subnet_id" {
  description = "Equivalent to AWS vpc_options.subnet_ids"
  type        = string
}

variable "nsg_id" {
  description = "Equivalent to AWS vpc_options.security_group_ids"
  type        = string
  default     = null
}

# Data nodes (equivalent to AWS cluster_config data node sizing)
variable "data_node_count" {
  type    = number
  default = 3
}

variable "data_node_host_ocpu_count" {
  type    = number
  default = 4
}

variable "data_node_host_memory_gb" {
  type    = number
  default = 64
}

variable "data_node_host_type" {
  type    = string
  default = "VM.Standard.E4"
}

variable "data_node_storage_gb" {
  description = "Equivalent to AWS ebs_options.volume_size"
  type        = number
  default     = 512
}

# Master nodes (equivalent to AWS dedicated_master_*)
variable "master_node_count" {
  type    = number
  default = 3
}

variable "master_node_host_ocpu_count" {
  type    = number
  default = 2
}

variable "master_node_host_memory_gb" {
  type    = number
  default = 32
}

variable "master_node_host_type" {
  type    = string
  default = "VM.Standard.E4"
}

# OpenSearch Dashboards nodes (equivalent to AWS Kibana access, implicit in AWS)
variable "opendashboard_node_count" {
  type    = number
  default = 1
}

variable "opendashboard_node_host_ocpu_count" {
  type    = number
  default = 2
}

variable "opendashboard_node_host_memory_gb" {
  type    = number
  default = 16
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
