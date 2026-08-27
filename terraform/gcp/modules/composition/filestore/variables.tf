variable "project_id" {
  description = "GCP project ID where Filestore instances are created"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and labeling"
  type        = string
  default     = "hyperswitch"
}

variable "instances" {
  description = "Map of Filestore instances to create, keyed by logical name"
  type = map(object({
    zone              = string
    network           = string
    tier              = optional(string, "BASIC_HDD") # BASIC_HDD, BASIC_SSD, ZONAL, REGIONAL, ENTERPRISE
    description       = optional(string)
    connect_mode      = optional(string, "DIRECT_PEERING")
    reserved_ip_range = optional(string)
    kms_key_name      = optional(string)
    create_backup     = optional(bool, false)
    backup_region     = optional(string)
    labels            = optional(map(string), {})
    shares = list(object({
      name        = string
      capacity_gb = number
      nfs_export_options = optional(list(object({
        ip_ranges   = list(string)
        access_mode = optional(string, "READ_WRITE")
        squash_mode = optional(string, "NO_ROOT_SQUASH")
      })), [])
    }))
  }))
}

variable "labels" {
  description = "Additional labels applied to every instance"
  type        = map(string)
  default     = {}
}
