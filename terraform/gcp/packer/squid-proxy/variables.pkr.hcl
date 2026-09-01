variable "project_id" {
  type        = string
  description = "GCP project ID to build the image in"
}

variable "zone" {
  type        = string
  description = "Zone for the temporary Packer build instance"
}

variable "network" {
  type        = string
  description = "Self-link or name of the VPC network for the temporary build instance"
}

variable "subnetwork" {
  type        = string
  description = "Self-link or name of the subnetwork for the temporary build instance (needs a route to the internet via Cloud NAT for apt access, or reachability to a package mirror)"
}

variable "source_image_family" {
  type        = string
  description = "Base image family to build from"
  default     = "ubuntu-2204-lts"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the temporary Packer build instance"
  default     = "e2-medium"
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB for the built image"
  default     = 20
}

variable "environment" {
  type        = string
  description = "Environment name (dev, sandbox, prod), used in the image name/family and labels"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name used in image labels"
  default     = "hyperswitch"
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix for the resulting image name and family"
  default     = "hyperswitch-squid"
}

variable "use_iap" {
  type        = bool
  description = "Reach the temporary build instance over an IAP tunnel (no public IP). Requires the caller to hold roles/iap.tunnelResourceAccessor on the project - if that role isn't granted, or hashicorp/packer#12169 is still unresolved, set to false to fall back to a temporary public IP for the build only (the built image itself never gets a public IP; that's a live-layer concern, not this build's)."
  default     = true
}

variable "vector_loki_endpoint" {
  type        = string
  description = "Loki endpoint Vector ships squid access.log to (scheme+host, e.g. http://loki.hyperswitch.internal - matches the AWS sandbox's vector.toml). NOT YET REACHABLE from the GCP VPC as of 2026-08-20: loki.hyperswitch.internal is an AWS-only Route53 private-zone record, and no interconnect/VPN exists between this GCP project and that AWS VPC. Vector will start and tail the log file correctly either way, but will retry indefinitely against this endpoint without ever successfully shipping to Loki until either a real cross-cloud interconnect exists or this is pointed at a GCP-reachable Loki instance instead. Baked in at build time - changing this requires a rebuild, not just a live-layer edit."
  default     = "http://loki.hyperswitch.internal"
}
