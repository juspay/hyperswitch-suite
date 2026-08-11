variable "compartment_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "project_name" {
  type = string
}

variable "load_balancer_id" {
  description = "OCID of the origin oci_load_balancer_load_balancer to protect with WAF (see README - this module does NOT provide CDN/edge caching, only an edge security layer)"
  type        = string
}

variable "web_app_firewall_policy_id" {
  description = "OCID of an oci_waf_web_app_firewall_policy (managed outside this module, since policy rule authoring is highly deployment-specific)"
  type        = string
}

variable "display_name" {
  type    = string
  default = null
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}
