variable "environment" {
  description = "Environment name (dev, integ, prod, sandbox)"
  type        = string
}

variable "project_name" {
  description = "Project name for naming resources"
  type        = string
  default     = "hyperswitch"
}

variable "project_id" {
  description = "GCP project ID where the firewall rules are created"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network the rules apply to"
  type        = string
}

variable "ingress_rules" {
  description = <<-EOT
    Ingress firewall rule groups keyed by logical component name (e.g. "bastion-to-locker").
    target_tags/target_service_accounts identify the instances each rule in the group applies
    to; ranges/source_tags/source_service_accounts identify allowed traffic sources. Rule names
    are auto-prefixed with "<environment>-<project_name>-<component>-<rule.name>".
  EOT
  type = map(object({
    target_tags             = optional(list(string))
    target_service_accounts = optional(list(string))
    rules = list(object({
      name                    = string
      description             = optional(string)
      priority                = optional(number, 1000)
      ranges                  = optional(list(string))
      source_tags             = optional(list(string))
      source_service_accounts = optional(list(string))
      allow = optional(list(object({
        protocol = string
        ports    = optional(list(string))
      })))
      deny = optional(list(object({
        protocol = string
        ports    = optional(list(string))
      })))
      log_config = optional(object({
        metadata = string
      }))
    }))
  }))
  default = {}
}

variable "egress_rules" {
  description = <<-EOT
    Egress firewall rule groups keyed by logical component name. target_tags/
    target_service_accounts identify the instances each rule in the group applies to; ranges
    identifies allowed destinations (GCP egress rules have no source/destination-tag matching,
    only destination IP ranges). Rule names are auto-prefixed the same way as ingress_rules.
  EOT
  type = map(object({
    target_tags             = optional(list(string))
    target_service_accounts = optional(list(string))
    rules = list(object({
      name        = string
      description = optional(string)
      priority    = optional(number, 1000)
      ranges      = optional(list(string))
      allow = optional(list(object({
        protocol = string
        ports    = optional(list(string))
      })))
      deny = optional(list(object({
        protocol = string
        ports    = optional(list(string))
      })))
      log_config = optional(object({
        metadata = string
      }))
    }))
  }))
  default = {}
}
