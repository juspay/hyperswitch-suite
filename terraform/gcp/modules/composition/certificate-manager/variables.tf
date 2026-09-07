variable "project_id" {
  description = "GCP project ID where certificates are created"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "dns_authorization_type" {
  description = "DNS authorization type: FIXED_RECORD or PER_PROJECT_RECORD"
  type        = string
  default     = "FIXED_RECORD"
}

variable "create_certificate_map" {
  description = "Whether to create a Certificate Manager certificate map + entry per certificate, for attaching to a target proxy via certificate_map"
  type        = bool
  default     = true
}

variable "certificates" {
  description = <<EOT
Map of certificate configurations. Each key represents a certificate name.
Example:
certificates = {
  "api" = {
    domain_name               = "api.dev.hyperswitch.example.com"
    subject_alternative_names = []
    validation_method         = "DNS"
  }
}
EOT
  type = map(object({
    domain_name                    = string
    subject_alternative_names      = optional(list(string), [])
    validation_method              = optional(string, "DNS")
    create_classic_ssl_certificate = optional(bool, false)
    labels                         = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for cert in var.certificates : contains(["DNS"], cert.validation_method)
    ])
    error_message = "validation_method must be 'DNS'; Certificate Manager only supports DNS authorization for Google-managed certificates."
  }
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
