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
  description = "Vector log-shipping config (vector.toml) content, written to the config bucket as vector.toml. Unlike squid_config_content/squid_allowlist_content, nothing in the image fetches this automatically - the Packer image (terraform/gcp/packer/squid-proxy) bakes its own vector.toml in at BUILD time via a template (scripts/vector.toml.pkrtpl.hcl), with no boot-time override path. Setting this variable only writes the object to the bucket; actually picking it up requires custom_startup_script to fetch and apply it (see that variable's own description, and envoy-proxy's templates/startup-script.sh in the live-layer for the pattern to mirror). Null skips writing the object entirely - the instance then just keeps whatever vector.toml the image baked in, same as before this variable existed."
  type        = string
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
  description = "GCE startup-script content run on boot, the GCP equivalent of the AWS squid-proxy composition module's custom_userdata - same pattern as composition/envoy-proxy's variable of the same name. Unlike envoy, this fleet's config/whitelist delivery is NOT normally this module's job: the Packer image (terraform/gcp/packer/squid-proxy) already bakes in squid-config-fetch.service and squid-whitelist-fetch.service (both Before=squid.service), which read the config-bucket instance-metadata key this module already sets and pull squid.conf/allowedlist.txt from module.config_bucket before Squid ever starts - the whitelist also re-syncs on its own via a cron job baked into the same image (update-squid-whitelist.sh, every 15 min). Null (default) means no startup-script is set at all and the instance boots purely on the image's own baked-in units, which is correct for the common case. Only set this if a specific fleet needs boot-time behavior beyond what the image already bakes in (e.g. one-off debugging, a temporary override) - it does not replace or need to duplicate the two systemd units above."
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
