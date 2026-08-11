output "bucket_name" {
  value = oci_objectstorage_bucket.state.name
}

output "namespace" {
  value = data.oci_objectstorage_namespace.this.namespace
}

output "s3_compatible_endpoint" {
  description = "Use as the `endpoints.s3` value in a Terraform S3-compatible backend block (substitute your region key, e.g. us-ashburn-1)"
  value       = "https://${data.oci_objectstorage_namespace.this.namespace}.compat.objectstorage.<region>.oraclecloud.com"
}

output "lock_table_name" {
  value = try(oci_nosql_table.lock[0].name, null)
}
