# Container Registry (OCIR): repositories plus an optional compartment-level
# access policy. The OCI counterpart of the AWS ECR / GCP artifact-registry module.

# THE LOAD-BEARING CONSTRAINT: HOW OKE ACTUALLY PULLS FROM THIS REGISTRY.
# This module creates repositories but does NOT create the credential a pod uses
# to pull. On OKE that path is not IAM-based: Oracle's documented mechanism is a
# Kubernetes `docker-registry` Secret built from a long-lived OCI **Auth Token**
# (a bearer credential on an IAM USER), referenced by every pod via
# `imagePullSecrets`. Consequences the module is built around:
#   1. NO KEYLESS MECHANISM IS INVENTED HERE. Granting a workload principal
#      `read repos` does not make an image pull work - the kubelet does the pull
#      and has no workload identity. `pull_subjects` is for human/CI principals,
#      not pods.
#   2. THIS MODULE DOES NOT CREATE THE AUTH TOKEN. `oci_identity_auth_token`
#      would write a long-lived registry password into Terraform state in
#      plaintext on the same apply that creates 130 repositories. The token and
#      the Secret belong to cluster/namespace bootstrap, with rotation designed
#      in from day one.
#   3. INSTEAD IT EMITS the two non-secret values bootstrap needs and cannot
#      compute itself: the docker-server host and the `<tenancy-namespace>/`
#      username prefix (see outputs.tf image_pull_*).
# Residual risk: a stale or revoked Auth Token breaks every image pull at once,
# with no IAM-based fallback.
data "oci_objectstorage_namespace" "this" {
  count = var.namespace == null ? 1 : 0
}

# Repositories
resource "oci_artifacts_container_repository" "this" {
  for_each = local.repositories

  compartment_id = each.value.compartment_id
  display_name   = each.value.display_name

  # All-or-nothing mutability: OCI gives one boolean and no pattern mechanism
  # (AWS's image_tag_mutability_exclusion_filter has no counterpart). A repository
  # needing mixed mutability must use TWO repositories, not a flag.
  is_immutable = each.value.is_immutable

  # Defaults false. Every repository in this fleet must be private; nothing
  # should ever publish an image publicly by accident.
  is_public = each.value.is_public

  dynamic "readme" {
    for_each = each.value.readme != null ? [each.value.readme] : []

    content {
      content = readme.value.content
      format  = readme.value.format
    }
  }

  freeform_tags = each.value.freeform_tags
  defined_tags  = each.value.defined_tags

  # IMAGE RETENTION / LIFECYCLE POLICY: NONE. THE BIGGEST GAP HERE.
  # There is no `lifecycle_policy` argument and no sibling resource - confirmed
  # by a zero-hit provider sweep and full reads of the Artifacts schemas, not by
  # not looking. Every repository therefore accumulates images forever, whereas
  # each AWS repo runs a keep-N or expire-older-than-N policy today.
  # No Terraform-native mitigation exists; the only path is out-of-band
  # automation (an OCI Function on a Resource Scheduler trigger, or a CI step)
  # calling the Artifacts API to delete by the same count/age rules. THAT
  # AUTOMATION DOES NOT EXIST YET. Until it does the failure mode is a slowly
  # growing storage bill rather than an outage - precisely why it will go
  # unnoticed.

  # Arguments a reader coming from the AWS module will look for and not find,
  # so their absence is not mistaken for an oversight:
  #   image_scanning_configuration.scan_on_push - NONE on this resource. OCI has
  #     a standalone Vulnerability Scanning Service that can target container
  #     images, but nothing inline/per-repository exists.
  #   encryption_configuration / kms_key - PARTIAL. No CMEK argument here (unlike
  #     objectstorage_bucket / file_storage_file_system). Images are
  #     Oracle-encrypted at rest.
  #   force_delete - PARTIAL. A repository holding images must be emptied out of
  #     band before Terraform can destroy it. Friction in the safe direction.
}

# Compartment-level access policy - the substitute for an ECR-style
# repository_policy. Created only when a subject is named; both lists default
# empty. OCI has no resource-attached policy, so the grant inverts to one
# identity-scoped, compartment-level statement naming a group or dynamic group.
# If the CI truly lives in a separate OCI TENANCY (the true analogue of a
# different AWS account), a compartment policy is not sufficient: cross-tenancy
# access needs Define/Endorse/Admit statements at BOTH tenancy roots - a
# negotiated trust relationship out of this module's scope.

resource "oci_identity_policy" "registry_access" {
  count = length(local.registry_statements) > 0 ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-container-registry-access"
  description    = "Push/pull access to ${var.environment} container repositories (substitute for AWS ECR repository policies)"
  statements     = local.registry_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
