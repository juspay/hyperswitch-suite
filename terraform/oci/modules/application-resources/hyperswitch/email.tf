# =============================================================================
# Email Delivery (check sheet feature 6, SUBSTITUTE - section 4.2)
# =============================================================================
# AWS: `aws_iam_policy.ses_policy` - `sts:AssumeRole` into a SEPARATE, centrally
# managed AWS account (576373346466) plus `ses:SendEmail`/`SendTemplatedEmail`/
# `SendRawEmail`/`ListTemplates`/`ListVerifiedEmailAddresses` against a verified
# sender identity that already exists over there.
#
# THREE THINGS CHANGE, AND ONLY ONE OF THEM IS A LOSS.
#
# 1. The cross-account hop disappears. Not because it is hard, but because
#    nothing on OCI reproduces it: there is no documented cross-tenancy
#    "borrow someone else's verified sender" pattern in the Email service at
#    all. The hop exists on AWS because SES sending was centralised
#    operationally in a second account - an organisational choice, not a
#    functional requirement. It is dropped, and it is one fewer moving part.
#
# 2. A verified domain becomes a real, DNS-verified object in THIS tenancy
#    rather than an implicit per-region identity. `oci_email_email_domain` +
#    `oci_email_sender` are created here, and the domain needs DKIM/SPF DNS
#    records published before mail actually flows. That is a new out-of-band
#    step with no AWS counterpart in this module.
#
# 3. The identity path is UNRESOLVED, and that is the loss. See the block on
#    `smtp_credential_vault_secret_id` in variables.tf and the local below.
# =============================================================================

resource "oci_email_email_domain" "this" {
  count = local.email_create ? 1 : 0

  compartment_id = var.compartment_id
  name           = var.email.domain_name

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_email_sender" "this" {
  count = local.email_create ? 1 : 0

  compartment_id = var.compartment_id
  email_address  = var.email.sender_address

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # The sender must sit under the verified domain. Ordering is expressed as a
  # real dependency rather than left to Terraform's graph inference, because the
  # sender's address is a plain string and carries no reference to the domain
  # resource.
  depends_on = [oci_email_email_domain.this]

  lifecycle {
    precondition {
      condition     = var.email.domain_name == null || endswith(lower(var.email.sender_address), "@${lower(var.email.domain_name)}")
      error_message = "email.sender_address must be an address under email.domain_name. OCI approved senders live under a verified domain in the same tenancy; there is no cross-domain or cross-tenancy sender."
    }
  }
}

# -----------------------------------------------------------------------------
# THE IDENTITY QUESTION, RESOLVED THE ONLY WAY IT HONESTLY CAN BE RIGHT NOW.
#
# What is decided: the workload-identity path is PRIMARY and unconditional. When
# `email.enabled` is true, locals.tf emits `use email-family` conditioned on the
# four `request.principal.*` terms, and this module creates no user, no API key
# and no `oci_identity_smtp_credential`.
#
# What is NOT decided, and is not decidable from documentation: whether OCI
# Email Delivery's HTTPS `SubmitEmail` endpoint actually accepts a
# workload-identity-authenticated request. Oracle's HTTPS-submission page names
# "API key of an Identity user, instance principal, or resource principal" and
# does not name workload identity - nor does it exclude it. The email policy
# reference ties `use approved-senders`/`use email-family` to the `SmtpSend`
# operation and does not list `SubmitEmail` in its verb tables at all. Check
# sheet section 9 Q1/Q2; answerable in an afternoon with one verified domain,
# one approved sender, one policy and one HTTPS send from a pod.
#
# WHY THERE IS NO SILENT FALLBACK HERE. The available fallback is an SMTP
# credential: bound to an IAM USER, capped at two per user, viewable once,
# rotated by hand - exactly the long-lived static credential
# identity-model.md section 3.1 rejects outright. If this module minted one
# "just in case", it would work on the first apply, nobody would ever exercise
# the workload-identity path, and the exception would become the architecture
# by default. So the fallback is opt-in, operator-provisioned out of band, and
# passed in as a Vault secret OCID only - this module never sees a credential
# value - and taking it flips a boolean that appears in this module's outputs
# and therefore in every consumer's plan.
# -----------------------------------------------------------------------------
locals {
  email_uses_static_credential_fallback = var.smtp_credential_vault_secret_id != null
}
