# =============================================================================
# Identity / naming
# =============================================================================

variable "compartment_id" {
  description = "OCID of the compartment that holds the certificates and, if created here, the root CA. OCI's analogue of the GCP module's project_id; the compartment layout itself is owned by docs/multi-cloud-parity/oci/identity-model.md, this module only consumes the id it is given."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment (or root tenancy) OCID, e.g. ocid1.compartment.oc1..aaaa..."
  }
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod). Used for naming and freeform tags."
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and freeform tags."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "Region identifier (e.g. ap-mumbai-1), used for freeform tags only. Placement is decided by the provider's own region."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Extra freeform tags merged onto every resource. Replaces the AWS module's `tags`; OCI freeform tags are string-to-string only."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Certificates
# =============================================================================

variable "certificates" {
  description = <<-EOT
    Map of logical certificate name to its configuration. Keyed exactly like
    the AWS module's `certificates` map so the two are readable side by side
    (`internal-alb`, `envoy-alb`, ...).

    Structurally different from AWS's in two ways, both forced by the target
    cloud, both recorded in docs/multi-cloud-parity/oci/modules/acm.md:

      1. All DNS/validation plumbing is GONE. AWS carries `zone_id`,
         `create_route53_records` and `validation_record_fqdns` because ACM
         proves domain ownership via a DNS-01-style challenge. OCI has no
         public issuance path, so there is no ownership proof to automate:
         a private-CA certificate needs none (you already own the
         compartment), and an IMPORTED certificate's challenge - if the
         external ACME client used one - was satisfied outside Terraform
         entirely. This module therefore has NO dependency on the `dns`
         module, unlike the GCP `certificate-manager` precedent which must
         publish dns_authorization_records for `cloud-dns` to carry.

      2. An issuer axis is NEW. Each entry must declare `config_type` and,
         for the public-facing case, `trust_domain = "public"`.

    `trust_domain` is not cosmetic. acm.md section 4 names it as the residual
    risk with the largest blast radius on this whole port: shipping a
    private-CA certificate on the internet-facing listener is a hard TLS
    failure for every external merchant, not a warning banner. The validation
    below makes that combination un-applyable.
  EOT

  type = map(object({
    description = optional(string)

    # ISSUED_BY_INTERNAL_CA | MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA | IMPORTED
    config_type = string

    # "public"   - served to clients outside the tenancy. MUST be IMPORTED.
    # "internal" - served only to clients the platform configures to trust
    #              the private CA (service mesh, SSO, internal ALB equivalent).
    trust_domain = optional(string, "internal")

    # ---- ISSUED_BY_INTERNAL_CA ------------------------------------------
    common_name = optional(string)
    # type is "DNS" or "IP". Wildcards ("*.internal.example.net") are legal
    # here - the SAN mechanism is generic X.509 and survives the port intact
    # (acm.md feature 3, FULL) - but a wildcard private-CA certificate is
    # still not publicly trusted.
    subject_alternative_names = optional(list(object({
      type  = string
      value = string
    })), [])
    issuer_certificate_authority_id = optional(string)
    certificate_profile_type        = optional(string, "TLS_SERVER_OR_CLIENT")
    key_algorithm                   = optional(string, "RSA2048")
    signature_algorithm             = optional(string, "SHA256_WITH_RSA")
    validity_not_after              = optional(string)
    validity_not_before             = optional(string)

    # ---- MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA -----------------------
    csr_pem = optional(string)

    # ---- IMPORTED --------------------------------------------------------
    # PEM material produced outside this module. Pass it in from a secret
    # store; do not commit it. Marked sensitive on the variable as a whole.
    certificate_pem            = optional(string)
    cert_chain_pem             = optional(string)
    private_key_pem            = optional(string)
    private_key_pem_passphrase = optional(string)

    # ---- Renewal (CA-issued only; acm.md feature 4, PARTIAL) -------------
    # ISO 8601 durations, e.g. renewal_interval = "P30D",
    # advance_renewal_period = "P7D". Oracle renews only certificates Oracle
    # issued; there is no rotation hook on IMPORTED at all.
    renewal_interval       = optional(string)
    advance_renewal_period = optional(string)

    version_name = optional(string)
  }))

  default = {}

  # NOT marked sensitive at the variable level, deliberately: a sensitive value
  # cannot be used as a for_each argument, and this map's KEYS are the resource
  # addresses. The two attributes that actually carry secret material -
  # private_key_pem and private_key_pem_passphrase - are marked sensitive by
  # the oracle/oci provider schema itself, so they are redacted from plan
  # output and from any output derived from them regardless. Supply them from a
  # secret store (an OCI Vault secret read by the unit), never from a committed
  # tfvars file.

  validation {
    condition = alltrue([
      for k, c in var.certificates : contains(
        ["ISSUED_BY_INTERNAL_CA", "MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA", "IMPORTED"],
        c.config_type
      )
    ])
    error_message = "certificates[*].config_type must be one of ISSUED_BY_INTERNAL_CA, MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA, IMPORTED. There is no publicly-issued option on OCI - see docs/multi-cloud-parity/oci/modules/acm.md section 4."
  }

  validation {
    condition     = alltrue([for k, c in var.certificates : contains(["public", "internal"], c.trust_domain)])
    error_message = "certificates[*].trust_domain must be \"public\" or \"internal\"."
  }

  # The guard rail acm.md section 4 asks for, expressed as code rather than as
  # a paragraph nobody reads at 2am.
  validation {
    condition = alltrue([
      for k, c in var.certificates : c.config_type == "IMPORTED"
      if c.trust_domain == "public"
    ])
    error_message = "A certificate with trust_domain = \"public\" must use config_type = \"IMPORTED\". OCI cannot issue a publicly-trusted certificate: config_type accepts only ISSUED_BY_INTERNAL_CA, MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA and IMPORTED, all of which chain to a private CA. Obtain the PEM from an ACME client or a public CA and import it."
  }

  validation {
    condition = alltrue([
      for k, c in var.certificates : c.common_name != null
      if c.config_type == "ISSUED_BY_INTERNAL_CA"
    ])
    error_message = "certificates[*].common_name is required when config_type = ISSUED_BY_INTERNAL_CA (the provider's certificate_config.subject block requires it)."
  }

  validation {
    condition = alltrue([
      for k, c in var.certificates : c.certificate_pem != null && c.private_key_pem != null
      if c.config_type == "IMPORTED"
    ])
    error_message = "certificates[*].certificate_pem and private_key_pem are required when config_type = IMPORTED."
  }

  validation {
    condition = alltrue([
      for k, c in var.certificates : c.csr_pem != null
      if c.config_type == "MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA"
    ])
    error_message = "certificates[*].csr_pem is required when config_type = MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA."
  }

  # Fail loudly rather than silently dropping the rule: an operator who sets
  # renewal_interval on an IMPORTED certificate believes renewal is handled.
  validation {
    condition = alltrue([
      for k, c in var.certificates : c.renewal_interval == null && c.advance_renewal_period == null
      if c.config_type == "IMPORTED"
    ])
    error_message = "certificates[*].renewal_interval / advance_renewal_period cannot be set when config_type = IMPORTED. Oracle has no issuer relationship to renew against, so certificate_rules has no effect on an imported certificate. Renewal for imported certificates is a self-managed automation - see docs/multi-cloud-parity/oci/modules/acm.md gap on feature 4."
  }
}

# =============================================================================
# Root certificate authority
# =============================================================================
# NEW SURFACE, not a port. Neither the AWS nor the GCP module owns a CA: ACM
# takes `private_authority_arn` as a reference to a CA somebody else made, and
# GCP's certificate-manager has no CA concept at all. On OCI a private CA is
# the ONLY way to get a certificate Oracle issues, so something has to own one.
#
# Both shapes are supported and neither is imposed:
#   create_root_ca = true   -> this module owns a root CA (small footprints)
#   default_issuer_ca_id    -> a shared, separately-owned CA is referenced
# acm.md oracle-gate item 2 is exactly this choice; it is left open here on
# purpose rather than decided by a default.
# =============================================================================

variable "create_root_ca" {
  description = "Create a root certificate authority in this module. Leave false and set default_issuer_ca_id when the platform stands up one shared CA elsewhere. Oracle-gate item 2 in docs/multi-cloud-parity/oci/modules/acm.md - not yet consulted, so neither shape is the default-by-fiat."
  type        = bool
  default     = false
}

variable "default_issuer_ca_id" {
  description = "OCID of an existing certificate authority used as the issuer for every ISSUED_BY_INTERNAL_CA certificate that does not name its own. Mutually exclusive with create_root_ca. Closest analogue of the AWS module's private_authority_arn (unset on both live AWS certificates today)."
  type        = string
  default     = null
}

variable "root_ca_name" {
  description = "Display name of the root CA. Defaults to <project>-<env>-root-ca."
  type        = string
  default     = null
}

variable "root_ca_common_name" {
  description = "Subject common name of the root CA, e.g. \"Hyperswitch Dev Root CA\". Required when create_root_ca = true."
  type        = string
  default     = null
}

variable "root_ca_kms_key_id" {
  description = "OCID of the Vault (KMS) asymmetric key that backs the root CA's private key. REQUIRED by oci_certificates_management_certificate_authority - there is no Oracle-managed-key shortcut, so a Vault must exist before any CA can be created. This is a real prerequisite the AWS module never had; acm.md open question 3 asks whether Vault is available in ap-mumbai-1."
  type        = string
  default     = null
}

variable "root_ca_signing_algorithm" {
  description = "Signing algorithm for the root CA."
  type        = string
  default     = "SHA256_WITH_RSA"
}

variable "root_ca_validity_not_after" {
  description = "RFC3339 timestamp the root CA expires at, e.g. \"2036-01-01T00:00:00Z\". Required when create_root_ca = true - the provider's validity block requires it and offers no default."
  type        = string
  default     = null
}

variable "root_ca_max_validity_duration" {
  description = "ISO 8601 cap on the validity of any leaf certificate this CA issues, e.g. \"P365D\". Richer than anything ACM exposes; null leaves Oracle's default in place."
  type        = string
  default     = null
}

variable "root_ca_path_length_constraint" {
  description = "Maximum depth of subordinate CAs beneath this root. 0 forbids subordinate CAs entirely. Null leaves Oracle's default in place. No AWS counterpart in this module."
  type        = number
  default     = null
}

variable "root_ca_crl_object_storage" {
  description = "Publish this CA's certificate revocation list to an Object Storage bucket. Null disables CRL publication. No AWS counterpart in this module; OCI requires an explicit target if a CRL is wanted at all."
  type = object({
    bucket_name           = string
    namespace             = optional(string)
    object_name_format    = string
    custom_formatted_urls = optional(list(string), [])
  })
  default = null
}

variable "certificate_create_timeout" {
  description = "Terraform resource timeout for certificate create/update. The SUBSTITUTE for AWS's wait_for_validation / validation_timeout pair (acm.md feature 10) - OCI has no validation step, so a generic timeout is the only lifecycle control available. 20m is the provider default."
  type        = string
  default     = "20m"
}
