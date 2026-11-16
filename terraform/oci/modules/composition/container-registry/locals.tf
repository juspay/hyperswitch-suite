locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # The tenancy namespace, either supplied or looked up. Everything URL-shaped
  # below hangs off this - NOT off the compartment, which never appears in a
  # pull URL (check sheet feature 2).
  namespace = var.namespace != null ? var.namespace : data.oci_objectstorage_namespace.this[0].namespace

  ocir_endpoint = var.ocir_endpoint != null ? var.ocir_endpoint : "${var.region}.ocir.io"

  # `<region>.ocir.io/<tenancy-namespace>` - the closest counterpart to AWS's
  # `registry_url` output (`<account>.dkr.ecr.<region>.amazonaws.com`).
  registry_url = "${local.ocir_endpoint}/${local.namespace}"

  freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "container-registry"
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  # Resolved repository shape. display_name is the namespace-unique OCIR path;
  # see variables.tf's collision warning for why the prefix is not optional in
  # practice even though it defaults to "".
  repositories = {
    for key, cfg in var.repositories : key => {
      display_name   = cfg.display_name != null ? cfg.display_name : "${var.repository_name_prefix}${key}"
      compartment_id = cfg.compartment_id != null ? cfg.compartment_id : var.compartment_id
      is_immutable   = cfg.is_immutable != null ? cfg.is_immutable : var.default_is_immutable
      is_public      = cfg.is_public
      readme         = cfg.readme
      freeform_tags  = merge(local.freeform_tags, cfg.freeform_tags)
      defined_tags   = merge(var.defined_tags, cfg.defined_tags)
    }
  }

  # ---------------------------------------------------------------------------
  # IAM statements - the SUBSTITUTE for aws_ecr_repository_policy (feature 6).
  #
  # Verbs from Oracle's registry policy reference: `manage repos` covers the
  # push permissions the AWS document grants (BatchCheckLayerAvailability,
  # PutImage, UploadLayerPart, CompleteLayerUpload, InitiateLayerUpload) plus
  # delete; `read repos` is REPOSITORY_READ, the pull half.
  # (docs.oracle.com/en-us/iaas/Content/Identity/Reference/registrypolicyreference.htm,
  # cited in identity-model.md section 3.5.)
  #
  # Statements are emitted pre-normalised and SORTED: the OCI API rewrites
  # statement strings server-side (lowercased compartment names, whitespace
  # stripped) and an unstable order produces a perpetual Terraform diff.
  # identity-model.md section 4.5 documents this; `compartment id <ocid>` rather
  # than `compartment <name>` is used for the same reason.
  #
  # One statement per subject, compartment-scoped - deliberately NOT one per
  # repository. The AWS fleet carries the same document on ~130 repositories;
  # collapsing that into one statement is the blast-radius improvement the check
  # sheet's feature 6 note calls out as the silver lining of a forced change.
  # ---------------------------------------------------------------------------
  registry_statements = sort(concat(
    [for subject in var.push_subjects :
      "Allow ${subject} to manage repos in compartment id ${var.compartment_id}"
    ],
    [for subject in var.pull_subjects :
      "Allow ${subject} to read repos in compartment id ${var.compartment_id}"
    ],
  ))
}
