# Plan-time guards for the NSG-only model. terraform_data has no provider and
# hangs lifecycle.precondition off a built-in resource - a precondition is a
# hard plan failure, unlike a `check` block which only warns.

# 1. The VCN default security list must be empty.
# OCI unions security-list and NSG rules (allow-only, no deny/priority), so the
# stock allow-all+SSH-22 default list would silently make every NSG egress rule
# decorative = fail-open. vpc-network neuters it; this module asserts it stayed
# that way. ZPR is deliberately out of scope, so this guard is the whole defence.
# OCI has no singular security-list data source, so the full set is read and
# filtered by OCID - which also surfaces any NON-default list, which must not
# exist under the NSG-only model.
data "oci_core_security_lists" "vcn" {
  count = (local.assert_default_sl || local.has_allowed_sl) ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
}

resource "terraform_data" "default_security_list_is_empty" {
  count = local.assert_default_sl ? 1 : 0

  input = var.default_security_list_id

  lifecycle {
    precondition {
      condition     = length(local.default_security_list) == 1
      error_message = "Default security list ${var.default_security_list_id} was not found among the ${length(local.discovered_security_lists)} security list(s) in compartment ${var.compartment_id}${var.vcn_id == null ? "" : " / VCN ${var.vcn_id}"}. Check compartment_id and vcn_id, or set assert_default_security_list_empty = false if planning before vpc-network has been applied."
    }

    precondition {
      condition = alltrue([
        for sl in local.default_security_list :
        length(sl.ingress_security_rules) == 0 && length(sl.egress_security_rules) == 0
      ])
      error_message = "VCN default security list ${var.default_security_list_id} is not empty. OCI unions security-list and NSG rules, so its allow-all egress and SSH-22 ingress override every NSG rule this module creates. Neuter it in composition/vpc-network (oci_core_default_security_list, zero rule blocks) before applying security-rules. Release blocker."
    }

  }
}

# 1b. No unauthorized non-default security list.
# Under the NSG-only model the default list should be the ONLY list in the VCN;
# a second one permanently widens every VNIC in its subnets. A small named
# allowlist (`allowed_non_default_security_lists`) permits only resource types
# with a VNIC but no NSG support: `bastion` (vpc-network's management list,
# egress-only) and `redis` (the OCI Cache/Valkey service's auto-created list,
# single service-port ingress). This is a HARD precondition, not a `check`,
# because an unauthorized list defeats the NSG-only model as badly as a
# populated default does. Gated on the allowlist being non-empty so a standalone
# plan before vpc-network/Redis exist still plans clean.
resource "terraform_data" "no_unauthorized_non_default_security_lists" {
  count = local.has_allowed_sl ? 1 : 0

  input = local.discovered_security_lists

  lifecycle {
    precondition {
      condition     = length(local.unauthorized_non_default_security_lists) == 0
      error_message = "VCN has non-default security list(s) other than the named allowlist in `allowed_non_default_security_lists`: ${join(", ", local.unauthorized_non_default_security_lists)}. The NSG-only model allows a non-default list only for a resource type with a VNIC but no NSG support, named explicitly. Add it to the allowlist only if so, otherwise remove it - any other non-default list is a fail-open widening of every VNIC in its subnets."
    }

    precondition {
      condition     = length(local.allowed_sl_ingress_violations) == 0
      error_message = "Allowlisted non-default security list(s) exceed their ingress budget: ${join(", ", local.allowed_sl_ingress_violations)}. The OCI Bastion service list must carry only egress (0 ingress); the OCI Cache (Valkey/Redis) service list carries only its single service-port ingress. Any ingress beyond that is an unauthorized fail-open path and must be removed."
    }
  }
}

# 2. Every service_cidr_label used must resolve to a real service CIDR.
# lookup() falls back to a sentinel so the failure is a readable message naming
# the label, not a raw "key not found".
resource "terraform_data" "service_cidr_labels_resolved" {
  count = local.has_service_cidr_rules ? 1 : 0

  input = local.service_cidr_blocks

  lifecycle {
    precondition {
      condition     = length(local.unresolved_service_labels) == 0
      error_message = "Unresolvable service_cidr_label(s): ${join(", ", local.unresolved_service_labels)}. Available in this region: ${join(", ", keys(local.service_cidr_blocks))}."
    }
  }
}

# 3. Per-NSG rule headroom.
# OCI caps an NSG at 120 rules and the limit is NOT increasable; multi-CIDR
# rules fan out, so the count scales with address-list length. Fail in plan.
resource "terraform_data" "nsg_rule_headroom" {
  count = length(local.target_nsg_ids) > 0 ? 1 : 0

  input = local.rules_by_nsg

  lifecycle {
    precondition {
      condition     = length(local.nsgs_over_rule_limit) == 0
      error_message = "These NSGs exceed the ${var.nsg_rule_limit}-rule per-NSG limit (not increasable): ${join(", ", local.nsgs_over_rule_limit)}. Note this counts only rules created by security-rules; rules created by the NSG's owning module are additional."
    }
  }
}

# 4. No rule should have an empty selector list.
# `cidr = []` / `nsg_id = []` passes the exactly-one-selector validation and then
# fans out to zero resources - an allow that quietly does not exist. Fails closed,
# so this warns rather than blocks; the common cause is a `values.ip_list` not set.
check "no_empty_selector_lists" {
  assert {
    condition     = length(local.empty_selector_rules) == 0
    error_message = "These rules have an empty cidr/nsg_id list and will create NO security rule at all: ${join(", ", local.empty_selector_rules)}. Check the stack's `values`."
  }
}
