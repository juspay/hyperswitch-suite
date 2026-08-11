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

variable "create_lb" {
  type    = bool
  default = true
}

variable "display_name" {
  type    = string
  default = null
}

variable "is_private" {
  type    = bool
  default = false
}

variable "subnet_ids" {
  type = list(string)
}

variable "min_bandwidth_mbps" {
  type    = number
  default = 10
}

variable "max_bandwidth_mbps" {
  type    = number
  default = 100
}

variable "ingress_rules" {
  description = "Equivalent to AWS ingress_rules on the LB security group"
  type = map(object({
    protocol    = optional(string, "6")
    port        = number
    cidr_blocks = list(string)
    description = optional(string, "")
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# Backend sets / listeners (equivalent of AWS var.listeners)
# ---------------------------------------------------------------------------
variable "backend_sets" {
  description = <<-EOT
    Map of backend-set name -> config. Equivalent of the AWS module's target
    groups + listeners combined (OCI backend sets own the health checker and
    the backend list; listeners just point at a backend set by name).
  EOT
  type = map(object({
    policy   = optional(string, "ROUND_ROBIN")
    port     = number
    protocol = optional(string, "HTTP") # HTTP or TCP
    backends = list(object({
      ip_address = string
      port       = number
      weight     = optional(number, 1)
    }))
    health_check_path        = optional(string, "/")
    health_check_port        = optional(number)
    health_check_protocol    = optional(string, "HTTP")
    health_check_return_code = optional(number, 200)
  }))
  default = {}
}

variable "listeners" {
  description = "Map of listener name -> config (equivalent of AWS var.listeners)"
  type = map(object({
    port                = number
    protocol            = optional(string, "HTTP") # HTTP or HTTPS
    default_backend_set = string
    certificate_ids     = optional(list(string), [])
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# DNS (equivalent of AWS var.route53_zone / var.route53_records)
# ---------------------------------------------------------------------------
variable "create_dns_zone" {
  type    = bool
  default = false
}

variable "dns_zone_name" {
  type    = string
  default = null
}

variable "dns_records" {
  description = "Map of record name -> rtype, pointing at the LB's IP (equivalent of AWS route53_records with create_as_alias)"
  type = map(object({
    rtype = optional(string, "A")
    ttl   = optional(number, 300)
  }))
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
