variable "project_id" {
  description = "GCP project ID where the load balancer is created"
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

variable "name_override" {
  description = "Logical name for this load balancer instance (e.g. 'api', 'admin'), used in resource naming"
  type        = string
}

variable "internal" {
  description = "Whether this is an internal (regional TCP/UDP) load balancer instead of an external (global HTTP(S)) one"
  type        = bool
  default     = false
}

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "region" {
  description = "Region, required when internal = true"
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Self-link of the subnetwork, required when internal = true"
  type        = string
  default     = null
}

# External HTTP(S) Load Balancer

variable "ssl" {
  description = "Whether to provision an HTTPS listener with a managed certificate and redirect HTTP to HTTPS"
  type        = bool
  default     = true
}

variable "managed_ssl_certificate_domains" {
  description = "List of domains for the Google-managed SSL certificate, used when ssl = true and certificate_map is null"
  type        = list(string)
  default     = []
}

variable "certificate_map" {
  description = "Certificate Manager certificate map ID to attach instead of a classic managed SSL certificate (see composition/certificate-manager)"
  type        = string
  default     = null
}

variable "backends" {
  description = "Backend service configuration for the external load balancer, in the shape expected by GoogleCloudPlatform/lb-http/google"
  type        = any
  default     = {}
}

# Internal TCP/UDP Load Balancer

variable "internal_backends" {
  description = "List of {group = <instance-group-self-link>} backends for the internal load balancer"
  type        = any
  default     = []
}

variable "internal_lb_ports" {
  description = "List of ports to forward for the internal load balancer"
  type        = list(string)
  default     = []
}

variable "internal_lb_source_tags" {
  description = "Source network tags for the internal load balancer's firewall rules"
  type        = list(string)
  default     = []
}

variable "internal_lb_target_tags" {
  description = "Target network tags for the internal load balancer's firewall rules"
  type        = list(string)
  default     = []
}

variable "internal_lb_health_check" {
  description = "Health check configuration for the internal load balancer, in the shape expected by terraform-google-modules/lb-internal"
  type        = any
  default = {
    type                = "http"
    port                = 80
    check_interval_sec  = 10
    timeout_sec         = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
