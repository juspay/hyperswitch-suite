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

variable "rules" {
  description = <<-EOT
    Map of firewall rule groups keyed by logical component name (e.g. "bastion-to-locker").
    Each group's rules are flattened and created as VPC firewall rules on var.network_name.
    Rule names are auto-prefixed with "<environment>-<project_name>-<component>-<rule.name>".
  EOT
  type = map(object({
    rules = list(object({
      name                    = string
      description             = optional(string)
      direction               = optional(string, "INGRESS") # INGRESS or EGRESS
      priority                = optional(number, 1000)
      ranges                  = optional(list(string))
      source_tags             = optional(list(string))
      source_service_accounts = optional(list(string))
      target_tags             = optional(list(string))
      target_service_accounts = optional(list(string))
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
