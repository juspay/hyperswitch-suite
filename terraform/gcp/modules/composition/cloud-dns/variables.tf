variable "project_id" {
  description = "GCP project ID where the zone is created"
  type        = string
}

variable "project_name" {
  description = "Project name used for labeling resources"
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "zone_name" {
  description = "Name of the Cloud DNS managed zone (DNS-safe identifier, not the domain itself)"
  type        = string
}

variable "domain" {
  description = "The DNS domain of this zone, e.g. 'dev.hyperswitch.example.com.' (trailing dot required)"
  type        = string
}

variable "type" {
  description = "Zone type: public or private"
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.type)
    error_message = "type must be either 'public' or 'private'."
  }
}

variable "private_visibility_config_networks" {
  description = "List of VPC network self-links this zone is visible from. Required when type = private"
  type        = list(string)
  default     = []
}

variable "enable_dnssec" {
  description = "Whether to enable DNSSEC. Only applicable to public zones"
  type        = bool
  default     = false
}

variable "recordsets" {
  description = "List of DNS recordsets to create in this zone, in the shape expected by terraform-google-modules/cloud-dns"
  type        = any
  default     = []
}

variable "labels" {
  description = "Additional labels to apply to the zone"
  type        = map(string)
  default     = {}
}
