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
  description = "Display name for the DB system (equivalent to AWS cluster_identifier)"
  type        = string
  default     = null
}

variable "db_version" {
  description = "PostgreSQL major version, e.g. \"16\" (equivalent to AWS engine_version)"
  type        = string
  default     = "16"
}

variable "shape" {
  description = "DB instance node shape (equivalent to AWS db_cluster_instance_class), e.g. \"PostgreSQL.VM.Standard.E4.Flex\""
  type        = string
}

variable "instance_ocpu_count" {
  type    = number
  default = 2
}

variable "instance_memory_size_in_gbs" {
  type    = number
  default = 32
}

variable "instance_count" {
  description = "Number of DB instance nodes (1 = standalone, 3 = primary + 2 replicas, equivalent to AWS cluster_instances count)"
  type        = number
  default     = 1
}

variable "subnet_id" {
  description = "Subnet OCID for the DB system (equivalent to AWS db_subnet_group_name / subnet_ids)"
  type        = string
}

variable "nsg_ids" {
  description = "Network Security Group OCIDs (equivalent to AWS vpc_security_group_ids)"
  type        = list(string)
  default     = []
}

variable "admin_username" {
  type    = string
  default = "hyperswitch_admin"
}

variable "admin_password_secret_id" {
  description = "OCID of the OCI Vault secret holding the admin password (equivalent to AWS manage_master_user_password via Secrets Manager)"
  type        = string
}

variable "admin_password_secret_version" {
  type    = number
  default = null
}

variable "storage_is_regionally_durable" {
  description = "true = regional block storage (recommended, matches AWS Multi-AZ durability); false requires availability_domain to be set"
  type        = bool
  default     = true
}

variable "storage_system_type" {
  description = "OCI_OPTIMIZED_STORAGE or ODB_STORAGE"
  type        = string
  default     = "OCI_OPTIMIZED_STORAGE"
}

variable "backup_policy_kind" {
  description = "DAILY | WEEKLY | MONTHLY | DISABLED (equivalent to AWS backup_retention_period > 0)"
  type        = string
  default     = "DAILY"
}

variable "backup_retention_days" {
  description = "Equivalent to AWS backup_retention_period"
  type        = number
  default     = 7
}

variable "backup_start_hour" {
  type    = string
  default = "03:00"
}

variable "config_id" {
  description = "OCID of an oci_psql_configuration (equivalent to AWS db_cluster_parameter_group_name)"
  type        = string
  default     = null
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
