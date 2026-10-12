# Service control-plane authorization (the AWS service-linked-role substitute).
# OCI has no service-linked-role object; the equivalent is a service POLICY
# granting a named service principal use of the virtual-network family in a
# compartment, which must exist BEFORE the first cluster can attach to a
# customer VCN. There is no service_linked_role_arn/_name to output. This is
# usually a compartment-level, once-per-tenancy concern, so create_service_policy
# defaults to FALSE (a second policy here would be duplication). THE SERVICE
# PRINCIPAL NAME IS AN INFERENCE - not confirmed for opensearch specifically; if
# it is wrong the apply fails cleanly and visibly, which is why shipping the
# inference is better than shipping nothing. Override with
# var.service_policy_statements.

resource "oci_identity_policy" "service" {
  count = var.create_service_policy ? 1 : 0

  compartment_id = local.policy_scope_compartment
  name           = "${local.display_name}-service-policy"
  description    = "Allows the OCI Search with OpenSearch control plane to attach ${local.display_name} to the customer VCN"

  statements = local.service_policy_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
