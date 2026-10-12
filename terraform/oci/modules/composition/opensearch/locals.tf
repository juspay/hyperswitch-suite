locals {
  name_prefix = "${var.environment}-${var.project_name}"

  display_name = coalesce(var.display_name, "${local.name_prefix}-opensearch")

  freeform_tags = merge(
    {
      environment = var.environment
      project     = var.project_name
      component   = "opensearch"
      managed_by  = "terraform"
    },
    var.freeform_tags
  )

  # OCI takes compartment context for the VCN and the subnet independently of the
  # cluster's own compartment; defaulting both to compartment_id reproduces the
  # AWS single-account assumption while leaving the split available.
  vcn_compartment_id    = coalesce(var.vcn_compartment_id, var.compartment_id)
  subnet_compartment_id = coalesce(var.subnet_compartment_id, var.compartment_id)

  # Exactly one NSG: the cluster resource's nsg_id is a single string, not a set,
  # so AWS's "several existing security groups" has no expressible counterpart.
  nsg_id = var.create_nsg ? oci_core_network_security_group.this[0].id : var.nsg_id

  # Service control-plane authorization. The service-principal name is INFERRED
  # from how other network-attached OCI managed services are granted VCN access,
  # not confirmed for opensearch; a wrong name fails the apply cleanly and visibly.
  policy_scope_compartment = coalesce(var.tenancy_ocid, var.compartment_id)

  default_service_policy_statements = [
    "Allow service opensearch to use virtual-network-family in compartment id ${var.compartment_id}",
  ]

  service_policy_statements = length(var.service_policy_statements) > 0 ? var.service_policy_statements : local.default_service_policy_statements

  # Endpoints. AWS returned kibana_url and kibana_url_legacy (both derived from
  # the dashboard endpoint); one is enough here.
  kibana_url = try("https://${oci_opensearch_opensearch_cluster.this.opendashboard_fqdn}", null)
}
