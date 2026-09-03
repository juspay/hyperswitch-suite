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

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "proxy_subnetwork" {
  description = "Self-link of the subnetwork for Squid proxy instances (typically the outgoing-proxy tier)"
  type        = string
}

variable "lb_subnetwork" {
  description = "Self-link of the subnetwork for the internal load balancer's forwarding rule"
  type        = string
}

variable "squid_image" {
  description = "Self-link or family of the custom image with Squid pre-installed"
  type        = string
}

variable "squid_config_content" {
  description = "squid.conf content, written to the config bucket. Null skips writing a config object"
  type        = string
  default     = null
}

variable "squid_allowlist_content" {
  description = "Whitelisted-domains file content (allowedlist.txt), written to the config bucket and synced onto instances every 15 min by the image's whitelist-fetch cron job (squid -k reconfigure, no instance replacement needed). Null skips writing the object."
  type        = string
  default     = null
}

variable "vector_config_content" {
  description = "Vector log-shipping config (vector.toml) content, written to the config bucket. Nothing on the instance fetches it automatically - the Packer image bakes its own vector.toml in at build time - so applying it requires a custom_startup_script that fetches it. Null skips writing the object"
  type        = string
  default     = null
}

variable "additional_config_files_path" {
  description = "Optional local directory whose files are uploaded verbatim to the config bucket. No placeholder templating is applied. \"squid.conf\", \"allowedlist.txt\" and \"vector.toml\" are skipped, since the dedicated *_content variables already own those objects. Null skips this entirely"
  type        = string
  default     = null
}

variable "ilb_source_ranges" {
  description = "CIDR ranges allowed to reach the internal LB's forwarding rule on squid_port. Required, with no default: the underlying lb-internal module falls back to 0.0.0.0/0 when both source_ip_ranges and source_tags are unset. Squid's clients are GKE pods, which carry no network tags to match on, so this must be IP-range based - keep it in sync with the gke-to-squid-egress rule in the same environment's firewall-rules unit"
  type        = list(string)
}

variable "force_destroy_buckets" {
  description = "Whether the config/log buckets can be destroyed while non-empty - required for `terraform destroy` to succeed at all, since versioning leaves noncurrent object versions behind. Null (default) auto-derives: true everywhere except \"prod\""
  type        = bool
  default     = null
}

variable "bucket_location" {
  description = "Location for the config/log buckets"
  type        = string
  default     = "US"
}

variable "log_retention_days" {
  description = "Number of days to retain access log objects before deletion"
  type        = number
  default     = 90
}

variable "machine_type" {
  description = "Machine type for proxy instances"
  type        = string
  default     = "n2-standard-2"
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

variable "min_replicas" {
  description = "Minimum number of proxy instances"
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Maximum number of proxy instances"
  type        = number
  default     = 6
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization (0-1) for the autoscaler"
  type        = number
  default     = 0.6
}

variable "squid_port" {
  description = "Port Squid listens on"
  type        = number
  default     = 3128
}

variable "metadata" {
  description = "Additional instance metadata applied to proxy instances (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "custom_startup_script" {
  description = "GCE startup-script content run on boot. Normally unnecessary: the Packer image already bakes in squid-config-fetch.service and squid-whitelist-fetch.service, which pull squid.conf/allowedlist.txt from the config bucket before Squid starts, plus a cron job that re-syncs the whitelist. Null (default) sets no startup-script. Only set this for boot-time behavior beyond what the image provides"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
