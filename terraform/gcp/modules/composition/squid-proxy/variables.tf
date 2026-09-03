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

variable "additional_config_files_path" {
  description = "Optional local directory (e.g. \"$${get_terragrunt_dir()}/config\") whose files are uploaded as-is to the config bucket alongside squid.conf/allowedlist.txt/vector.toml - same mechanism as composition/envoy-proxy's identically-named variable, mirroring the AWS module's config_files_source_path/fileset() pattern (terraform/aws/modules/composition/squid-proxy). Every file found in this directory is uploaded verbatim under its own name (subdirectories via fileset's \"**\" glob too) - a plain byte-for-byte upload, no {{placeholder}} templating. \"squid.conf\", \"allowedlist.txt\", and \"vector.toml\" are all skipped if present, since squid_config_content/squid_allowlist_content/vector_config_content already own those three object names (avoids two resources managing the same bucket key). Null skips this entirely - existing callers that only set the three dedicated *_content variables are unaffected."
  type        = string
  default     = null
}

variable "ilb_source_ranges" {
  description = "CIDR ranges allowed to reach the internal LB's forwarding rule (squid_port). Required - there is no safe default: the underlying terraform-google-modules/lb-internal module's firewall resource falls back to GCP's own API default of 0.0.0.0/0 whenever both source_ip_ranges and source_tags/source_service_accounts are left unset (confirmed live, 2026-09-02 - the exact gap this variable closes). Squid's actual clients are GKE pods, which carry no network tags of their own to source-tag-match against instead, so this must be IP-range-based - set it to the same GKE node-subnet + pod-secondary-range CIDRs already used by the sibling gke-to-squid-egress ingress firewall rule in this environment's firewall-rules unit, to avoid the two rules drifting out of sync."
  type        = list(string)
}

variable "force_destroy_buckets" {
  description = "Whether the config/log buckets can be destroyed while non-empty (needed for `terraform destroy` to succeed at all, since versioning = true otherwise leaves noncurrent object versions behind that block deletion). Null (default) auto-derives from environment - true everywhere except \"prod\", matching the AWS module's identical var.environment != \"prod\" ? true : false gate on its own config/log S3 buckets (terraform/aws/modules/composition/squid-proxy/main.tf). Set explicitly to override the auto-derived value for either bucket."
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
  description = "GCE startup-script content run on boot, the GCP equivalent of the AWS squid-proxy composition module's custom_userdata - same pattern as composition/envoy-proxy's variable of the same name. Unlike envoy, this fleet's config/whitelist delivery is NOT normally this module's job: the Packer image (terraform/gcp/packer/squid-proxy) already bakes in squid-config-fetch.service and squid-whitelist-fetch.service (both Before=squid.service), which read the config-bucket instance-metadata key this module already sets and pull squid.conf/allowedlist.txt from module.config_bucket before Squid ever starts - the whitelist also re-syncs on its own via a cron job baked into the same image (update-squid-whitelist.sh, every 15 min). Null (default) means no startup-script is set at all and the instance boots purely on the image's own baked-in units, which is correct for the common case. Only set this if a specific fleet needs boot-time behavior beyond what the image already bakes in (e.g. one-off debugging, a temporary override) - it does not replace or need to duplicate the two systemd units above."
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
