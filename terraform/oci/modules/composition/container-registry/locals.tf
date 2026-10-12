locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # The tenancy namespace, either supplied or looked up. Everything URL-shaped
  # hangs off this - NOT the compartment, which never appears in a pull URL.
  namespace = var.namespace != null ? var.namespace : data.oci_objectstorage_namespace.this[0].namespace

  ocir_endpoint = var.ocir_endpoint != null ? var.ocir_endpoint : "${var.region}.ocir.io"

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

  # IAM statements - the substitute for aws_ecr_repository_policy.
  # Verbs: `manage repos` covers push plus delete (the push half); `read repos`
  # is REPOSITORY_READ, the pull half. Statements are emitted pre-normalised and
  # SORTED because the OCI API rewrites statement strings server-side and an
  # unstable order would produce a perpetual Terraform diff; `compartment id
  # <ocid>` rather than `compartment <name>` is used for the same reason.
  # One statement per subject, compartment-scoped - deliberately NOT one per
  # repository, which is the blast-radius improvement of collapsing ~130
  # per-repository AWS documents into one.
  registry_statements = sort(concat(
    [for subject in var.push_subjects :
      "Allow ${subject} to manage repos in compartment id ${var.compartment_id}"
    ],
    [for subject in var.pull_subjects :
      "Allow ${subject} to read repos in compartment id ${var.compartment_id}"
    ],
  ))
}
