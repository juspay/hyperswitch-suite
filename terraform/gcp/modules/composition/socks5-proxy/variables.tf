variable "project_id" {
  description = "GCP project to create the proxy fleet in."
  type        = string
}

variable "project_name" {
  description = "Resource-name prefix component."
  type        = string
  default     = "hyperswitch"
}

variable "environment" {
  description = "Environment short name, used in every resource name."
  type        = string
}

variable "region" {
  description = "Region for the MIG and the internal load balancer."
  type        = string
}

variable "network" {
  description = "VPC network self-link or name."
  type        = string
}

variable "proxy_subnetwork" {
  description = "Subnetwork the proxy instances get their NICs in."
  type        = string
}

variable "lb_subnetwork" {
  description = "Subnetwork the internal load balancer's forwarding rule lives in."
  type        = string
}

variable "socks5_image" {
  description = "Pre-baked image with Dante installed. Accepts a bare name, a full image self-link, or a `.../global/images/family/<name>` link. Build it from terraform/gcp/packer/socks5-proxy."
  type        = string
}

variable "socks5_config_content" {
  description = "Full danted.conf to upload to the config bucket. Null leaves the image's own boot-time default in place, which listens on socks5_port with no authentication and relies on ilb_source_ranges plus the VPC firewall to scope access."
  type        = string
  default     = null
}

variable "vector_config_content" {
  description = "Optional override for the vector.toml baked into the image. Nothing in the image fetches this on its own - applying it needs a custom_startup_script."
  type        = string
  default     = null
}

variable "additional_config_files_path" {
  description = "Directory whose files are uploaded to the config bucket verbatim, alongside danted.conf."
  type        = string
  default     = null
}

variable "ilb_source_ranges" {
  description = "CIDR ranges allowed to reach the internal LB's forwarding rule on socks5_port. Required, with no default: the underlying lb-internal module falls back to 0.0.0.0/0 when both source_ip_ranges and source_tags are unset. The clients here are GKE pods, which carry no network tags to match on, so this must be IP-range based - keep it in sync with the gke-to-socks5-egress rule in the same environment's firewall-rules unit."
  type        = list(string)
}

variable "force_destroy_buckets" {
  description = "Whether the config/log buckets can be destroyed while non-empty - required for `terraform destroy` to succeed at all, since versioning leaves noncurrent object versions behind. Null (default) auto-derives: true everywhere except \"prod\"."
  type        = bool
  default     = null
}

variable "bucket_location" {
  description = "Location for the config and log buckets."
  type        = string
  default     = "US"
}

variable "log_retention_days" {
  description = "Age at which objects in the log bucket are deleted."
  type        = number
  default     = 90
}

variable "machine_type" {
  description = "Machine type for the proxy instances."
  type        = string
  default     = "e2-small"
}

variable "disk_size_gb" {
  description = "Boot disk size."
  type        = number
  default     = 20
}

variable "disk_type" {
  description = "Boot disk type."
  type        = string
  default     = "pd-balanced"
}

variable "min_replicas" {
  description = "Minimum (and initial) MIG size."
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum MIG size."
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilisation for the autoscaler."
  type        = number
  default     = 0.6
}

variable "socks5_port" {
  description = "Port Dante listens on. 1080 is the SOCKS5 default and what the application's email.smtp.socks5.port expects."
  type        = number
  default     = 1080
}

variable "metadata" {
  description = "Extra instance metadata, merged with the config-bucket key the image's fetch unit reads."
  type        = map(string)
  default     = {}
}

variable "custom_startup_script" {
  description = "Startup script for the instances. Null by default: config delivery is handled by a systemd unit baked into the image, not a startup script."
  type        = string
  default     = null
}

variable "labels" {
  description = "Extra labels, merged onto every resource."
  type        = map(string)
  default     = {}
}
