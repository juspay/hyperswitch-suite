# ONE propagation trust + ONE scoped policy. Per environment, not per app.
# OCI side of the hyperops EKS->OCI cross-cloud pipeline: an EKS workload
# exchanges its projected K8s SA JWT for an RPST at the Identity Domain
# token-exchange endpoint. This module creates that trust on the OCI side.
#
# SECURITY SEMANTICS (do not collapse further):
# * Trust ACCEPTS the EKS OIDC issuer as JWT source and issues an RPST. `issuer`
#   must be the exact EKS issuer URL; impersonating_resource/res_type and
#   client_claim_* pin the audience + impersonated workload so tokens from the
#   wrong cluster or audience are rejected at exchange. The federated principal
#   has NO dynamic group - the grant IS the policy statement:
#   request.principal.type='identityfederateddomainapp' carrying the EKS issuer
#   as ext_iss, scoped by request.principal.{type,domain.id,ext_iss,name,...}.
# * Bootstrap is ONE-SHOT under the existing OCI identity (IAM-Domain-admin
#   action) to CREATE the trust; the deploy workload consumes it via
#   auth="WorkloadIdentityFederation", it never creates this trust.
# * ONE policy object per environment: statements contributed, never one per
#   app (100-object per-tenancy limit, non-updatable `name`). Separate object
#   from oke-workload-identity because request.principal.type cannot be shared.

variable "compartment_id" {
  description = "OCID of the compartment the policy is ATTACHED to. A policy governs only its own compartment and its descendants; attach at or above every resource the federated workload deploys. NOT UPDATABLE once set."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment.* / ocid1.tenancy.*)."
  }
}

variable "identity_domain_url" {
  description = "Identity Domain URL that hosts the trust and issues the RPST (also the token-exchange endpoint host). e.g. https://idcs-<uuid>.identity.oraclecloud.com. Set from the applied identity-domain resource; NOT updatable on the trust in practice - treat as immutable."
  type        = string

  validation {
    condition     = can(regex("^https://", var.identity_domain_url))
    error_message = "identity_domain_url must be an https:// Identity Domain URL."
  }
}

variable "trust_name" {
  description = "Name of the propagation trust. Tenancy-unique and NOT updatable; a change destroys and recreates the trust."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{0,98}[a-z0-9]$", var.trust_name))
    error_message = "trust_name must be lowercase alphanumeric with . _ - separators, 2-100 chars."
  }
}

variable "eks_oidc_issuer" {
  description = "Exact AWS EKS cluster OIDC issuer URL, e.g. https://oidc.eks.ap-south-1.amazonaws.com/id/<id>. MUST match the EKS cluster's actual issuer exactly or token exchange is rejected."
  type        = string

  validation {
    condition     = can(regex("^https://oidc\\.eks\\..*", var.eks_oidc_issuer))
    error_message = "eks_oidc_issuer must be an AWS EKS OIDC issuer URL (https://oidc.eks.<region>.amazonaws.com/id/<id>)."
  }
}

variable "token_audience" {
  description = "The projected Kubernetes service-account token audience. The K8s projected-token volume must set this exact `audience`; OCI validates the JWT `aud`/client claim against `client_claim_values`. Defaults to sts.amazonaws.com because the hyperops infra-switch SA projects only the standard EKS IRSA token (aud=sts.amazonaws.com); a custom audience needs a projectedServiceAccountToken volume on the AWS side."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "legacy_identity_domain_client" {
  description = "Optional OAuth client ID authorized for the token-exchange (RFC 8693) request when the deploy workload authenticates the exchange via an OAuth client. Leave empty to use the credentialless Instance-Principal (IPST) / Service-Principal (SPST) signed exchange client-auth instead, which the self-managed-k8s walkthrough recommends and which requires a {GET_RPST} dynamic-group grant rather than a client secret. `oauth_clients` is optional on the trust; this passes it through."
  type        = string
  default     = null
}

variable "impersonating_resource" {
  description = "The external workload that acts as the impersonating resource principal, e.g. \"eksworkload\". The token-exchange `res_type` (or the JWT's res_type claim) must EXACTLY match this, and `allow_impersonation` is implicitly true. Required to impersonate a resource."
  type        = string
  default     = null
}

variable "aws_account_id" {
  description = "The AWS account ID (12 digits) of the EKS cluster. Used as the trust's `account_id` - the Identity cloud provider service identifier for AWS."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "public_key_endpoint" {
  description = "Optional URL of the JWKS endpoint OCI uses to validate the incoming JWT signature. For EKS this is the cluster OIDC discovery JWKS (https://oidc.eks.<region>.amazonaws.com/id/<id>/.well-known/jwks). Prefer over a static `public_certificate` so key rotation is automatic. One of public_key_endpoint or public_certificate is required."
  type        = string
  default     = null
}

variable "public_certificate" {
  description = "Optional static certificate OCI uses to validate the incoming JWT signature. Prefer `public_key_endpoint` (JWKS) to avoid manual rotation; use this only if the issuer does not expose a JWKS endpoint."
  type        = string
  default     = null

  validation {
    condition     = (var.public_key_endpoint != null) || (var.public_certificate != null)
    error_message = "One of public_key_endpoint or public_certificate is required so OCI can validate the incoming JWT signature."
  }
}

variable "claim_validations" {
  description = "Up to 5 {name, value} claims that MUST all match on the incoming JWT or the token exchange is rejected. Each name is a JWT claim (e.g. \"sub\" = system:serviceaccount:<ns>:<sa>). These are the narrowest pin of who is allowed."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "claim_propagations" {
  description = "Claim names carried into the RPST as var_ext_<name>, surfaceable in policy as request.principal.ext_<name>. list(string). Include \"ext_iss\" so every grant can pin the exact EKS OIDC issuer. RPST is capped at 5 var_* with 2 reserved (var_domain.id, var_name), leaving 3."
  type        = list(string)
  default     = []
}

variable "policy_name" {
  description = "Name of the single federated-workload policy. Tenancy-unique and NOT updatable; a change is a destroy/recreate window in which the federated workload loses access. Environment-scoped, never app- or region-scoped (see oke-workload-identity for the full rationale)."
  type        = string

  validation {
    condition     = length(regexall("(af|ap|ca|eu|il|me|mx|sa|uk|us)-[a-z]+-[0-9]", var.policy_name)) == 0
    error_message = "policy_name must not contain an OCI region identifier. Policy names are tenancy-unique and NOT updatable; identity objects are environment-scoped, never region-scoped."
  }
}

variable "policy_description" {
  description = "Description of the federated-workload policy."
  type        = string
  default     = null
}

variable "workload_grants" {
  description = "Structured grants rendered into policy statements scoped to the federated EKS service account. Each grant expands into one statement pinned to request.principal.type='identityfederateddomainapp', request.principal.domain.id, request.principal.ext_iss (the EKS issuer, via claim_propagations['ext_iss']), and request.principal.name (the K8s SA subject). verb one of inspect/read/use/manage."
  type = list(object({
    namespace       = string
    service_account = string
    verb            = string
    resource_type   = string
    compartment_id  = optional(string)
    condition       = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for g in var.workload_grants : contains(["inspect", "read", "use", "manage"], lower(g.verb))])
    error_message = "workload_grants[*].verb must be one of inspect, read, use, manage."
  }

  validation {
    condition     = alltrue([for g in var.workload_grants : length(trimspace(g.namespace)) > 0 && length(trimspace(g.service_account)) > 0])
    error_message = "workload_grants[*].namespace and .service_account must be non-empty."
  }

  validation {
    condition     = alltrue([for g in var.workload_grants : length(trimspace(g.resource_type)) > 0])
    error_message = "workload_grants[*].resource_type must be non-empty."
  }
}

variable "statements" {
  description = "Pre-composed policy STATEMENTS contributed by callers, concatenated into this module's single policy object. Escape hatch for grants whose principal is not a federated K8s workload (e.g. the RPST dynamic-group {GET_RPST} bootstrap). Empty by default."
  type        = list(string)
  default     = []
}

variable "max_statements" {
  description = "Plan-time cap on statements in this one policy object. Defaults to 50 (OCI's hard per-policy-object limit)."
  type        = number
  default     = 50

  validation {
    condition     = var.max_statements > 0 && var.max_statements <= 50
    error_message = "max_statements must be between 1 and 50."
  }
}

variable "active" {
  description = "Whether the propagation trust is active. Set true to enable the trust (and the token exchange). Defaults to false so the trust can be created but left dormant until the EKS OIDC issuer / audience are verified."
  type        = bool
  default     = true
}

variable "freeform_tags" {
  description = "Free-form tags applied to both the trust and the policy."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags applied to the trust and policy, keyed \"namespace.key\"."
  type        = map(string)
  default     = {}
}