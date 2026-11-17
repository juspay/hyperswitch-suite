locals {
  name_prefix = "${var.environment}-${var.project_name}"

  # Replaces the AWS module's domain-name fallback logic, same shape.
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
  # cluster's own compartment. Defaulting both to compartment_id reproduces the
  # AWS single-account assumption while leaving the split available.
  vcn_compartment_id    = coalesce(var.vcn_compartment_id, var.compartment_id)
  subnet_compartment_id = coalesce(var.subnet_compartment_id, var.compartment_id)

  # Exactly one NSG. The cluster resource's nsg_id is a single string, not a set,
  # so AWS's "several existing security groups" has no expressible counterpart.
  nsg_id = var.create_nsg ? oci_core_network_security_group.this[0].id : var.nsg_id

  # ---------------------------------------------------------------------------
  # Service control-plane authorization (section 4.6)
  # ---------------------------------------------------------------------------
  # VERIFIED 2026-11-17 against Oracle's own prerequisite documentation for
  # this exact resource (registry.terraform.io/providers/oracle/oci
  # oci_opensearch_opensearch_cluster, "Prerequisites", mirrored at
  # docs.oracle.com/en-us/iaas/Content/search-opensearch/Concepts/importingacluster.htm
  # and ocisearchpermissions.htm): the service principal is `opensearch`, and
  # the documented statement set is FOUR grants, not one aggregate:
  #
  #   Allow service opensearch to manage vnics in compartment id <...>
  #   Allow service opensearch to use subnets in compartment id <...>
  #   Allow service opensearch to use network-security-groups in compartment id <...>
  #   Allow service opensearch to manage vcns in compartment id <...>
  #
  # The original inference here was a single `use virtual-network-family`
  # aggregate. That is INSUFFICIENT against Oracle's documented set: the
  # control plane needs `manage vnics` (it creates the cluster node VNICs)
  # and `manage vcns`, which a use-level aggregate never grants. The four
  # statements below match Oracle's documentation verbatim (modulo the
  # `compartment id <ocid>` form oke-cluster-iam established to avoid the
  # named-compartment lowercasing diff).
  policy_scope_compartment = coalesce(var.tenancy_ocid, var.compartment_id)

  default_service_policy_statements = [
    "Allow service opensearch to manage vnics in compartment id ${var.compartment_id}",
    "Allow service opensearch to use subnets in compartment id ${var.compartment_id}",
    "Allow service opensearch to use network-security-groups in compartment id ${var.compartment_id}",
    "Allow service opensearch to manage vcns in compartment id ${var.compartment_id}",
  ]

  # The policy is written through the ALIASED oci.home provider (see
  # identity.tf): one module, one unit, two provider configurations - the
  # cluster regional, the IAM write homed in the tenancy home region.
  service_policy_raw_statements = length(var.service_policy_statements) > 0 ? var.service_policy_statements : local.default_service_policy_statements

  # Normalisation: collapse whitespace, tighten spaces around operators and
  # comma lists, so contributed statements compare stable against the form the
  # OCI API stores and returns.
  service_policy_statements = sort(distinct([
    for s in local.service_policy_raw_statements :
    replace(
      replace(
        replace(
          replace(trimspace(s), "/\\s+/", " "),
        "/\\s*(!?=)\\s*/", "$1"),
      "/,\\s+/", ","),
    "/\\{\\s+|\\s+\\}/", "")
  ]))

  # Guard inputs for the identity.tf preconditions.
  service_policy_statements_without_service_principal = [
    for s in local.service_policy_statements : s
    if length(regexall("(?i)service opensearch", s)) == 0
  ]

  service_policy_statements_with_named_compartment = [
    for s in local.service_policy_statements : s
    if length(regexall(" in compartment ", s)) > 0 && length(regexall(" in compartment id ", s)) == 0
  ]

  # oci_identity_policy.name is tenancy-unique and NOT UPDATABLE - decide once,
  # then leave it alone. Default derives from the cluster display name, e.g.
  # "prd-hyperswitch-opensearch-service-policy".
  service_policy_name = coalesce(
    var.service_policy_name,
    "${local.display_name}-service-policy"
  )

  service_policy_description = coalesce(
    var.service_policy_description,
    "Allows the OCI Search with OpenSearch control plane to attach ${local.display_name} to the customer VCN"
  )

  # ---------------------------------------------------------------------------
  # Endpoints
  # ---------------------------------------------------------------------------
  # AWS returned kibana_url and kibana_url_legacy, both derived from the
  # dashboard endpoint. One is enough here; the "legacy" variant existed only
  # because Amazon renamed Kibana to Dashboards mid-life.
  kibana_url = try("https://${oci_opensearch_opensearch_cluster.this.opendashboard_fqdn}", null)
}
