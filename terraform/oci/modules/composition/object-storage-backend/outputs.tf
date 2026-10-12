# Bucket outputs. Two AWS outputs have no OCI counterpart and are documented
# rather than faked:
#   state_bucket_arn - OCI has no ARN; the OCID plus the namespace+name pair play
#     that role (the backend addresses the bucket by namespace+name).
#   lock_table_* - nothing to output: locking is built into the `oci` backend
#     (If-None-Match conditional write), there is no lock-table resource.

output "state_bucket_name" {
  description = "Name of the Terraform state bucket - the value a root.hcl remote_state.config.bucket needs"
  value       = oci_objectstorage_bucket.state.name
}

output "state_bucket_ocid" {
  description = "OCID of the Terraform state bucket (closest counterpart to AWS's state_bucket_arn)"
  value       = oci_objectstorage_bucket.state.bucket_id
}

output "state_bucket_namespace" {
  description = "Object Storage namespace of the state bucket - the value a root.hcl remote_state.config.namespace needs. Has no AWS or GCP counterpart"
  value       = data.oci_objectstorage_namespace.this.namespace
}

output "state_bucket_region" {
  description = "Region of the state bucket (passed through from var.region - not a bucket attribute on OCI)"
  value       = var.region
}

output "state_bucket_compartment_id" {
  description = "OCID of the compartment holding the state bucket"
  value       = oci_objectstorage_bucket.state.compartment_id
}

# IAM
output "state_access_policy_id" {
  description = "OCID of the IAM policy granting state-bucket access, or null when no access subject was supplied"
  value       = length(oci_identity_policy.state_access) > 0 ? oci_identity_policy.state_access[0].id : null
}

# Backend configuration
output "backend_config" {
  description = "Backend configuration object for use by other Terraform/Terragrunt roots"
  value = {
    bucket    = oci_objectstorage_bucket.state.name
    namespace = data.oci_objectstorage_namespace.this.namespace
    region    = var.region
    auth      = var.backend_auth
  }
}

output "backend_config_formatted" {
  description = "Formatted backend configuration for copy-paste into a backend.tf, matching state-backend-decision.md section 4"
  value       = <<-EOT
    terraform {
      backend "oci" {
        bucket    = "${oci_objectstorage_bucket.state.name}"
        namespace = "${data.oci_objectstorage_namespace.this.namespace}"
        region    = "${var.region}"
        key       = "<environment>/<region>/<service>/terraform.tfstate"
        auth      = "${var.backend_auth}"
      }
    }

    # No dynamodb_table / lock table argument: the oci backend locks natively
    # with an If-None-Match conditional write on a .lock object in this bucket.
  EOT
}
