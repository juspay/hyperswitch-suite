# Output contract

output "vault_id" {
  description = "OCID of the Vault. Consumed by ESO's SecretStore spec.provider.oracle.vault."
  value       = oci_kms_vault.this.id
}

output "compartment_id" {
  description = "Compartment the Vault and key live in. The consuming policy attaches at the same compartment, so no workload mapping is needed."
  value       = oci_kms_vault.this.compartment_id
}

output "key_id" {
  description = "OCID of the master key. Encrypts the secret bundles; wired into the Vault at secret-creation time out of band."
  value       = oci_kms_key.this.id
}

output "region" {
  description = "Region identifier, for callers that wire ESO's SecretStore spec.provider.oracle.region."
  value       = var.region
}

output "management_endpoint" {
  description = "Management API endpoint of the Vault."
  value       = oci_kms_vault.this.management_endpoint
}

output "crypto_endpoint" {
  description = "Crypto API endpoint of the Vault."
  value       = oci_kms_vault.this.crypto_endpoint
}