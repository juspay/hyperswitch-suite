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
  description = "Self-link of the subnetwork for Envoy proxy instances (typically the incoming-envoy tier)"
  type        = string
}

variable "envoy_image" {
  description = "The custom image with Envoy pre-installed - either a full self-link (https://www.googleapis.com/compute/v1/projects/P/global/images/I or projects/P/global/images/I) or a bare image name living in var.project_id. Both forms are parsed correctly (see locals.tf) - do not pass an image *family* here, only a specific image name/self-link."
  type        = string
}

variable "envoy_config_content" {
  description = "Envoy config YAML content. Written to both the config bucket and a Secret Manager secret. Null skips both"
  type        = string
  default     = null
  sensitive   = true
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
  default     = 30
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
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization (0-1) for the autoscaler"
  type        = number
  default     = 0.6
}

variable "http_port" {
  description = "Port Envoy listens on for HTTP"
  type        = number
  default     = 8080
}

variable "https_port" {
  description = "Port Envoy listens on for HTTPS"
  type        = number
  default     = 8443
}

variable "mtls_port" {
  description = "Port Envoy listens on for mTLS"
  type        = number
  default     = 8444
}

variable "health_check_path" {
  description = "HTTP path for the load balancer / MIG health check"
  type        = string
  default     = "/health"
}

variable "managed_ssl_certificate_domains" {
  description = "List of domains for the load balancer's Google-managed SSL certificate"
  type        = list(string)
  default     = []
}

variable "enable_https_redirect" {
  description = <<-EOT
    Whether the LB force-redirects HTTP to HTTPS. Defaults true (the
    correct posture once a real domain + validated managed cert exist).
    Set false only when managed_ssl_certificate_domains is a placeholder
    that will never validate (e.g. no real DNS pointed at the LB yet) -
    otherwise port 80 just redirects into a TLS handshake that can never
    complete, and the LB is untestable end-to-end from outside the VPC.
  EOT
  type        = bool
  default     = true
}

variable "enable_cdn" {
  description = "Whether to enable Cloud CDN on the load balancer's backend. GCP's Cloud CDN attaches directly to an existing HTTP(S) LB backend (unlike AWS CloudFront, it does not create a separate distribution/domain) - the LB's own IP/hostname becomes CDN-accelerated. Uses cache_mode = CACHE_ALL_STATIC (respects origin Cache-Control, only heuristically caches static content types) rather than FORCE_CACHE_ALL, since this backend also serves live, non-cacheable payment API traffic."
  type        = bool
  default     = false
}

variable "enable_cloud_armor" {
  description = "Whether to create and attach a Cloud Armor WAF policy to the load balancer backend"
  type        = bool
  default     = true
}

variable "cloud_armor_preconfigured_rules" {
  description = "Map of Cloud Armor pre-configured WAF rules to enable, in the shape expected by GoogleCloudPlatform/cloud-armor"
  type        = any
  default     = {}
}

variable "enable_mtls_listener" {
  description = "Whether to create the separate regional mTLS Server TLS Policy listener"
  type        = bool
  default     = false
}

variable "mtls_trust_config_id" {
  description = "ID of the Certificate Manager TrustConfig used for client certificate validation. Required when enable_mtls_listener = true"
  type        = string
  default     = null
}

variable "metadata" {
  description = "Additional instance metadata applied to proxy instances (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "custom_startup_script" {
  description = "GCE startup-script content run on boot, the GCP equivalent of the AWS envoy-proxy composition module's custom_userdata - pulls envoy.yaml/vector.toml from the config bucket (module.config_bucket.name, exposed to the script via the config-bucket instance-metadata key this module already sets) and (re)starts envoy.service/vector.service. Unlike AWS's custom_userdata, no {{bucket-name}}-style placeholder substitution happens here - the script is expected to read the config-bucket key itself from the instance metadata server at boot (http://metadata.google.internal/computeMetadata/v1/instance/attributes/config-bucket), since GCE's metadata server makes that trivial without needing Terraform-side templating. Null means no startup-script is set at all - the instance boots with whatever the image itself bakes in (see the envoy-proxy Packer image's own README for what that is by default)."
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
