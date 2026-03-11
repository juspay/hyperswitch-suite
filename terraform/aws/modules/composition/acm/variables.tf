# =========================================================================
# REQUIRED VARIABLES
# =========================================================================

variable "environment" {
  description = "Environment name (dev/integ/prod)"
  type        = string
}

# =========================================================================
# OPTIONAL VARIABLES
# =========================================================================

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "certificates" {
  description = <<EOT
Map of ACM certificate configurations. Each key represents a certificate name.
Example:
certificates = {
  "main" = {
    domain_name               = "example.com"
    subject_alternative_names = ["*.example.com"]
    zone_id                   = "Z1234567890ABC"
    validation_method         = "DNS"
    create_route53_records    = true
    validate_certificate      = true
    wait_for_validation       = true
  }
  "api" = {
    domain_name = "api.example.com"
    zone_id     = "Z1234567890ABC"
  }
}
EOT
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

  validation {
    condition = alltrue([
      for cert in var.certificates : contains(["DNS", "EMAIL"], cert.validation_method)
    ])
    error_message = "Validation method must be either 'DNS' or 'EMAIL'."
  }
}
