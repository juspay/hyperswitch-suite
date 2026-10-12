# Security-rules module variables (OCI). Input vocabulary kept in AWS terms
# (from_port/to_port/protocol="tcp") so the AWS rule set ports mechanically;
# OCI translation happens in locals.tf. The module never names a consumer - it
# takes a generic map of (nsg_id, rules) and attaches rules to NSGs it does not
# own, which is what lets it run last after every other unit's NSG outputs.

variable "compartment_id" {
  description = <<-EOT
    OCID of the compartment this environment lives in.

    Note on scope: no RULE resource in this module is compartment-scoped -
    oci_core_network_security_group_security_rule inherits the compartment of
    the NSG it attaches to, which is the property that lets this module write
    into NSGs owned by other states. compartment_id is required only by the
    default-security-list guard's lookup (guards.tf). Kept required anyway so
    the unit's contract matches every other OCI unit.
  EOT
  type        = string
}

# -------------------------------------------------------------------------
# Default security list guard: the NSG-only model requires an empty default list.
# -------------------------------------------------------------------------
variable "default_security_list_id" {
  description = <<-EOT
    OCID of the VCN's default security list, from composition/vpc-network's
    `default_security_list_id` output. Used only for the plan-time assertion
    that it carries zero rules.
  EOT
  type        = string
  default     = null
}

variable "assert_default_security_list_empty" {
  description = <<-EOT
    Fail the plan if the VCN's default security list is not empty.

    This is a correctness prerequisite, not hardening polish. OCI evaluates
    security lists and NSGs as a UNION (OR): a packet is allowed if ANY rule in
    ANY relevant list or group allows it. The stock default security list
    carries allow-all egress and SSH-22 ingress, and a subnet that does not set
    `security_list_ids` inherits it - which makes every NSG egress rule this
    module writes decorative. vpc-network neuters it via
    oci_core_default_security_list with zero rule blocks; this asserts it stayed
    that way. Treat a failure as a release blocker.

    Requires `default_security_list_id` to be a real, readable OCID - the data
    source read fails against a terragrunt mock, so set this false for a
    standalone plan before vpc-network has been applied.
  EOT
  type        = bool
  default     = true
}

variable "allowed_non_default_security_lists" {
  description = <<-EOT
    Map of the LEGITIMATE non-default security lists permitted in this VCN,
    keyed by a short logical name (e.g. "bastion", "redis"). Each entry names a
    resource type with a VNIC but no (or partial) NSG support - the single case
    the NSG-only model tolerates. Each
    entry matches a discovered list by EITHER:

      security_list_ocid - OCID of a list THIS IaC owns and exports
                           (vpc-network's `bastion` list). Precise, but brittle
                           to service-managed recreation.
      match_display_name - well-known display name of a SERVICE-created list we
                           do not own (the OCI Cache/Valkey service's
                           `redis-security-list`). Matches the service's fixed
                           name rather than an OCID, so it survives service-side
                           recreation.

    Exactly one of the two must be set. Plus:

      max_ingress_rules - maximum INGRESS rule count permitted on that list.
                         Bastion: 0 (egress-only). Redis: 1 (only the service's
                         own cache-port ingress, e.g. 6379). Any actual ingress
                         above this hard-fails the plan.

    The guard asserts these are the ONLY non-default lists in the VCN, and that
    none exceeds its permitted ingress budget.
  EOT
  type = map(object({
    security_list_ocid = optional(string)
    match_display_name = optional(string)
    max_ingress_rules  = number
  }))
  default = {}
}

# -------------------------------------------------------------------------
# The rule set
# -------------------------------------------------------------------------
variable "ingress_rules" {
  description = <<-EOT
    Map of ingress rule groups keyed by logical component (e.g. "oke_node_ingress").
    `nsg_id` is the OCID of the NSG the rules are attached to - normally owned by
    another Terraform state.

    Exactly one source selector per rule:
      cidr               - list of CIDRs. Covers IPv4 AND IPv6: OCI has a single
                           `source` field for both families, so AWS's separate
                           `ipv6_cidr` selector is gone. OCI's `source` is a
                           SINGLE string, so an N-entry list fans out into N
                           resources (PARTIAL, sheet §4.1).
      nsg_id             - list of peer NSG OCIDs. This is the 83%-of-rules case
                           and the reason the port uses NSGs, not security lists.
      service_cidr_label - "objectstorage" or "all-services". Replaces AWS
                           `prefix_list_ids` (PARTIAL, sheet §4.2): OCI exposes
                           only the two service-gateway CIDR labels and has no
                           customer-managed prefix-list equivalent, so shared
                           address sets must be repeated as `cidr` lists.
  EOT
  type = map(object({
    nsg_id = string
    rules = list(object({
      description        = string
      from_port          = number
      to_port            = number
      protocol           = string
      cidr               = optional(list(string))
      nsg_id             = optional(list(string))
      service_cidr_label = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for group in var.ingress_rules : [
        for rule in group.rules :
        (rule.cidr != null ? 1 : 0) + (rule.nsg_id != null ? 1 : 0) + (rule.service_cidr_label != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "Each ingress rule must have exactly one of 'cidr', 'nsg_id' or 'service_cidr_label'."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.ingress_rules : [
        for rule in group.rules :
        contains(["tcp", "udp", "icmp", "icmpv6", "-1", "all"], rule.protocol)
      ]
    ]))
    error_message = "Ingress rule protocol must be one of tcp, udp, icmp, icmpv6, -1, all. OCI takes IANA protocol numbers; the module translates, so an unmapped name would otherwise become a silently wrong rule."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.ingress_rules : [
        for rule in group.rules :
        contains(["objectstorage", "all-services"], coalesce(rule.service_cidr_label, "objectstorage"))
      ]
    ]))
    error_message = "service_cidr_label must be 'objectstorage' or 'all-services' - a region's service gateway exposes exactly these two CIDR labels."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.ingress_rules : [
        for rule in group.rules :
        length(trimspace(rule.description)) > 0 && length(rule.description) <= 200
      ]
    ]))
    error_message = "Every ingress rule needs a non-empty description under 200 characters (PCI-DSS 1.2/1.3 audit surface; the module appends an 'n/m' suffix to fanned-out rules, so the ceiling is below OCI's 255)."
  }
}

variable "egress_rules" {
  description = "Map of egress rule groups keyed by logical component. Same shape and same selector rules as ingress_rules; `nsg_id`/`cidr`/`service_cidr_label` become the rule's destination."
  type = map(object({
    nsg_id = string
    rules = list(object({
      description        = string
      from_port          = number
      to_port            = number
      protocol           = string
      cidr               = optional(list(string))
      nsg_id             = optional(list(string))
      service_cidr_label = optional(string)
    }))
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for group in var.egress_rules : [
        for rule in group.rules :
        (rule.cidr != null ? 1 : 0) + (rule.nsg_id != null ? 1 : 0) + (rule.service_cidr_label != null ? 1 : 0) == 1
      ]
    ]))
    error_message = "Each egress rule must have exactly one of 'cidr', 'nsg_id' or 'service_cidr_label'."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.egress_rules : [
        for rule in group.rules :
        contains(["tcp", "udp", "icmp", "icmpv6", "-1", "all"], rule.protocol)
      ]
    ]))
    error_message = "Egress rule protocol must be one of tcp, udp, icmp, icmpv6, -1, all."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.egress_rules : [
        for rule in group.rules :
        contains(["objectstorage", "all-services"], coalesce(rule.service_cidr_label, "objectstorage"))
      ]
    ]))
    error_message = "service_cidr_label must be 'objectstorage' or 'all-services'."
  }

  validation {
    condition = alltrue(flatten([
      for group in var.egress_rules : [
        for rule in group.rules :
        length(trimspace(rule.description)) > 0 && length(rule.description) <= 200
      ]
    ]))
    error_message = "Every egress rule needs a non-empty description under 200 characters."
  }
}

variable "nsg_rule_limit" {
  description = "Per-NSG rule ceiling used by the rules_summary output and the headroom guard. OCI's documented limit is 120 total (ingress + egress) per NSG and it is NOT increasable, so this is surfaced in a plan rather than discovered at apply."
  type        = number
  default     = 120
}

variable "vcn_id" {
  description = "OCID of the VCN, from composition/vpc-network's `vcn_id` output. Used only to scope the default-security-list guard's lookup; no rule resource needs it, because an NSG rule addresses its NSG directly."
  type        = string
  default     = null
}
