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
  description = "Self-link or family of the custom image with Envoy pre-installed"
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

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
