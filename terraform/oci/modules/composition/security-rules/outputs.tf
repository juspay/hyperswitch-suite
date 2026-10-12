# Security rules outputs (OCI)
output "ingress_rule_ids" {
  description = "Map of ingress NSG security rule IDs grouped by target NSG OCID"
  value = {
    for nsg_id in distinct([for k, v in local.ingress_rules_flat : v.nsg_id]) :
    nsg_id => {
      for k, v in oci_core_network_security_group_security_rule.ingress :
      k => v.id if v.network_security_group_id == nsg_id
    }
  }
}

output "egress_rule_ids" {
  description = "Map of egress NSG security rule IDs grouped by target NSG OCID"
  value = {
    for nsg_id in distinct([for k, v in local.egress_rules_flat : v.nsg_id]) :
    nsg_id => {
      for k, v in oci_core_network_security_group_security_rule.egress :
      k => v.id if v.network_security_group_id == nsg_id
    }
  }
}

output "service_cidr_blocks" {
  description = "Service gateway CIDR labels resolved for this region, keyed by the alias the live layer uses ('objectstorage', 'all-services'). Replaces the hand-maintained per-region s3_prefix_list_id root local."
  value       = local.service_cidr_blocks
}

output "rules_summary" {
  description = <<-EOT
    Audit summary of the rules this module created. Extends the AWS output with
    two OCI-specific facts:
      rules_by_nsg  - per-NSG counts against the non-increasable 120/NSG limit,
                      which matters here because multi-CIDR rules fan out.
      invalid_rules - rules whose is_valid attribute is false. OCI flips this
                      when a referenced peer NSG is deleted; traffic stops but
                      the plan stays clean, so this is a better dangling-
                      reference signal than AWS gives. Fail the validation rung
                      on any entry.
  EOT
  value = {
    total_ingress_rules = length(local.ingress_rules_flat)
    total_egress_rules  = length(local.egress_rules_flat)
    total_rules         = length(local.ingress_rules_flat) + length(local.egress_rules_flat)

    by_selector = {
      network_security_group = length([for r in local.all_rules_flat : r.key if r.target_type == "NETWORK_SECURITY_GROUP"])
      cidr_block             = length([for r in local.all_rules_flat : r.key if r.target_type == "CIDR_BLOCK"])
      service_cidr_block     = length([for r in local.all_rules_flat : r.key if r.target_type == "SERVICE_CIDR_BLOCK"])
    }

    by_component = merge(
      { for name, group in var.ingress_rules : name => length([for r in local.ingress_flat_list : r.key if r.component == name]) },
      { for name, group in var.egress_rules : name => length([for r in local.egress_flat_list : r.key if r.component == name]) },
    )

    ingress_by_nsg = {
      for nsg_id in distinct([for k, v in local.ingress_rules_flat : v.nsg_id]) :
      nsg_id => length([for k, v in local.ingress_rules_flat : k if v.nsg_id == nsg_id])
    }

    egress_by_nsg = {
      for nsg_id in distinct([for k, v in local.egress_rules_flat : v.nsg_id]) :
      nsg_id => length([for k, v in local.egress_rules_flat : k if v.nsg_id == nsg_id])
    }

    rules_by_nsg   = local.rules_by_nsg
    nsg_rule_limit = var.nsg_rule_limit

    # An NSG with rules but no VNICs attached is silently inert. Rules are
    # allow-only, so the symptom is a connectivity failure rather than an
    # exposure - it fails closed - but this makes the target set reviewable.
    target_nsg_count = length(local.target_nsg_ids)

    invalid_rules = concat(
      [for k, v in oci_core_network_security_group_security_rule.ingress : k if v.is_valid == false],
      [for k, v in oci_core_network_security_group_security_rule.egress : k if v.is_valid == false],
    )
  }
}
