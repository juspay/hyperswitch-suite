variable "project_id" {
  type        = string
  description = "GCP project to build the image in."
}

variable "zone" {
  type        = string
  description = "Zone the temporary build instance runs in."
}

variable "environment" {
  type        = string
  description = "Environment short name; part of the image name and family."
}

variable "project_name" {
  type        = string
  description = "Label value only."
  default     = "hyperswitch"
}

variable "image_name_prefix" {
  type        = string
  description = "Image name/family prefix. The composition module's socks5_image can then be passed as \"family/<prefix>-<environment>\"."
  default     = "hyperswitch-socks5"
}

variable "source_image_family" {
  type        = string
  description = "Base image family. Dante ships as `dante-server` in the Ubuntu archive."
  default     = "ubuntu-2204-lts"
}

variable "machine_type" {
  type    = string
  default = "e2-medium"
}

variable "disk_size_gb" {
  type    = number
  default = 20
}

variable "network" {
  type        = string
  description = "Network for the build instance."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork for the build instance."
}

variable "use_iap" {
  type        = bool
  description = "Reach the build instance over an IAP tunnel with no public IP. Currently broken for Ubuntu source images (hashicorp/packer#12169 - the tunnel connects but the SSH handshake never completes), which is why squid/envoy builds set this false and fall back to a temporary public IP for the build only."
  default     = false
}

variable "vector_loki_endpoint" {
  type        = string
  description = "Loki endpoint baked into the image's vector.toml. Not live-layer configurable - rebuild the image to change it."
  default     = "http://loki.monitoring.svc.cluster.local:3100"
}
