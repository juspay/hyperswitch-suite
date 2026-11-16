# -----------------------------------------------------------------------------
# ONE conditional resource, and NO `oci_identity_policy`.
#
# The AWS module's three resources - aws_iam_role, aws_iam_role_policy,
# aws_iam_role_policy_attachment - have no counterpart here. There is no role to
# create, no policy document to attach, and nothing on the Kubernetes side to
# mutate: OCI needs no equivalent of `eks.amazonaws.com/role-arn`. Hence no
# `provider "kubernetes"` block either, unlike the GCP module on `main` - which
# additionally cannot plan as committed, because its unit passes neither
# `cluster_endpoint` nor `cluster_ca_certificate`.
#
# The identity itself is `policy_statements` in outputs.tf, concatenated by the
# orchestrator into the environment's single shared oke-workload-identity policy
# object.
# -----------------------------------------------------------------------------

# Cross-compartment reach. Needed ONLY when the vault's compartment is outside
# the cluster's own compartment subtree; the recommended layout puts both under
# the environment compartment, so this is off by default and should stay off.
#
# Namespace-granular by design - Oracle: "a workload mapping applies to all
# workloads in the specified namespace on the cluster. Use IAM policy conditions
# such as request.principal.service_account for finer-grained access." So this
# resource widens reach; it never narrows it. The service-account condition in
# the statements remains the only fine-grained control.
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
