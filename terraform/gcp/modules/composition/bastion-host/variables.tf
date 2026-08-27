variable "project_id" {
  description = "GCP project ID where the bastion is created"
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

variable "region" {
  description = "Region for regional resources"
  type        = string
}

variable "zone" {
  description = "Zone to create the bastion instance in"
  type        = string
}

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "subnet" {
  description = "Self-link of the subnetwork for the bastion (typically the management tier)"
  type        = string
}

variable "machine_type" {
  description = "Machine type for the bastion instance"
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Persistent disk type"
  type        = string
  default     = "pd-balanced"
}

variable "image" {
  description = "Specific image self-link to boot from. Null uses image_family/image_project instead"
  type        = string
  default     = null
}

variable "image_family" {
  description = "Image family to boot from, used when image is null"
  type        = string
  default     = "debian-12"
}

variable "image_project" {
  description = "Project the boot image/family belongs to"
  type        = string
  default     = "debian-cloud"
}

variable "members" {
  description = "List of IAM members (users/groups/service accounts) granted IAP-tunnel SSH access to the bastion"
  type        = list(string)
  default     = []
}

variable "enable_session_logging" {
  description = "Whether to create a GCS bucket + log sink capturing bastion session/audit logs"
  type        = bool
  default     = true
}

variable "log_bucket_location" {
  description = "Location for the session log bucket"
  type        = string
  default     = "US"
}

variable "session_log_retention_days" {
  description = "Number of days to retain session log objects before deletion"
  type        = number
  default     = 365
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
