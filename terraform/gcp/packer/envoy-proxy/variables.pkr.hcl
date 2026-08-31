variable "project_id" {
  type        = string
  description = "GCP project ID to build the image in"
}

variable "zone" {
  type        = string
  description = "Zone for the temporary Packer build instance"
}

variable "network" {
  type        = string
  description = "Self-link or name of the VPC network for the temporary build instance"
}

variable "subnetwork" {
  type        = string
  description = "Self-link or name of the subnetwork for the temporary build instance (needs a route to the internet via Cloud NAT for apt access, or reachability to a package mirror)"
}

variable "source_image_family" {
  type        = string
  description = "Base image family to build from"
  default     = "ubuntu-2204-lts"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the temporary Packer build instance"
  default     = "e2-medium"
}

variable "disk_size_gb" {
  type        = number
  description = "Boot disk size in GB for the built image"
  default     = 20
}

variable "envoy_version" {
  type        = string
  description = "Envoy release tag to install (e.g. \"v1.39.0\"), matching a tag on the official envoyproxy/envoy Docker Hub image (hub.docker.com/r/envoyproxy/envoy/tags) - NOT an apt package version. The binary is extracted from that image at build time, not run as a container."
  default     = "v1.39.0"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, sandbox, prod), used in the image name/family and labels"
  default     = "dev"
}

variable "project_name" {
  type        = string
  description = "Project name used in image labels"
  default     = "hyperswitch"
}

variable "image_name_prefix" {
  type        = string
  description = "Prefix for the resulting image name and family"
  default     = "hyperswitch-envoy"
}

variable "envoy_http_port" {
  type        = number
  description = "Envoy HTTP listener port to allow through ufw (must match the composition module's http_port, default 8080)"
  default     = 8080
}

variable "envoy_https_port" {
  type        = number
  description = "Envoy HTTPS listener port to allow through ufw (must match the composition module's https_port, default 8443)"
  default     = 8443
}

variable "envoy_mtls_port" {
  type        = number
  description = "Envoy mTLS listener port to allow through ufw (must match the composition module's mtls_port, default 8444)"
  default     = 8444
}

variable "vector_prometheus_port" {
  type        = number
  description = "Port Vector's prometheus_exporter sink listens on, allowed through ufw (matches address = \"0.0.0.0:9273\" in scripts/vector.toml)"
  default     = 9273
}

variable "use_iap" {
  type        = bool
  description = "Reach the temporary build instance over an IAP tunnel (no public IP). Requires the caller to hold roles/iap.tunnelResourceAccessor on the project - if that role isn't granted, set to false to fall back to a temporary public IP for the build only (the built image itself never gets a public IP; that's a live-layer concern, not this build's)."
  default     = true
}
