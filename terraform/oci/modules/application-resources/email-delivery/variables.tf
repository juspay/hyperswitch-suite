variable "compartment_id" {
  type        = string
  description = "OCI compartment OCID where the domain and approved sender are created."
}

variable "defined_tags" {
  type        = map(string)
  description = "Defined tags applied to the domain and sender."
  default     = {}
}

variable "freeform_tags" {
  type        = map(string)
  description = <<-EOT
    Freeform tags applied to the domain and sender. The caller's own
    environment/project/component tags are expected to be merged in before
    this module is called; OCI does not auto-attach them here.
  EOT
  default     = {}
}

variable "region" {
  type        = string
  description = "OCI region the Email Delivery domain/sender live in. Echoed for consumer stack values."
}

variable "email" {
  description = <<-EOT
    Transactional email. Replaces the AWS `ses` object (`enabled`, `role_arn`)
    ENTIRELY - there is no role to assume, there is a domain to verify.

    THE CROSS-ACCOUNT HOP IS DELIBERATELY NOT PORTED. On AWS this feature
    carries an `sts:AssumeRole` into a separate account because SES sending was
    centralised there. That is an organisational choice, not a functional
    requirement, and OCI documents no cross-tenancy "borrow someone else's
    verified sender" pattern; approved senders live under a verified domain in
    this tenancy.

    `use_existing_domain_id` / `use_existing_sender_id` let a second consumer
    (e.g. decision-engine) reuse one verified domain/sender pair shared with
    hyperswitch, avoiding two independent DNS verifications for the same
    logical sender.

    `dkim_enabled` (default false) opt-in creates an `oci_email_dkim` signing
    key for the domain, enabling DKIM signing for DMARC alignment and higher
    deliverability. The CNAME it must be published to is exported as
    `email_dkim_cname_record_value` / `email_dkim_dns_subdomain_name` for the
    DNS owner; until that CNAME is published the DKIM stays in PENDING state
    (sending still works). `dkim_selector` is optional; if omitted, OCI
    auto-generates a globally-unique selector.
  EOT
  type = object({
    enabled                = optional(bool, true)
    create                 = optional(bool, true)
    domain_name            = optional(string)
    sender_address         = optional(string)
    use_existing_domain_id = optional(string)
    use_existing_sender_id = optional(string)
    dkim_enabled           = optional(bool, false)
    dkim_selector          = optional(string)
  })
  default = {}

  validation {
    condition     = !try(var.email.enabled, true) || !try(var.email.create, true) || (try(var.email.domain_name, null) != null && try(var.email.sender_address, null) != null)
    error_message = "email.domain_name and email.sender_address are both required when email.create is true. An OCI approved sender is an explicit object under an explicit, DNS-verified domain - unlike SES, there is no implicit per-region identity to inherit."
  }
}

variable "smtp_credential_vault_secret_id" {
  description = <<-EOT
    OCID of an OCI Vault secret holding an SMTP credential for Email Delivery.
    THE FALLBACK PATH, AND AN ACCEPTED REGRESSION IF USED - read this in full
    before setting it.

    Email Delivery has two send paths. HTTPS `SubmitEmail` is documented as
    using "standard OCI SDK authentication mechanisms" - workload identity is
    NOT named there and is not explicitly excluded either. SMTP submission uses
    `oci_identity_smtp_credential`, which is bound to an IAM user, capped at two
    per user, and is exactly the long-lived static credential that is rejected
    by the identity model.

    This module builds the WORKLOAD IDENTITY path as primary and unconditional.
    Setting this variable is an operator's explicit opt-in to the long-lived
    fallback; it flips `email_uses_static_credential_fallback` so every
    consumer's plan shows the regression. This module never reads or stores the
    credential value.
  EOT
  type        = string
  default     = null
}