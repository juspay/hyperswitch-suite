output "keyring_id" {
  description = "Full resource ID of the KMS keyring"
  value       = google_kms_key_ring.this.id
}

output "keyring_name" {
  description = "Name of the KMS keyring"
  value       = google_kms_key_ring.this.name
}

output "key_ids" {
  description = "Map of key name → full resource ID (self-link) of each CryptoKey"
  value       = { for k, v in google_kms_crypto_key.keys : k => v.id }
}

output "key_self_links" {
  description = "Map of key name → self-link of each CryptoKey (compatible with encryption_key_name inputs)"
  value       = { for k, v in google_kms_crypto_key.keys : k => v.id }
}
