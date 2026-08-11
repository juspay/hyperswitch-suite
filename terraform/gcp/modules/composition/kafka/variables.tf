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
  description = "Region for regional resources (addresses, instance templates)"
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
  description = "Self-link of the subnetwork (typically the data-stack tier from composition/vpc-network)"
  type        = string
}

variable "broker_image" {
  description = "Self-link or family of the custom image with Kafka broker software pre-installed"
  type        = string
}

variable "controller_image" {
  description = "Self-link or family of the custom image with the Kafka (KRaft) controller software pre-installed"
  type        = string
}

variable "broker_count" {
  description = "Number of broker instances"
  type        = number
  default     = 3
}

variable "controller_count" {
  description = "Number of KRaft controller instances (should be odd for quorum)"
  type        = number
  default     = 3
}

variable "broker_machine_type" {
  description = "Machine type for broker instances"
  type        = string
  default     = "n2-standard-4"
}

variable "controller_machine_type" {
  description = "Machine type for controller instances"
  type        = string
  default     = "n2-standard-2"
}

variable "broker_disk_size_gb" {
  description = "Boot/data disk size in GB for broker instances"
  type        = number
  default     = 500
}

variable "controller_disk_size_gb" {
  description = "Boot/data disk size in GB for controller instances"
  type        = number
  default     = 100
}

variable "disk_type" {
  description = "Persistent disk type for all instances"
  type        = string
  default     = "pd-ssd"
}

variable "metadata" {
  description = "Additional instance metadata applied to both broker and controller instances (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
