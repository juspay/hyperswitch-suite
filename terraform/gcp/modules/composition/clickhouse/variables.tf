variable "project_id" {
  description = "GCP project ID where instances are created"
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

variable "subnetwork" {
  description = "Self-link of the subnetwork for ClickHouse nodes"
  type        = string
}

variable "lb_subnetwork" {
  description = "Self-link of the subnetwork for the internal load balancer's forwarding rule"
  type        = string
}

variable "server_image" {
  description = "Self-link or family of the custom image with the ClickHouse server pre-installed"
  type        = string
}

variable "keeper_image" {
  description = "Self-link or family of the custom image with ClickHouse Keeper pre-installed"
  type        = string
}

variable "server_count" {
  description = "Number of ClickHouse server instances"
  type        = number
  default     = 2
}

variable "keeper_count" {
  description = "Number of ClickHouse Keeper instances (should be odd for quorum)"
  type        = number
  default     = 3
}

variable "server_machine_type" {
  description = "Machine type for server instances"
  type        = string
  default     = "n2-standard-8"
}

variable "keeper_machine_type" {
  description = "Machine type for keeper instances"
  type        = string
  default     = "n2-standard-2"
}

variable "server_boot_disk_size_gb" {
  description = "Boot disk size in GB for server instances"
  type        = number
  default     = 50
}

variable "keeper_boot_disk_size_gb" {
  description = "Boot disk size in GB for keeper instances"
  type        = number
  default     = 50
}

variable "server_disk_size_gb" {
  description = "Attached data disk size in GB per server instance"
  type        = number
  default     = 1000
}

variable "keeper_disk_size_gb" {
  description = "Attached data disk size in GB per keeper instance"
  type        = number
  default     = 50
}

variable "disk_type" {
  description = "Persistent disk type used for both boot and data disks"
  type        = string
  default     = "pd-ssd"
}

variable "server_http_port" {
  description = "ClickHouse HTTP interface port"
  type        = number
  default     = 8123
}

variable "server_native_port" {
  description = "ClickHouse native TCP protocol port"
  type        = number
  default     = 9000
}

variable "metadata" {
  description = "Additional instance metadata applied to both tiers (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
