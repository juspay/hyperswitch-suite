# =============================================================================
# Container Registry (OCIR) - the OCI counterpart of
# aws/modules/composition/ecr and gcp/modules/composition/artifact-registry.
#
# Check sheet: hyperswitch-infra/docs/multi-cloud-parity/oci/modules/ecr.md
# Parity headline recorded there: 2 FULL / 4 PARTIAL / 1 SUBSTITUTE / 2 NONE.
#
# Named after the OCI product ("Container Registry" / OCIR), not after ECR. The
# provider subcategory is "Artifacts"; both names refer to the same service.
# =============================================================================

# -----------------------------------------------------------------------------
# THE LOAD-BEARING CONSTRAINT: HOW OKE ACTUALLY PULLS FROM THIS REGISTRY
# -----------------------------------------------------------------------------
# This module creates repositories. It does NOT create the credential a pod uses
# to pull from them, and it deliberately cannot.
#
# On AWS the EKS worker node's IAM role calls ecr:GetAuthorizationToken and the
# kubelet pulls with a short-lived token. There is no Kubernetes Secret, nothing
# to rotate, nothing stored anywhere.
#
# On OKE that path does not exist. Oracle's documented - and only documented -
# mechanism (docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengpullingimagesfromocir.htm,
# fetched in full for the check sheet) is a Kubernetes `docker-registry` Secret
# built from an OCI **Auth Token**: a user-generated, long-lived bearer
# credential attached to an IAM USER, not an instance principal and not a
# workload identity. Every pod spec pulling a private image references it via
# `imagePullSecrets`.
#
#     kubectl create secret docker-registry <name> \
#       --docker-server=<ocir-endpoint> \
#       --docker-username='<tenancy-namespace>/<oci-username>' \
#       --docker-password='<auth-token>'
#
# Three consequences this module is built around rather than papering over:
#
#   1. NO KEYLESS MECHANISM IS INVENTED HERE. OKE workload identity
#      (docs/multi-cloud-parity/oci/identity-model.md, the decided model for
#      pod-to-OCI-service auth) governs calls a pod's SDK makes. It does NOT
#      govern the kubelet's image pull - the kubelet is not running the OCI SDK
#      and has no workload identity. `read repos` granted to a workload
#      principal does not make an image pull work. The pull_subjects variable
#      exists for human/CI principals, not for pods.
#
#   2. THIS MODULE DOES NOT CREATE THE AUTH TOKEN. `oci_identity_auth_token`
#      exists in the provider, and using it here would write a long-lived
#      registry password into Terraform state in plaintext, on the same apply
#      that creates 130 repositories. That is worse than the gap. The token and
#      the resulting Kubernetes Secret belong to cluster/namespace bootstrap -
#      the oke-kubernetes-resources-equivalent layer - with rotation designed in
#      from day one, per the check sheet's section 4 proposal.
#
#   3. WHAT THIS MODULE DOES INSTEAD is emit exactly the two non-secret values
#      that bootstrap step needs and cannot compute for itself: the docker-server
#      host and the `<tenancy-namespace>/` username prefix. See outputs.tf's
#      image_pull_* outputs.
#
# Residual risk, recorded: a stale or revoked Auth Token breaks every image pull
# on the cluster at once, with no IAM-based fallback. Oracle gate item, check
# sheet section 8 item 4 - NOT YET CONSULTED.
# -----------------------------------------------------------------------------

# Read-only lookup of the tenancy namespace. Only queried when the caller did
# not supply one. Cheap enough that the check sheet explicitly prefers
# duplicating it over creating a cross-module dependency on
# object-storage-backend.
data "oci_objectstorage_namespace" "this" {
  count = var.namespace == null ? 1 : 0
}

# -----------------------------------------------------------------------------
# Repositories
# -----------------------------------------------------------------------------
resource "oci_artifacts_container_repository" "this" {
  for_each = local.repositories

  compartment_id = each.value.compartment_id
  display_name   = each.value.display_name

  # Feature 3, PARTIAL. AWS's image_tag_mutability is a three-state field with a
  # companion image_tag_mutability_exclusion_filter that can carve out tag
  # patterns (keep releases immutable, let `dev-*` be re-pushed). OCI gives one
  # boolean and no pattern mechanism. If a repository ever needs mixed
  # mutability, the workaround is TWO repositories, not a flag - a naming
  # convention change, which is why it is not hidden behind a module default.
  is_immutable = each.value.is_immutable

  # Defaults false. Every AWS repository reviewed is private, and nothing in
  # this fleet should ever publish an image publicly by accident.
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

  # ---------------------------------------------------------------------------
  # FEATURE 7 - IMAGE RETENTION / LIFECYCLE POLICY: NONE. THE BIGGEST GAP HERE.
  #
  # There is no `lifecycle_policy` argument here and no sibling resource to
  # create one with, because none exists. This was established by a zero-hit
  # sweep, not by not finding one: `search_providers` for "retention" across the
  # ENTIRE oracle/oci provider (995 resources, not just Artifacts) returned no
  # relevant result, and the artifacts_container_repository and
  # artifacts_container_configuration schemas were both read in full. The only
  # other Artifacts resource, artifacts_container_image_signature, governs image
  # SIGNING, not retention. Re-verified against the locally cached provider
  # schema for oracle/oci 9.0.0 while writing this module.
  #
  # Every one of the ~130 AWS repositories per environment runs one of two
  # active lifecycle policies today (keep N most recent tagged images, or expire
  # images older than N days). On OCI, every repository accumulates images
  # forever.
  #
  # No Terraform-native mitigation is available to write here. The only path is
  # out-of-band automation - an OCI Function on a Resource Scheduler trigger, or
  # a CI step - calling the Artifacts API to list and delete images by the same
  # count/age rules. THAT AUTOMATION DOES NOT EXIST. Until it does, this module
  # is not at parity, and the failure mode is a slowly growing storage bill
  # rather than an outage, which is precisely why it will go unnoticed.
  #
  # Oracle gate item, check sheet section 8 item 3 - NOT YET CONSULTED.
  # ---------------------------------------------------------------------------

  # ---------------------------------------------------------------------------
  # Three more arguments a reader coming from the AWS module will look for and
  # not find, so their absence is not mistaken for an oversight:
  #
  #   image_scanning_configuration.scan_on_push  feature 4, NONE on this
  #     resource. The AWS module defaults it TRUE and no live root overrides it,
  #     so scanning on every push is today's baseline, not an extra. OCI has a
  #     standalone Vulnerability Scanning Service that can target container
  #     images, but nothing inline and per-repository was found, and whether it
  #     can be made push-triggered is check sheet open question 1. Recorded as a
  #     real gap rather than assumed closed.
  #
  #   encryption_configuration / kms_key         feature 5, PARTIAL. No CMEK
  #     argument on this resource, in contrast with objectstorage_bucket and
  #     file_storage_file_system which both expose kms_key_id. Images are
  #     Oracle-encrypted at rest; whether a customer-managed key is reachable by
  #     some other mechanism is check sheet open question 2. No live root sets a
  #     non-default key on AWS today, so this is unlikely to block.
  #
  #   force_delete                               feature 8, PARTIAL. Nothing
  #     equivalent. A repository holding images must be emptied out of band
  #     before Terraform can destroy it. Friction in the safe direction.
  # ---------------------------------------------------------------------------
}

# -----------------------------------------------------------------------------
# Compartment-level access policy - the SUBSTITUTE for aws_ecr_repository_policy
# -----------------------------------------------------------------------------
# Created only when a subject is named; both lists default empty. The AWS side
# attaches an identical resource-based document to every one of ~130
# repositories, granting a Jenkins CI role in a DIFFERENT AWS account push and
# pull. OCI has no resource-based policy of any kind here, so the grant inverts:
# one identity-scoped statement, attached to a compartment, naming a group or
# dynamic group.
#
# If the CI system genuinely lives in a separate OCI TENANCY - the true analogue
# of a different AWS account - this is not sufficient. Cross-tenancy access
# needs Define/Endorse/Admit statements at BOTH tenancy roots, which is a
# negotiated trust relationship rather than a principal string, and is out of
# this module's scope (identity-model.md section 4.3).
#
# Oracle gate item, check sheet section 8 item 2 - NOT YET CONSULTED. The
# mechanism is here; the decision to adopt it is not made.
resource "oci_identity_policy" "registry_access" {
  count = length(local.registry_statements) > 0 ? 1 : 0

  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-container-registry-access"
  description    = "Push/pull access to ${var.environment} container repositories (substitute for AWS ECR repository policies)"
  statements     = local.registry_statements

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
