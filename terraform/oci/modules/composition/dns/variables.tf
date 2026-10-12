# =============================================================================
# Identity / naming
# =============================================================================

variable "compartment_id" {
  description = "OCID of the compartment holding the zones, the private view and any rrsets. OCI's scoping context; replaces nothing in the AWS module, which had no equivalent axis."
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment (or root tenancy) OCID, e.g. ocid1.compartment.oc1..aaaa..."
  }
}

variable "environment" {
  description = "Environment short name (dev, integ, sandbox, prod). Used for naming and freeform tags."
  type        = string
}

variable "project_name" {
  description = "Project name used for naming and freeform tags."
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "Region identifier (e.g. ap-mumbai-1), used for freeform tags only. OCI DNS zones are global (public) or view-scoped (private); this variable does not move them."
  type        = string
  default     = null
}

variable "freeform_tags" {
  description = "Extra freeform tags merged onto every taggable resource. Replaces the AWS module's `tags`. Note oci_dns_rrset is NOT taggable - AWS's per-record tags have no counterpart."
  type        = map(string)
  default     = {}
}

# =============================================================================
# Zones and records
# =============================================================================

variable "zones" {
  description = <<-EOT
    Map of logical zone name to zone configuration, keyed like the AWS
    module's `route53_zones` (`hyperswitch_public`, `hyperswitch_internal`).

    Deliberately SIMPLER than the AWS variable on one axis: none of Route 53's
    routing policies (weighted, failover, geolocation, geoproximity, latency,
    CIDR, multivalue) are carried into the first cut. On OCI none of them is an
    attribute of a record - each needs a separate oci_dns_steering_policy plus
    an oci_dns_steering_policy_attachment, and two of them (geoproximity's
    coordinate bias, true latency-based routing) have no OCI equivalent at all.
    Every one of those policies is UNUSED by every live AWS instantiation
    reviewed - every record in the live catalog unit is a plain CNAME - so
    building the heavier OCI machinery speculatively would be porting plumbing,
    not capability. route53.md section 4 records the mapping for when a real
    consumer appears. Verdicts: features 5/6/7/10 PARTIAL, 8/9 NONE,
    11/12 SUBSTITUTE.

    Also absent: `delegation_set_id` (route53.md feature 13, NONE - OCI has no
    reusable pre-allocated nameserver set) and `health_check_id`
    (feature 12, SUBSTITUTE via a steering policy, not a record attribute).
  EOT

  type = map(object({
    # Fully qualified zone name, e.g. "dev.hyperswitch.net" or
    # "hyperswitch.internal". No trailing dot.
    name = string

    # "public"  - oci_dns_zone with no view, resolvable from the internet.
    # "private" - oci_dns_zone inside a PRIVATE view, resolvable only from
    #             VCNs whose resolver has that view attached. See resolver.tf.
    type = optional(string, "public")

    # OCI-only. AWS's module has no DNSSEC surface at all, so this is additive
    # rather than a port. Values: "ENABLED" / "DISABLED"; null leaves Oracle's
    # default. Meaningless on private zones.
    dnssec_state = optional(string)

    records = optional(map(object({
      # Relative to the zone. "" or "@" means the zone apex - which on OCI is
      # a plain A record at the load balancer's reserved IP, not an ALIAS
      # pseudo-record (route53.md feature 4, PARTIAL).
      name    = string
      type    = string
      ttl     = optional(number, 300)
      records = list(string)
    })), {})
  }))

  default = {}

  validation {
    condition     = alltrue([for k, z in var.zones : contains(["public", "private"], z.type)])
    error_message = "zones[*].type must be \"public\" or \"private\"."
  }

  validation {
    condition     = alltrue([for k, z in var.zones : !endswith(z.name, ".")])
    error_message = "zones[*].name must not carry a trailing dot."
  }

  validation {
    condition = alltrue(flatten([
      for k, z in var.zones : [for rk, r in z.records : length(r.records) > 0]
    ]))
    error_message = "Every record must carry at least one rdata value; an oci_dns_rrset with an empty items set is not a valid way to express \"no record\" - omit the entry instead."
  }
}

# =============================================================================
# VCN resolver attachment - NEW SURFACE, no AWS analogue
# =============================================================================

variable "vcn_id" {
  description = <<-EOT
    OCID of the VCN whose auto-created DNS Resolver should resolve this
    module's private zones. Required whenever any zone has type = "private"
    and attach_private_views_to_vcn_resolver is true.

    This is the cross-module dependency AWS never needed. On AWS, a private
    hosted zone and its VPC visibility are ONE resource:
    aws_route53_zone with an inline `vpc { vpc_id = ... }` block. On OCI the
    same outcome takes three objects, one of which this module does not own -
    see resolver.tf.
  EOT
  type        = string
  default     = null
}

variable "attach_private_views_to_vcn_resolver" {
  description = "Attach this module's private view to the VCN's resolver. Turning this OFF is a supported but dangerous choice: the zones and records still apply cleanly and are still completely invisible from inside the VCN. Only set it false when a separate, platform-owned unit centralises every resolver attachment (route53.md open question 3)."
  type        = bool
  default     = true
}

variable "private_view_id" {
  description = "OCID of an existing PRIVATE DNS view to place private zones in, instead of creating one. Set this when a shared, platform-owned view already exists; leave null to let this module own its view."
  type        = string
  default     = null
}

variable "additional_attached_view_ids" {
  description = <<-EOT
    Extra view OCIDs to keep attached to the VCN resolver alongside this
    module's own.

    READ THIS BEFORE LEAVING IT EMPTY: oci_dns_resolver.attached_views is
    AUTHORITATIVE. Terraform will set the resolver's attached view list to
    exactly what this module computes, silently detaching anything another
    unit or a console operator attached out of band. If a second unit also
    attaches a view to the same VCN resolver, one of the two must list the
    other's view here or the two will fight on every apply.
  EOT
  type        = list(string)
  default     = []
}

variable "resolver_display_name" {
  description = "Display name to set on the VCN's resolver. Null leaves whatever OCI generated when it auto-created the resolver with the VCN. Setting it renames a resource this module does not own - harmless, but visible to everyone else looking at that VCN."
  type        = string
  default     = null
}
