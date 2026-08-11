variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "certificates" {
  description = <<-EOT
    Map of certificate key -> config. Equivalent of the AWS module's
    `var.certificates` (each entry -> one terraform-aws-modules/acm/aws
    instance). OCI Certificates Management issues certificates from a
    Certificate Authority you manage in OCI (there is no "public CA +
    DNS validation" flow built into the service the way ACM has); the
    common pattern is a private CA (`certificate_authority_id`) or
    importing an externally-issued certificate (`imported_certificate_pem`).
  EOT
  type = map(object({
    common_name               = string
    subject_alternative_names = optional(list(string), [])
    certificate_authority_id  = optional(string)
    imported_certificate_pem  = optional(string)
    imported_cert_chain_pem   = optional(string)
    imported_private_key_pem  = optional(string)
    key_algorithm             = optional(string, "RSA2048")
    validity_not_after        = optional(string)
    tags                      = optional(map(string), {})
  }))
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
