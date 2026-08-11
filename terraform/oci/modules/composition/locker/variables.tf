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

variable "locker_subnet_id" {
  type = string
}

variable "lb_subnet_id" {
  type = string
}

variable "instance_count" {
  type    = number
  default = 2
}

variable "shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  type    = number
  default = 4
}

variable "instance_memory_in_gbs" {
  type    = number
  default = 16
}

variable "image_id" {
  type = string
}

variable "locker_port" {
  type    = number
  default = 8080
}

variable "user_data" {
  type    = string
  default = null
}

variable "additional_policy_statements" {
  description = "Extra OCI IAM policy statements for the locker dynamic group (equivalent to AWS additional_policy_arns)"
  type        = list(string)
  default     = []
}

variable "vault_key_ids" {
  description = "OCI Vault KMS key OCIDs the locker instance needs to use (equivalent to AWS kms)"
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------------------
# Optional embedded database (equivalent of AWS locker/database.tf's
# conditional `module.database`, which sources the sibling `database`
# composition module)
# ---------------------------------------------------------------------------
variable "create_locker_database" {
  type    = bool
  default = true
}

variable "database_subnet_id" {
  type    = string
  default = null
}

variable "database_shape" {
  type    = string
  default = "PostgreSQL.VM.Standard.E4.Flex"
}

variable "database_admin_password_secret_id" {
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
