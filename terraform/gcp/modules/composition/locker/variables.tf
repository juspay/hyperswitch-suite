variable "project_id" {
  description = "GCP project ID where resources are created"
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
  description = "Zone to create instances in"
  type        = string
}

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network (used by the optional Cloud SQL database, requires Private Service Access)"
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Self-link of the subnetwork for locker instances (typically the locker-server tier)"
  type        = string
}

variable "lb_subnetwork" {
  description = "Self-link of the subnetwork for the internal load balancer's forwarding rule"
  type        = string
}

variable "locker_image" {
  description = "Self-link or family of the custom image with the card-vault software pre-installed"
  type        = string
}

variable "instance_count" {
  description = "Number of locker instances"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for locker instances"
  type        = string
  default     = "n2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Persistent disk type"
  type        = string
  default     = "pd-ssd"
}

variable "locker_port" {
  description = "Port the locker application listens on"
  type        = number
  default     = 8080
}

variable "health_check_port" {
  description = "Port for the locker health check"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path for the locker health check"
  type        = string
  default     = "/health"
}

variable "metadata" {
  description = "Additional instance metadata (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Locker Database
# ============================================================================

variable "create_locker_database" {
  description = "Whether to create a dedicated Cloud SQL database for the locker"
  type        = bool
  default     = true
}

variable "database_config" {
  description = "Configuration for the locker's dedicated Cloud SQL database (composition/cloud-sql)"
  type = object({
    instance_name       = optional(string)
    database_version    = optional(string, "POSTGRES_15")
    tier                = optional(string, "db-custom-2-8192")
    availability_type   = optional(string, "REGIONAL")
    disk_size           = optional(number, 100)
    deletion_protection = optional(bool, true)
    database_name       = optional(string, "locker")
    master_username     = optional(string, "locker_admin")
    master_password     = optional(string)
    encryption_key_name = optional(string)
  })
  default = {}
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
