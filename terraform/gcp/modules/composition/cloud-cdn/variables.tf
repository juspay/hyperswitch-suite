variable "project_id" {
  description = "GCP project ID where CDN resources are created"
  type        = string
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "name_override" {
  description = "Logical name for this distribution (e.g. 'assets', 'dashboard')"
  type        = string
  default     = "default"
}

variable "backend_buckets" {
  description = "Map of GCS-origin backends to create, keyed by logical name"
  type = map(object({
    bucket_name       = string
    enable_cdn        = optional(bool, true)
    cache_mode        = optional(string, "CACHE_ALL_STATIC")
    default_ttl       = optional(number, 3600)
    client_ttl        = optional(number, 3600)
    max_ttl           = optional(number, 86400)
    negative_caching  = optional(bool, true)
    serve_while_stale = optional(number, 86400)
  }))
  default = {}
}

variable "ssl" {
  description = "Whether to provision an HTTPS listener"
  type        = bool
  default     = true
}

variable "http_redirect_to_https" {
  description = "Whether the HTTP listener redirects to HTTPS instead of serving the same url_map"
  type        = bool
  default     = true
}

variable "managed_ssl_certificate_domains" {
  description = "List of domains for the Google-managed SSL certificate, used when ssl = true and certificate_map is null"
  type        = list(string)
  default     = []
}

variable "certificate_map" {
  description = "Certificate Manager certificate map ID to attach instead of a classic managed SSL certificate (see composition/certificate-manager)"
  type        = string
  default     = null
}

variable "enable_logging" {
  description = "Whether to create a GCS bucket for CDN access logs"
  type        = bool
  default     = true
}

variable "log_bucket_location" {
  description = "Location for the CDN log bucket"
  type        = string
  default     = "US"
}

variable "log_retention_days" {
  description = "Number of days to retain CDN log objects before deletion"
  type        = number
  default     = 90
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "bucket_name_suffix" {
  description = "Suffix appended to this module's DEFAULT bucket names (<env>-<project>-<component>-<role>-<suffix>). GCS bucket names are global, so the same name in two projects collides; the suffix is what lets several environments coexist. null = the first 6 hex characters of sha256(project_id): stable across applies and unique per project. \"\" = no suffix (the names this module produced before the suffix existed - set it on existing deployments to avoid replacing their buckets). Any other value is used as given (1-16 lowercase letters, digits and hyphens). The readable prefix is trimmed so the full name stays within the 63-character GCS limit; the role and the suffix are never trimmed."
  type        = string
  default     = null

  validation {
    condition     = var.bucket_name_suffix == null || can(regex("^([a-z0-9]([a-z0-9-]{0,14}[a-z0-9])?)?$", var.bucket_name_suffix))
    error_message = "bucket_name_suffix must be null, an empty string, or 1-16 characters of lowercase letters, digits and hyphens that starts and ends with a letter or digit."
  }
}
