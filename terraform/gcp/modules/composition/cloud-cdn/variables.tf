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
