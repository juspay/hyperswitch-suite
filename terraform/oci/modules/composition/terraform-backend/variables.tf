variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "state_bucket_name" {
  type = string
}

variable "allow_destroy" {
  description = "Equivalent of AWS allow_destroy (force_destroy on the bucket)"
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "OCI Vault KMS key OCID for bucket encryption (equivalent of AWS kms_master_key_id). If null, Oracle-managed encryption keys are used."
  type        = string
  default     = null
}

variable "create_lock_table" {
  description = <<-EOT
    Whether to create an OCI NoSQL Database table for state locking
    (equivalent of AWS's DynamoDB lock table). Usually unnecessary: when
    Terraform's S3-compatible backend targets OCI Object Storage's S3
    Compatibility API, Terraform >= 1.10 performs native conditional-write
    locking against the bucket itself, with no separate lock table needed.
    Set this to true only if you need to support older Terraform versions
    or a locking mechanism external to the S3-compatible backend.
  EOT
  type        = bool
  default     = false
}

variable "lock_table_name" {
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
