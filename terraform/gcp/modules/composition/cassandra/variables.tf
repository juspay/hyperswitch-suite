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
  description = "Region for regional resources (addresses, instance templates, the seed-discovery function)"
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

variable "node_image" {
  description = "Self-link or family of the custom image with Cassandra pre-installed"
  type        = string
}

variable "node_count" {
  description = "Number of Cassandra node instances"
  type        = number
  default     = 3
}

variable "machine_type" {
  description = "Machine type for Cassandra node instances"
  type        = string
  default     = "n2-standard-4"
}

variable "disk_size_gb" {
  description = "Data disk size in GB per node"
  type        = number
  default     = 500
}

variable "disk_type" {
  description = "Persistent disk type"
  type        = string
  default     = "pd-ssd"
}

variable "metadata" {
  description = "Additional instance metadata (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "enable_seed_discovery" {
  description = "Whether to create the seed-discovery Cloud Function"
  type        = bool
  default     = true
}

variable "seed_discovery_source" {
  description = "GCS location of the seed-discovery function source zip: {bucket, object}"
  type = object({
    bucket     = string
    object     = string
    generation = optional(string)
  })
  default = null
}

variable "seed_discovery_runtime" {
  description = "Cloud Functions runtime for the seed-discovery function"
  type        = string
  default     = "python312"
}

variable "seed_discovery_entrypoint" {
  description = "Entrypoint function name in the seed-discovery source"
  type        = string
  default     = "get_seeds"
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
