# =========================================================================
# PLAN-TIME GUARDS
# =========================================================================
# terraform_data is a built-in resource (no provider), used purely to hang
# lifecycle.precondition blocks off. A precondition is a hard plan failure,
# unlike a `check` block which only warns - and each of these is a condition
# under which the NSG-only model is quietly not in force.
# =========================================================================

# -------------------------------------------------------------------------
# 1. The VCN default security list must be empty.
#
# THE FAIL-OPEN RISK, in one place. OCI evaluates security lists and NSGs as
# a UNION: "a packet is allowed to reach VNIC 1 if ANY rule in ANY of the
# relevant lists and groups allows the traffic." Rules are allow-only - there
# is no deny rule and no priority ordering - so an NSG can never narrow what a
# security list has already opened. The stock default security list carries
# allow-all egress plus SSH-22 ingress, and any subnet that does not set
# security_list_ids inherits it. On AWS the equivalent default
# (aws_default_security_group) is inert unless something is attached to it; on
# OCI it applies by default. If it is not neutered, every egress rule this
# module writes is decorative and the whole NSG-only model is fail-open.
#
# vpc-network owns the fix (oci_core_default_security_list with zero rule
# blocks, plus explicit security_list_ids on every subnet). This module owns
# the assertion, because it is the module whose correctness depends on it.
#
# ZPR (Zero Trust Packet Routing) is the only OCI mechanism that ANDs rather
# than unions, and is therefore the only way to narrow an over-broad NSG. It
# is deliberately out of scope for the first cut - see network-security-model.md
# §3.5 - which means this guard is the entire defence for now.
# -------------------------------------------------------------------------
# The provider exposes no singular oci_core_security_list DATA source (only the
# managed resource), so the whole VCN's list set is read and filtered by OCID.
# That is strictly better for this purpose: it also makes visible any NON-default
# security list, which the NSG-only model says must not exist at all
# (network-security-model.md §5.1, "no composition module creates an
# oci_core_security_list").
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

# -------------------------------------------------------------------------
# 1b. No unauthorized non-default security list.
#
# Under the NSG-only model the default list should be the ONLY security list in
# the VCN, and a second one is a permanent, un-narrowable widening of every VNIC
# in the subnets it is attached to. The model tolerates a small named allowlist
# of exceptions (variables.tf `allowed_non_default_security_lists`), each for a
# resource type with a VNIC but no (or partial) NSG support - verified here:
#   - `bastion`: vpc-network's dedicated management-bastion list, carrying the
#     OCI Bastion service's data-plane egress only (0 ingress).
#   - `redis`: the OCI Cache (Valkey/Redis) service's automatically-created
#     list for its managed VNICs (single service-port ingress, e.g. 6379).
#
# This is a HARD plan failure (precondition), not an advisory `check`, because an
# unauthorized non-default list silently defeats the NSG-only model exactly as
# badly as a populated default one does - it unions extra allow rules under every
# NSG (network-security-model.md section 5.1). Gated on the allowlist being
# non-empty, so a standalone plan before vpc-network's security-list output
# exists (or before the Redis cluster creates its list) still plans clean.
# -------------------------------------------------------------------------
resource "terraform_data" "no_unauthorized_non_default_security_lists" {
  count = local.has_allowed_sl ? 1 : 0

  input = local.discovered_security_lists

  lifecycle {
    precondition {
      condition     = length(local.unauthorized_non_default_security_lists) == 0
      error_message = "VCN has non-default security list(s) other than the named allowlist in `allowed_non_default_security_lists`: ${join(", ", local.unauthorized_non_default_security_lists)}. The NSG-only model (network-security-model.md section 5) allows a non-default list only for a resource type with a VNIC but no NSG support, named explicitly. Add it to the allowlist only if so, otherwise remove it - any other non-default list is a fail-open widening of every VNIC in its subnets."
    }

    precondition {
      condition     = length(local.allowed_sl_ingress_violations) == 0
      error_message = "Allowlisted non-default security list(s) exceed their ingress budget: ${join(", ", local.allowed_sl_ingress_violations)}. The OCI Bastion service list must carry only egress (0 ingress); the OCI Cache (Valkey/Redis) service list carries only its single service-port ingress. Any ingress beyond that is an unauthorized fail-open path and must be removed."
    }
  }
}

# -------------------------------------------------------------------------
# 2. Every service_cidr_label used must resolve to a real service CIDR.
#
# lookup() falls back to a sentinel rather than erroring so the failure is a
# readable message naming the label, not a raw "key not found".
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# 3. Per-NSG rule headroom.
#
# OCI caps an NSG at 120 rules total (ingress + egress) and the limit is NOT
# increasable. Because multi-CIDR rules fan out (locals.tf), rule count now
# scales with the length of address lists like office_ips - so the ceiling is
# something a config change can walk into. Fail in plan, not at apply.
# -------------------------------------------------------------------------
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

# -------------------------------------------------------------------------
# 4. No rule should have an empty selector list.
#
# `cidr = []` or `nsg_id = []` passes the exactly-one-selector validation and
# then fans out to zero resources - an allow that quietly does not exist. It
# fails closed, so this warns rather than blocks; the usual cause is a stack
# that has not set `values.ip_list` yet.
# -------------------------------------------------------------------------
check "no_empty_selector_lists" {
  assert {
    condition     = length(local.empty_selector_rules) == 0
    error_message = "These rules have an empty cidr/nsg_id list and will create NO security rule at all: ${join(", ", local.empty_selector_rules)}. Check the stack's `values`."
  }
}
