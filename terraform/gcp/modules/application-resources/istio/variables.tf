variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and labeling"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "Region for the gateway's static IP"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint (host, without scheme) for the Kubernetes API server"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  type        = string
  sensitive   = true
}

variable "network" {
  description = "Self-link of the VPC network"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network, required when create_firewall_rules = true"
  type        = string
  default     = null
}

variable "istio_namespace" {
  description = "Namespace to install Istio components into"
  type        = string
  default     = "istio-system"
}

variable "istio_base" {
  description = "Configuration for the Istio base chart"
  type = object({
    enabled       = bool
    release_name  = optional(string)
    chart_repo    = optional(string)
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })
  default = { enabled = true }
}

variable "istiod" {
  description = "Configuration for the istiod chart"
  type = object({
    enabled       = bool
    release_name  = optional(string)
    chart_repo    = optional(string)
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })
  default = { enabled = true }
}

variable "istio_gateway" {
  description = "Configuration for the Istio gateway chart"
  type = object({
    enabled       = bool
    release_name  = optional(string)
    chart_repo    = optional(string)
    chart_version = optional(string)
    values        = optional(list(string), [])
    values_file   = optional(string, "")
  })
  default = { enabled = true }
}

variable "create_gateway_static_ip" {
  description = "Whether to reserve a static regional IP for the gateway's LoadBalancer service"
  type        = bool
  default     = true
}

variable "gateway_service_annotations" {
  description = "Additional annotations applied to the gateway's LoadBalancer service"
  type        = map(string)
  default     = {}
}

variable "create_firewall_rules" {
  description = "Whether to create the firewall rule allowing ingress traffic to the gateway"
  type        = bool
  default     = true
}

variable "host_domains" {
  description = "Map of logical name to hostname(s) served through this gateway, passed through as an output for wiring into DNS/routing config"
  type        = map(list(string))
  default     = {}
}

variable "labels" {
  description = "Additional labels to apply to created resources that support them"
  type        = map(string)
  default     = {}
}
