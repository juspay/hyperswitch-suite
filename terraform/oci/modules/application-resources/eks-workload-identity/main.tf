resource "oci_identity_domains_identity_propagation_trust" "eks" {
  idcs_endpoint = var.identity_domain_url
  name          = var.trust_name
  issuer        = var.eks_oidc_issuer
  type          = "JWT"
  active        = var.active

  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:IdentityPropagationTrust"
  ]

  # subject_type must be "Resource" for the RPST flow (required-at-API even
  # though the provider schema marks it optional).
  subject_type = "Resource"

  # The external workload that acts as the impersonating resource principal.
  # MUST match the token-exchange res_type (or the JWT res_type claim) or the
  # exchange is rejected.
  impersonating_resource = var.impersonating_resource

  # For AWS, the Identity cloud provider service identifier is the AWS account
  # ID.
  account_id = var.aws_account_id

  # OCI validates the incoming JWT signature against this JWKS endpoint
  # (EKS OIDC discovery JWKS) or the static public_certificate.
  public_key_endpoint = var.public_key_endpoint
  public_certificate  = var.public_certificate

  # Optional OAuth client ID(s) authorized to perform the token exchange. If
  # omitted and the deploy workload authenticates via Instance/Service
  # Principal signed exchange, a {GET_RPST} dynamic-group grant is required.
  oauth_clients = var.legacy_identity_domain_client == null ? [] : [var.legacy_identity_domain_client]

  # Claims that MUST match on the incoming JWT or the exchange is rejected.
  # For AWS, client_claim_name is 'aud' or 'client_id'; client_claim_values
  # pins the exact projected-token audience.
  client_claim_name   = "aud"
  client_claim_values = [var.token_audience]

  dynamic "claim_validations" {
    for_each = var.claim_validations
    content {
      name  = claim_validations.value.name
      value = claim_validations.value.value
    }
  }

  # Claim names carried into the RPST as var_ext_<name>, surfaceable in policy
  # as request.principal.ext_<name>. list(string); propagate "ext_iss" to pin
  # the EKS issuer in every grant.
  claim_propagations = var.claim_propagations
}