# =========================================================================
# LOCALS
# =========================================================================
locals {
  common_tags = merge(
    {
      "Environment" = var.environment
      "Project"     = var.project_name
      "Component"   = "acm"
      "ManagedBy"   = "terraform"
    },
    var.tags
  )
}

# =========================================================================
# ACM CERTIFICATES
# =========================================================================
module "certificate" {
  source  = "terraform-aws-modules/acm/aws"
  version = "6.3.0"

  for_each = var.certificates

  domain_name = each.value.domain_name

  subject_alternative_names = each.value.subject_alternative_names

  zone_id = each.value.zone_id

  validation_method = each.value.validation_method

  create_route53_records  = each.value.create_route53_records
  validate_certificate    = each.value.validate_certificate
  validation_record_fqdns = each.value.validation_record_fqdns
  zones                   = each.value.zones

  create_route53_records_only               = each.value.create_route53_records_only
  distinct_domain_names                     = each.value.distinct_domain_names
  acm_certificate_domain_validation_options = each.value.acm_certificate_domain_validation_options

  wait_for_validation                = each.value.wait_for_validation
  validation_timeout                 = each.value.validation_timeout
  validation_allow_overwrite_records = each.value.validation_allow_overwrite_records

  certificate_transparency_logging_preference = each.value.certificate_transparency_logging_preference

  key_algorithm         = each.value.key_algorithm
  export                = each.value.export
  private_authority_arn = each.value.private_authority_arn

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name = "${var.environment}-${var.project_name}-${each.key}-cert"
    }
  )
}
