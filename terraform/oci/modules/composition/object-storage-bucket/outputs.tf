output "bucket_name" {
  description = "Bucket name. Matches the GCS `simple_bucket` module's `name` output that GCP's hyperswitch-sdk-assets unit exposed to its CDN unit."
  value       = oci_objectstorage_bucket.this.name
}

output "bucket_id" {
  description = "Bucket OCID."
  value       = oci_objectstorage_bucket.this.id
}

output "namespace" {
  description = "Object Storage namespace the bucket lives in."
  value       = local.namespace
}

output "access_type" {
  description = "The applied public-access posture, echoed back so a plan review can see it without opening the module."
  value       = oci_objectstorage_bucket.this.access_type
}

output "base_url" {
  description = <<-EOT
    Public HTTPS prefix for objects in this bucket:
      https://objectstorage.<region>.oraclecloud.com/n/<ns>/b/<bucket>/o

    An object named `a/b/c.js` is served at `<base_url>/a/b/c.js` - slashes in
    an object name are just characters, there are no directories.

    THIS URL IS BROWSER-VALID HTTPS WITH NO EXTRA INFRASTRUCTURE. Verified live
    2026-09-05 in ap-mumbai-1: DigiCert-issued certificate, HSTS, and
    `access-control-allow-origin: *` on the response. It is only ANONYMOUSLY
    readable when access_type is ObjectRead or ObjectReadWithoutList.

    THE ONE THING IT IS NOT: an origin ROOT. `/n/<ns>/b/<bucket>/o` is a path
    prefix, so any consumer that builds absolute-from-root URLs ("/web/x/y.js")
    will resolve them against `https://objectstorage.<region>.oraclecloud.com/`
    and miss the bucket entirely. See the hyperswitch-sdk-assets unit in
    hyperswitch-infra for the one real consumer where this matters.
  EOT
  value       = local.base_url
}

output "is_publicly_readable" {
  description = "True when anonymous callers can GET objects. Surfaced as its own boolean so a reviewer does not have to know which of the three access_type strings is which."
  value       = contains(["ObjectRead", "ObjectReadWithoutList"], oci_objectstorage_bucket.this.access_type)
}

output "allows_anonymous_listing" {
  description = "True ONLY for access_type = ObjectRead, which additionally permits ListObjects. The narrower ObjectReadWithoutList does not."
  value       = oci_objectstorage_bucket.this.access_type == "ObjectRead"
}

output "object_names" {
  description = "Names of objects this module uploaded, if any."
  value       = keys(oci_objectstorage_object.this)
}
