# ONE conditional resource, and NO `oci_identity_policy`. The AWS module's three
# resources (role, role-policy, attachment) have no counterpart - there is no
# annotation to set on the Kubernetes side. The identity itself is
# `policy_statements` in outputs.tf, concatenated by the orchestrator into the
# environment's single shared oke-workload-identity policy object.

# Cross-compartment reach. Needed ONLY when the vault's compartment is outside
# the cluster's own compartment subtree; the recommended layout puts both under
# the environment compartment, so this is off by default.
#
# Namespace-granular by design: a workload mapping applies to ALL workloads in
# the namespace, so it widens reach and never narrows it. The service-account
# condition in the statements remains the only fine-grained control.
resource "oci_containerengine_cluster_workload_mapping" "vault" {
  for_each = var.create_workload_mapping ? toset(var.cluster_ids) : toset([])

  cluster_id            = each.value
  namespace             = var.k8s_namespace
  mapped_compartment_id = local.secrets_compartment_id

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = local.secrets_compartment_id != var.compartment_id
      error_message = "create_workload_mapping is true but the vault compartment equals the environment compartment. A mapping inside the cluster's own subtree grants nothing extra and adds a namespace-granular object for no reason - leave it false."
    }
  }
}
