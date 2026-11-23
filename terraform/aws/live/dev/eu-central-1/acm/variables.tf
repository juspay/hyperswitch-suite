variable "environment" {
  description = "Environment name (e.g., dev, integ, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hyperswitch"
}

variable "certificates" {
  description = "Map of ACM certificate configurations"
  type = map(object({
    domain_name                                 = string
    subject_alternative_names                   = optional(list(string), [])
    zone_id                                     = optional(string, null)
    validation_method                           = optional(string, "DNS")
    create_route53_records                      = optional(bool, false)
    validate_certificate                        = optional(bool, false)
    validation_record_fqdns                     = optional(list(string), [])
    zones                                       = optional(map(string), {})
    wait_for_validation                         = optional(bool, false)
    validation_timeout                          = optional(string, null)
    validation_allow_overwrite_records          = optional(bool, false)
    certificate_transparency_logging_preference = optional(bool, true)
    create_route53_records_only                 = optional(bool, false)
    distinct_domain_names                       = optional(list(string), [])
    acm_certificate_domain_validation_options   = optional(any, {})
    key_algorithm                               = optional(string, null)
    export                                      = optional(string, null)
    private_authority_arn                       = optional(string, null)
    tags                                        = optional(map(string), {})
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
