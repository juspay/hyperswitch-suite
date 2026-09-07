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
  description = "Custom image with Envoy pre-installed - either a full self-link (projects/P/global/images/I) or a bare image name in var.project_id. Must be a specific image, not an image family"
  type        = string
}

variable "envoy_config_content" {
  description = "Envoy config YAML content. Written to both the config bucket and a Secret Manager secret. Null skips both"
  type        = string
  default     = null
  sensitive   = true
}

variable "additional_config_files_path" {
  description = "Optional local directory whose files are uploaded verbatim to the config bucket alongside envoy.yaml (e.g. a vector.toml override). No placeholder templating is applied. \"envoy.yaml\" is skipped, since envoy_config_content already owns that object. Null skips this entirely"
  type        = string
  default     = null
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

variable "deployments" {
  description = <<-EOT
    Map of concurrent Envoy deployments for blue/green and canary rollouts.
    Each key is an identifier (e.g. "stable", "canary"). Traffic is split
    across them via the load balancer's weighted_backend_services - GCP
    normalizes each deployment's share as weight / sum(all weights), so
    weights don't need to sum to 100 the way AWS's ALB weighted-forward
    percentages conventionally do (they still can, that's just not
    required).

    Fields left unset on a deployment fall back to the module-level
    envoy_image/machine_type/min_replicas/max_replicas variables - same
    override-or-inherit pattern as the AWS module's deployments map.
  EOT
  type = map(object({
    weight       = number
    envoy_image  = optional(string)
    machine_type = optional(string)
    min_replicas = optional(number)
    max_replicas = optional(number)
  }))
  default = {
    stable = { weight = 100 }
  }

  validation {
    condition     = length(var.deployments) > 0
    error_message = "At least one deployment must be defined."
  }

  validation {
    condition     = alltrue([for d in values(var.deployments) : d.weight >= 0])
    error_message = "All deployment weights must be >= 0."
  }
}

variable "scaling_policies" {
  description = <<-EOT
    Autoscaling policy configuration, applied to every deployment's MIG.

    cpu_target_tracking uses the MIG autoscaler's built-in CPU utilization
    signal (target_value is a 0-1 fraction, e.g. 0.6 = 60%). Enabled by
    default to preserve this module's previous always-on CPU autoscaling
    behavior.

    memory_target_tracking uses a custom Cloud Monitoring metric
    (agent.googleapis.com/memory/percent_used, a 0-100 gauge - note the
    different scale from cpu_target_tracking's 0-1 fraction). This
    requires the Ops Agent to be installed and configured on the Envoy
    image - enabling this without the agent present means the autoscaler
    never receives the metric and this policy is a silent no-op, the same
    precondition the AWS module documents for its CloudWatch-agent-backed
    memory_target_tracking. Installing the Ops Agent is out of scope for
    this module; see terraform/gcp/packer/envoy-proxy's README.

    If both signals are disabled, the MIG's target_size (== min_replicas)
    is used as a static instance count with no autoscaler attached.
  EOT
  type = object({
    cpu_target_tracking = optional(object({
      enabled      = optional(bool, true)
      target_value = optional(number, 0.6)
    }), {})
    memory_target_tracking = optional(object({
      enabled      = optional(bool, false)
      target_value = optional(number, 70)
    }), {})
  })
  default = {}
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
  description = "Whether to enable Cloud CDN on the load balancer's backend. Cloud CDN attaches directly to the existing backend rather than creating a separate distribution, so the LB's own IP becomes CDN-accelerated. Uses cache_mode = CACHE_ALL_STATIC, since this backend also serves non-cacheable payment API traffic"
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

variable "listener_rules" {
  description = <<-EOT
    Advanced load-balancer routing rules, evaluated before the default
    weighted deployment split, for path/host/header-based routing or
    redirects at the load balancer layer (before traffic reaches Envoy).

    Rules are evaluated in ascending priority order (lower number = higher
    precedence), matching the AWS ALB listener_rules priority convention.
    A rule with host = null applies regardless of host; a rule with host
    set only applies to hostnames in that list (GCP routes host-scoped
    rules through a dedicated path_matcher selected by a host_rule - see
    locals.path_matchers).

    Only one of path_prefix / path_exact may be set per rule. headers
    entries with more than one value are OR'd together via a regex
    alternation (values are NOT regex-escaped - avoid regex metacharacters
    in header values unless an alternation pattern is intended).

    Source-IP-based routing is NOT supported: GCP's HTTP(S) load balancer
    URL map has no source-IP match dimension at the routing layer (Cloud
    Armor can allow/deny by source IP at the edge, but cannot route a
    matched request to a different backend) - the AWS module's source_ip
    listener_rules condition has no equivalent field here.

    action.type = "forward" routes matching requests to a specific
    deployment's backend service (action.target_deployment, required, must
    be a key in var.deployments), bypassing the weighted split entirely.
    action.type = "redirect" returns an HTTP redirect without forwarding
    to any backend.
  EOT
  type = list(object({
    priority    = number
    host        = optional(list(string))
    path_prefix = optional(string)
    path_exact  = optional(string)
    headers = optional(list(object({
      name   = string
      values = list(string)
    })), [])
    action = object({
      type              = string
      target_deployment = optional(string)
      redirect = optional(object({
        host          = optional(string)
        path          = optional(string)
        https         = optional(bool, true)
        response_code = optional(string, "MOVED_PERMANENTLY_DEFAULT")
      }))
    })
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.listener_rules : contains(["forward", "redirect"], r.action.type)])
    error_message = "Each listener_rules[*].action.type must be \"forward\" or \"redirect\"."
  }

  validation {
    condition     = alltrue([for r in var.listener_rules : r.path_prefix == null || r.path_exact == null])
    error_message = "Each listener_rules[*] may set path_prefix or path_exact, not both."
  }

  validation {
    condition     = alltrue([for r in var.listener_rules : r.action.type != "forward" || r.action.target_deployment != null])
    error_message = "Each listener_rules[*] with action.type = \"forward\" must set action.target_deployment."
  }
}

variable "metadata" {
  description = "Additional instance metadata applied to proxy instances (e.g. startup-script parameters)"
  type        = map(string)
  default     = {}
}

variable "custom_startup_script" {
  description = "GCE startup-script content run on boot - fetches envoy.yaml/vector.toml from the config bucket and (re)starts envoy.service/vector.service. No placeholder substitution happens here; the script reads the config-bucket key from the instance metadata server itself. Null sets no startup-script, leaving the instance to boot on whatever the image bakes in"
  type        = string
  default     = null
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
