# hyperswitch - KMS, object storage, email, secrets grants and policy
# statements for the main workload.

variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment this module's resources live in, and the default
    `in compartment id <ocid>` location term of every statement it renders.

    Must be the same compartment the shared `oke-workload-identity` policy is
    attached to, or a descendant of it: a policy governs only its own
    compartment and that compartment's descendants, so a grant naming a
    compartment outside that subtree is unreachable from where the policy is
    attached.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID."
  }
}

variable "environment" {
  description = "Short environment name (dev / integ / sandbox / prod). Used in resource naming."
  type        = string
}

variable "project_name" {
  description = "Project name prefix used in resource naming."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Echoed back as an output; no resource here is region-argument-driven (the provider's region is)."
  type        = string
}

variable "cluster_ids" {
  description = <<-EOT
    OCIDs of every OKE cluster whose workloads these grants authorise. A LIST
    from day one even though dev has exactly one cluster: N clusters means N
    statements, not N policy objects, and `request.principal.cluster_id` is one
    of the four conditions that make up the entire security boundary.

    Replaces the AWS module's `cluster_service_accounts` map keys. The AWS
    map's VALUES (the service-account list) become `service_accounts` below.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID. An empty list renders no statements at all, which silently grants nothing - and looks identical to a correctly-configured module."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "service_accounts" {
  description = <<-EOT
    The (namespace, name) pairs this module's grants authorise.

    Defaults to the single pair the real AWS catalog unit manages today:
    `hyperswitch/hyperswitch-router-role`. `uas/uas-role` belongs to the
    separate `uas` module in the `hyperswitch-infra` repo, not here, and
    `hyperswitch-auth-proxy` likewise.

    Every grant is rendered across `service_accounts x cluster_ids`, so adding
    a pair here multiplies this module's statement contribution by the number
    of grants. Watch the 50-per-policy-object budget.
  EOT
  type = list(object({
    namespace = string
    name      = string
  }))
  default = [{ namespace = "hyperswitch", name = "hyperswitch-router-role" }]

  validation {
    condition     = length(var.service_accounts) > 0
    error_message = "service_accounts must contain at least one (namespace, name) pair."
  }

  validation {
    condition     = alltrue([for s in var.service_accounts : length(trimspace(s.namespace)) > 0 && length(trimspace(s.name)) > 0])
    error_message = "service_accounts[*].namespace and .name must be non-empty. A blank value renders a condition that matches nothing, or is dropped entirely - which widens the grant."
  }
}

variable "kms" {
  description = <<-EOT
    Customer-managed encryption key. AWS: `module.kms`
    (`terraform-aws-modules/kms/aws` 4.2.0) + `aws_iam_policy.kms_policy`.

    `use_virtual_private_vault` is NEW and has no AWS counterpart. AWS
    multi-region keys are ordinary objects on the shared KMS service - a
    boolean. OCI's `oci_kms_vault_replication` "only supports virtual private
    vault", which is the dedicated-HSM-partition tier: a standing cost, and
    `vault_type` is NOT updatable in place. So the DR posture has to be chosen
    before the first apply, per environment, not patched in later.

    Deliberately absent, because OCI has no argument to map them onto:
    `aliases`, `key_administrators`, `key_users`, `key_service_users`, and
    every other key-policy-document field. OCI key access is entirely
    policy-STATEMENT driven - there is no key-policy argument on `oci_kms_key`
    at all - so those grants come out of `policy_statements` instead.

    Set `existing_key_id` to consume a key owned elsewhere instead of creating
    one; `create` and `existing_key_id` are mutually exclusive.
  EOT
  type = object({
    create                    = optional(bool, true)
    existing_key_id           = optional(string)
    vault_display_name        = optional(string)
    key_display_name          = optional(string)
    use_virtual_private_vault = optional(bool, false)
    key_algorithm             = optional(string, "AES")
    key_length                = optional(number, 32)
    protection_mode           = optional(string, "HSM")
    enable_key_rotation       = optional(bool, true)
    rotation_interval_in_days = optional(number, 365)
    create_replica            = optional(bool, false)
    replica_region            = optional(string)
  })
  default = {}

  validation {
    condition     = contains([60, 365], var.kms.rotation_interval_in_days) || (var.kms.rotation_interval_in_days >= 60 && var.kms.rotation_interval_in_days <= 365)
    error_message = "kms.rotation_interval_in_days must be between 60 and 365 (OCI's documented range). AWS's default annual rotation maps to 365."
  }

  validation {
    condition     = contains(["HSM", "SOFTWARE"], var.kms.protection_mode)
    error_message = "kms.protection_mode must be HSM or SOFTWARE."
  }
}

variable "dashboard_themes_bucket" {
  description = <<-EOT
    Dashboard-themes bucket. AWS: `module.s3_dashboard_themes`.

    `force_destroy` is DROPPED, not renamed: `oci_objectstorage_bucket` has no
    such argument in provider 9.0.0, and a bucket containing objects cannot be
    deleted by the resource at all - the API rejects it. Empty it out of band
    first (`oci os object bulk-delete`). Same finding as vector.md section 4.3.
  EOT
  type = object({
    create             = optional(bool, true)
    bucket_name        = optional(string)
    versioning_enabled = optional(bool, true)
    storage_tier       = optional(string, "Standard")
  })
  default = {}
}

variable "file_uploads_bucket" {
  description = "File-uploads bucket. AWS: `module.s3_file_uploads`. Same shape and same `force_destroy` absence as dashboard_themes_bucket."
  type = object({
    create             = optional(bool, true)
    bucket_name        = optional(string)
    versioning_enabled = optional(bool, true)
    storage_tier       = optional(string, "Standard")
  })
  default = {}
}

variable "email" {
  description = <<-EOT
    Transactional email. Replaces the AWS `ses` object (`enabled`, `role_arn`)
    ENTIRELY - there is no role to assume, there is a domain to verify.

    THE CROSS-ACCOUNT HOP IS DELIBERATELY NOT PORTED. On AWS this feature
    carries an `sts:AssumeRole` into account 576373346466 because SES sending
    was centralised operationally in a separate account. That is an AWS
    organisational choice, not a functional requirement, and OCI documents no
    cross-tenancy "borrow someone else's verified sender" pattern anywhere in
    the Email service.

    `use_existing_domain_id` / `use_existing_sender_id` exist because
    `decision-engine` sends from the SAME AWS SES role today: ONE shared verified
    domain across both modules avoids two independent DNS verifications
    for the same logical sender, but that sharing decision is not yet
    reviewed, so both paths are buildable from here.

    See `smtp_credential_vault_secret_id` for the identity fallback.
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
    using "standard OCI SDK authentication mechanisms", but the specific list
    Oracle gives is "API key of an Identity user, instance principal, or
    resource principal" - WORKLOAD IDENTITY IS NOT NAMED, and is not explicitly
    excluded either. SMTP submission uses `oci_identity_smtp_credential`, which
    is bound to an IAM USER, capped at two per user, and is exactly the
    long-lived static credential that is rejected by the identity model.

    This module builds the WORKLOAD IDENTITY path as primary and unconditional:
    when `email.enabled` is true it emits a `use email-family` grant conditioned
    on the four `request.principal.*` terms, and nothing else. It does NOT
    create an `oci_identity_smtp_credential`, does not create an
    `oci_identity_user`, and never handles a credential value - because doing so
    silently would make the fallback the default and nobody would ever find out
    the primary path was untested.

    If, and only if, hyperswitch.md section 9 Q1 resolves AGAINST workload
    identity on the HTTPS path, set this to the OCID of a Vault secret an
    operator created out of band. This module then surfaces it as an output for
    an ExternalSecret to project into the pod, and flips
    `email_uses_static_credential_fallback` to true so the regression is visible
    in the plan and in every consumer's outputs rather than buried in a chart.
    Nothing here reads or stores the secret's value.
  EOT
  type        = string
  default     = null
}

variable "secrets" {
  description = <<-EOT
    Read app secrets from OCI Vault. AWS: `aws_iam_policy.secrets_manager_policy`
    (`secretsmanager:GetSecretValue` + `DescribeSecret`, scoped to
    `<env>/hyperswitch-*`).

    Two OCI grants, not one, and the split is not cosmetic:
      GetSecretValue -> `read secret-bundles` (the VALUE)
      DescribeSecret -> `read secrets`        (the METADATA)
    `read secrets` alone CANNOT read a secret.

    `secret_ids` is empty by default, which renders both grants
    compartment-scoped - the same breadth as AWS's `secret:*` ARN wildcard,
    expressed as a compartment instead. Supplying OCIDs narrows to
    `target.secret.id='<ocid>'` per secret, which is least-privilege but costs
    2 statements PER SECRET PER SERVICE ACCOUNT PER CLUSTER against a hard
    50-statement per-policy-object budget. Narrow deliberately, not reflexively.
  EOT
  type = object({
    enabled    = optional(bool, true)
    secret_ids = optional(list(string), [])
  })
  default = {}
}

variable "functions" {
  description = <<-EOT
    Invoke the report-generator functions. AWS: `aws_iam_policy.lambda_policy`.

    DELIBERATELY NARROWED. AWS grants `lambda:InvokeFunction` AND `lambda:*` on
    five named ARNs, plus account-wide `ListFunctions`,
    `CreateEventSourceMapping`, `ListCodeSigningConfigs` and friends. OCI
    Functions' policy model has no analogue for event-source-mappings or
    code-signing-configs as IAM-nameable sub-resources, and the five function
    names describe scheduled report generation this workload INVOKES, not
    functions it creates, signs or wires event sources for. So the port grants
    `use functions-family` scoped to a compartment and does not attempt to
    reproduce the account-wide management actions - a least-privilege
    improvement.

    RESIDUAL RISK, unresolved: if some out-of-band process (a deploy pipeline
    assuming the same role) really does use those account-wide actions,
    narrowing breaks it silently. Ask the
    report-generation pipeline's owner before cutover.

    `compartment_id` defaults to this module's own compartment. AWS's
    `function_arns` list has no counterpart: there is no per-function condition
    variable documented for functions-family.
  EOT
  type = object({
    enabled        = optional(bool, true)
    compartment_id = optional(string)
  })
  default = {}
}

variable "extra_statements" {
  description = <<-EOT
    Raw policy statement strings appended to `policy_statements`.

    Replaces BOTH `additional_iam_policies` (a map of JSON documents) AND
    `assume_role` - OCI has no role object
    and no assume operation, so "this workload may additionally assume role X"
    has nothing to port onto; a same-tenancy equivalent is a second parallel
    statement naming the second principal, which is what this list is for.

    Write them PRE-NORMALISED (no spaces around `=`, no space after `,`, none
    inside `{}`) and use `in compartment id <ocid>`, never
    `in compartment <name>` - the API lowercases compartment names in statement
    text and produces a perpetual diff. `oke-workload-identity` re-normalises
    and re-validates everything contributed to it at plan time, but a statement
    that arrives already correct is one fewer thing to reason about.
  EOT
  type        = list(string)
  default     = []
}

variable "freeform_tags" {
  description = "Freeform tags merged onto every resource. The AWS `tags` analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags, keyed \"namespace.key\". Passed through untouched; this module owns no tag namespace."
  type        = map(string)
  default     = {}
}
