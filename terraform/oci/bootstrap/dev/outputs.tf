# =============================================================================
# Bucket outputs
# =============================================================================
# state_bucket_name and state_bucket_namespace are the two values every OCI
# root.hcl must carry as locals. The namespace in particular has no AWS or GCP
# counterpart and cannot be supplied through an environment variable - it has to
# be literal in the backend block.

output "state_bucket_name" {
  description = "Name of the Terraform state bucket"
  value       = module.object_storage_backend.state_bucket_name
}

output "state_bucket_namespace" {
  description = "Object Storage namespace of the state bucket"
  value       = module.object_storage_backend.state_bucket_namespace
}

output "state_bucket_ocid" {
  description = "OCID of the Terraform state bucket"
  value       = module.object_storage_backend.state_bucket_ocid
}

output "state_bucket_region" {
  description = "Region of the Terraform state bucket"
  value       = module.object_storage_backend.state_bucket_region
}

output "state_bucket_compartment_id" {
  description = "OCID of the compartment holding the state bucket"
  value       = module.object_storage_backend.state_bucket_compartment_id
}

# Null unless an access group or dynamic group was supplied. There is no
# lock-table output on OCI: the native backend locks with an If-None-Match
# conditional write, so AWS's dynamodb_table_name / dynamodb_table_arn outputs
# have nothing to correspond to.
output "state_access_policy_id" {
  description = "OCID of the IAM policy granting state-bucket access, or null when none was created"
  value       = module.object_storage_backend.state_access_policy_id
}

# =============================================================================
# Backend configuration
# =============================================================================

output "backend_config" {
  description = "Backend configuration object for other OCI roots"
  value       = module.object_storage_backend.backend_config
}

output "next_steps" {
  description = "What to do once this root has been applied"
  value       = <<-EOT

  ========================================
  OCI Terraform state backend created
  ========================================

  Bucket:      ${module.object_storage_backend.state_bucket_name}
  Namespace:   ${module.object_storage_backend.state_bucket_namespace}
  Region:      ${module.object_storage_backend.state_bucket_region}
  Compartment: ${module.object_storage_backend.state_bucket_compartment_id}

  ========================================
  State locking
  ========================================

  Nothing else to provision. The native oci backend takes a lock by writing
  <workspace_key_prefix>/<workspace>/<key>.lock into this bucket with an
  If-None-Match conditional write. There is no DynamoDB-equivalent table.

  ========================================
  Next steps
  ========================================

  1. Record these two locals in every OCI live root.hcl
     (hyperswitch-infra, terraform/oci/live/<env>/<region>/root.hcl):

       state_bucket_name       = "${module.object_storage_backend.state_bucket_name}"
       object_storage_namespace = "${module.object_storage_backend.state_bucket_namespace}"

  2. Point that root.hcl's remote_state block at them:

  ${module.object_storage_backend.backend_config_formatted}

  3. Terragrunt will NOT create this bucket for you if the name is wrong -
     for backend = "oci" it only generates HCL. A typo surfaces as a
     bucket-not-found error on the first terragrunt init.

  4. Verify the bucket is reachable:

     oci os bucket get \
       --bucket-name ${module.object_storage_backend.state_bucket_name} \
       --namespace ${module.object_storage_backend.state_bucket_namespace}

  ========================================

  EOT
}
