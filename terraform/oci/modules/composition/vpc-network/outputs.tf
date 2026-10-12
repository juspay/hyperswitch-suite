# Output contract. Every other OCI unit reads this module; the names below are
# a contract. OCIDs replace ARNs throughout, so vpc_arn and every *_subnet_arns
# output has no counterpart.
#
# Deliberately ABSENT, each a recorded gap rather than a silent drop:
#   - vpc_endpoint_security_group_id: a service gateway has no VNIC, so no NSG
#     to attach and no id to export. The live security-rules ingress group
#     inverts to per-consumer NSG egress rules to SERVICE_CIDR_BLOCK.
#   - nacl_id / nacl_arn: OCI has no object distinct from security lists that
#     plays the NACL role, and the AWS instance is allow-all in both directions
#     so it enforces nothing. Not ported; no consumer reads them.
#   - the per-tier *_subnet_ids / *_subnet_cidr_blocks / *_route_table_id
#     outputs: collapsed into the by-tier maps below.

output "vcn_id" {
  description = "OCID of the VCN. Replaces AWS's vpc_id."
  value       = oci_core_vcn.this.id
}

output "vcn_cidr_blocks" {
  description = "IPv4 CIDR blocks of the VCN. Replaces AWS's vpc_cidr_block plus vpc_secondary_cidr_blocks - OCI models both as one list. security-rules reads this for its VCN-CIDR rules."
  value       = oci_core_vcn.this.cidr_blocks
}

output "subnets_by_tier" {
  description = "Map of tier name to subnet OCID (external-incoming, management, oke-nodes, oke-pods, oke-api-endpoint, database, locker-database, locker-server, cache, data-stack, incoming-envoy, outgoing-proxy, utils, plus any custom subnets). One value per tier, not a list: subnets are regional, so there is no per-AZ fan-out to index."
  value       = { for tier, subnet in oci_core_subnet.this : tier => subnet.id }
}

output "subnet_cidrs_by_tier" {
  description = "Map of tier name to subnet CIDR block. Replaces the 13 AWS *_subnet_cidr_blocks outputs."
  value       = { for tier, subnet in oci_core_subnet.this : tier => subnet.cidr_block }
}

output "route_tables_by_name" {
  description = "Map of route-table catalogue name to OCID. Replaces the 13 AWS *_route_table_id outputs."
  value       = { for name, rt in oci_core_route_table.this : name => rt.id }
}

output "service_route_suppressed_route_tables" {
  description = "Route tables whose service-gateway rule was deliberately omitted because they also carry an internet-gateway rule and the gateway is on the all-services CIDR label - Oracle rejects that pair at create time with 400-InvalidParameter and its Console prohibits it (known_issues_for_networking.htm, sgw-route-rule-conflict). EXPECTED TO BE EMPTY: since correction C7 no table in the catalogue is both internet-bearing and service-bearing, so this is a guardrail against a future public+service-gateway table (a custom_subnets tier, or a new catalogue entry), not an active workaround. A NON-EMPTY value in a plan means someone has reintroduced that combination and a tier is silently losing its private Oracle-services path. See locals.tf."
  value       = local.service_route_suppressed_route_tables
}

output "internet_gateway_id" {
  description = "OCID of the internet gateway, or null when create_internet_gateway = false"
  value       = try(oci_core_internet_gateway.this[0].id, null)
}

output "nat_gateway_id" {
  description = "OCID of the NAT gateway, or null when enable_nat_gateway = false. Singular: OCI's NAT gateway is regional and limited to 1 per VCN."
  value       = try(oci_core_nat_gateway.this[0].id, null)
}

output "nat_public_ip" {
  description = "Public egress IP of the NAT gateway - the single address a PSP or bank allowlists. Singular, replacing AWS's nat_gateway_public_ips list. Pinned across gateway replacement only when nat_reserved_public_ip_id is set."
  value       = try(oci_core_nat_gateway.this[0].nat_ip, null)
}

output "service_gateway_id" {
  description = "OCID of the service gateway. Replaces AWS's gateway_vpc_endpoint_ids and interface_vpc_endpoint_ids - 1 S3 gateway endpoint plus 19 interface endpoints collapse into this one regional resource."
  value       = try(oci_core_service_gateway.this[0].id, null)
}

output "object_storage_service_cidr" {
  description = "Value of the \"OCI <region> Object Storage\" service CIDR label. This is what an NSG rule needs as its destination when destination_type = \"SERVICE_CIDR_BLOCK\" - NSG rules may use either label regardless of which one the service gateway itself carries, so this stays resolvable even when the gateway is on the all-services label."
  value       = local.object_storage_service_cidr
}

output "all_services_service_cidr" {
  description = "Value of the \"All <region> Services in Oracle Services Network\" service CIDR label - the superset that includes Object Storage. security-rules needs it to express the per-consumer egress allowlist for non-Object-Storage Oracle APIs. Additive, so no existing consumer breaks."
  value       = try(local.all_osn_services[0].cidr_block, null)
}

output "local_peering_gateway_ids" {
  description = "Map of peering name to local peering gateway OCID (same-region peering). Half of what AWS's vpc_peering_connection_ids covered; see remote_peering_connection_ids for the cross-region half."
  value       = { for name, lpg in oci_core_local_peering_gateway.this : name => lpg.id }
}

output "drg_id" {
  description = "OCID of the Dynamic Routing Gateway this VCN is attached to, whether created here or supplied. null when neither create_drg nor drg_id is set. No AWS analogue - cross-region peering, FastConnect and Site-to-Site VPN all terminate here rather than on the network itself."
  value       = var.drg_id != null ? var.drg_id : try(oci_core_drg.this[0].id, null)
}

output "remote_peering_connection_ids" {
  description = "Map of peering name to remote peering connection OCID (cross-region peering over the DRG). Note that peer routes target the DRG, not the RPC - the RPC is the session, the DRG is the route target."
  value       = { for name, rpc in oci_core_remote_peering_connection.this : name => rpc.id }
}

output "default_security_list_id" {
  description = "OCID of the VCN's default security list, which this module manages down to ZERO rules. Exported so a validation step can assert emptiness: because security-list rules union (OR) with NSG rules, a non-empty default list silently defeats the NSG-only security model and is a release blocker."
  value       = oci_core_default_security_list.this.id
}

output "management_bastion_security_list_id" {
  description = "OCID of the dedicated management-subnet / OCI Bastion security list, or null when the management tier is absent. The single legitimate non-default security list: the OCI Bastion service VNIC has no NSG support, so its data-plane egress is governed only by this list. Exported so composition/security-rules' guard can assert it is the ONLY non-default list carrying exactly the bastion egress rules."
  value       = can(local.named_subnets.management.cidr) ? oci_core_security_list.management_bastion[0].id : null
}
