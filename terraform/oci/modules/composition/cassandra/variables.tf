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
  description = "Equivalent to AWS cassandra subnet placement"
  type        = string
}

variable "node_count" {
  type    = number
  default = 3
}

variable "shape" {
  description = "Compute shape, e.g. \"VM.Standard.E4.Flex\" (equivalent to AWS instance_type)"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_flex_ocpus" {
  type    = number
  default = 4
}

variable "instance_flex_memory_in_gbs" {
  type    = number
  default = 32
}

variable "image_id" {
  description = "Equivalent to AWS ami_id"
  type        = string
}

variable "boot_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "data_volume_size_in_gbs" {
  description = "Equivalent to AWS ebs_volume_size (attached data volume for Cassandra data directory)"
  type        = number
  default     = 500
}

variable "ssh_authorized_keys" {
  description = "Equivalent to AWS public_key for the auto-managed key pair"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Cloud-init user data (base64 is handled by the compute-instance module)"
  type        = string
  default     = null
}

variable "vcn_endpoint_nsg_id" {
  description = "NSG ID of a service/VCN endpoint that Cassandra nodes need HTTPS access to (equivalent to AWS vpc_endpoint_security_group_id)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
