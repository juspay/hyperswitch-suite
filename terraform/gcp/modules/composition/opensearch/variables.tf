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
  description = "Self-link of the subnetwork for OpenSearch nodes"
  type        = string
}

variable "lb_subnetwork" {
  description = "Self-link of the subnetwork for the internal load balancer's forwarding rule"
  type        = string
}

variable "node_image" {
  description = "Self-link or family of the custom image with OpenSearch pre-installed"
  type        = string
}

variable "node_count" {
  description = "Number of OpenSearch node instances"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for node instances"
  type        = string
  default     = "n2-standard-4"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 50
}

variable "data_disk_size_gb" {
  description = "Attached data disk size in GB per node"
  type        = number
  default     = 500
}

variable "disk_type" {
  description = "Persistent disk type used for both boot and data disks"
  type        = string
  default     = "pd-ssd"
}

variable "http_port" {
  description = "OpenSearch REST API port"
  type        = number
  default     = 9200
}

variable "metadata" {
  description = "Additional instance metadata (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
