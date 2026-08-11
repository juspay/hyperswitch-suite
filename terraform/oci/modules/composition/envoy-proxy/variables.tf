variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "proxy_subnet_id" {
  type = string
}

variable "lb_subnet_id" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "shape" {
  type    = string
  default = "VM.Standard.E4.Flex"
}

variable "instance_ocpus" {
  type    = number
  default = 4
}

variable "instance_memory_in_gbs" {
  type    = number
  default = 16
}

variable "image_id" {
  type = string
}

variable "root_volume_size_in_gbs" {
  type    = number
  default = 50
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 6
}

variable "size" {
  type    = number
  default = 2
}

variable "envoy_traffic_port" {
  type    = number
  default = 10000
}

variable "create_lb" {
  type    = bool
  default = true
}

variable "lb_internal" {
  type    = bool
  default = true
}

variable "http_listener_port" {
  type    = number
  default = 80
}

variable "https_listener_port" {
  type    = number
  default = 443
}

variable "enable_https_listener" {
  type    = bool
  default = true
}

variable "https_certificate_ids" {
  description = "Equivalent of AWS ssl_certificate_arn (OCI Certificates Management certificate OCIDs, from the ../acm module)"
  type        = list(string)
  default     = []
}

variable "enable_mtls_listener" {
  type    = bool
  default = false
}

variable "mtls_listener_port" {
  type    = number
  default = 8443
}

variable "mtls_trusted_ca_ids" {
  description = "Equivalent of AWS mtls_listener.trust_store_arn"
  type        = list(string)
  default     = []
}

variable "health_check" {
  type = object({
    port     = number
    path     = optional(string, "/health")
    protocol = optional(string, "HTTP")
  })
  default = {
    port = 10000
  }
}

variable "ssh_authorized_keys" {
  type    = string
  default = null
}

variable "user_data" {
  type    = string
  default = null
}

variable "create_config_bucket" {
  type    = bool
  default = true
}

variable "create_logs_bucket" {
  type    = bool
  default = true
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
