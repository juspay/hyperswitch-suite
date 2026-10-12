# shared-policy - the OCI port of AWS `shared-policy`. AWS creates detached,
# attachable `aws_iam_policy` objects; OCI has no such object - `oci_identity_policy`
# IS the grant. So this module creates NOTHING (no main.tf): it renders shared
# grants into statement strings for the shared oke-workload-identity object.
# REJECTED ALTERNATIVE (recorded because tempting): one real policy object per
# grant with a broad `request.principal.type='workload'` subject but NO
# service_account condition - that grants the permission to EVERY POD IN THE
# CLUSTER, exactly the blast radius this port exists to eliminate (rejected).

variable "compartment_id" {
  description = <<-EOT
    Default location term for rendered statements - the compartment a grant
    applies to when the grant itself does not name one. Normally the
    environment compartment, i.e. the same compartment the shared
    `oke-workload-identity` policy object is attached to.

    A policy governs only its own compartment and that compartment's
    descendants, so a grant naming a compartment OUTSIDE the attachment point's
    subtree renders a statement that is accepted by the API and grants nothing.
    That failure is silent; this module cannot detect it because it does not
    know where the consuming policy object is attached.
  EOT
  type        = string

  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.", var.compartment_id))
    error_message = "compartment_id must be a compartment or tenancy OCID (ocid1.compartment.* / ocid1.tenancy.*)."
  }
}

variable "subjects" {
  description = <<-EOT
    The (namespace, service_account) pairs the shared grants are rendered FOR.

    THE NEW REQUIRED INPUT, and the whole reason this module changed shape. On
    AWS the subject is supplied later, by an attachment; on OCI it must be known
    at render time (check sheet section 4.1). One shared grant used by three
    apps is therefore three statements, not one attachment - which is the real
    cost of the substitution and the reason the 50-statements-per-object and
    500-per-compartment-hierarchy limits bite here.

    Required and non-empty on purpose: an empty list would render nothing, but
    a caller who expected statements would get silence rather than an error.
  EOT
  type = list(object({
    namespace       = string
    service_account = string
  }))

  validation {
    condition     = length(var.subjects) > 0
    error_message = "subjects must contain at least one (namespace, service_account) pair. A shared grant with no subject has no OCI expression - see the rejected alternative in this file's header."
  }

  validation {
    condition     = alltrue([for s in var.subjects : length(trimspace(s.namespace)) > 0 && length(trimspace(s.service_account)) > 0])
    error_message = "subjects[*].namespace and .service_account must be non-empty. A blank value renders a condition that matches nothing, or is dropped - which widens the grant."
  }
}

variable "cluster_ids" {
  description = <<-EOT
    OCIDs of every OKE cluster whose workloads these shared grants apply to. A
    LIST from day one, for the same reason `oke-workload-identity` takes one:
    N clusters is N statements inside one policy object, never N objects.

    `request.principal.cluster_id` is one of the four conditions that make up
    the entire security boundary. An empty list would render statements with no
    cluster condition, granting every cluster in the tenancy - rejected below.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.cluster_ids) > 0
    error_message = "cluster_ids must contain at least one OKE cluster OCID."
  }

  validation {
    condition     = alltrue([for c in var.cluster_ids : can(regex("^ocid1\\.cluster\\.", c))])
    error_message = "every entry in cluster_ids must be an OKE cluster OCID (ocid1.cluster.*)."
  }
}

variable "grants" {
  description = <<-EOT
    The shared grants, keyed by logical name. Replaces the AWS module's
    `policies = map(object({name, description, path, policy, tags}))`.

    Four fields of that AWS object have no counterpart and are gone:
      * `policy`      - a JSON document; an OCI grant is verb + resource-type +
                        location + optional condition, not a document;
      * `name`        - the statement is anonymous; only this map key names it,
                        and the key is Terraform-side only;
      * `path`        - PARTIAL, check sheet section 4.3. OCI's organisational
                        axis is the compartment (which is also the policy's
                        scope, so it is load-bearing rather than decorative)
                        plus freeform tags. There is no name hierarchy;
      * `tags`        - nothing is created, so there is nothing to tag. The
                        audit question "who has hs-ses-assume-policy?" was a
                        single attachment listing on AWS and becomes a text
                        search here; tag the CONSUMING policy object with the
                        logical grant names it embeds (check sheet 4.1).

      verb           - inspect | read | use | manage. Cumulative lattice.
                       Note `use objects` CANNOT create an object; anything that
                       writes a new object needs `manage objects`.
      resource_type  - e.g. objects, secret-bundles, metrics, log-content.
                       Prefer the individual type over a `-family` aggregate:
                       families are coarser than AWS's curated policies
                       (`manage object-family` includes bucket deletion,
                       `AmazonS3ReadOnlyAccess` does not).
      compartment_id - location. Defaults to var.compartment_id.
      condition      - extra `where all {}` term, e.g.
                       "target.bucket.name='hyps-dev-uploads'". Rendered
                       verbatim AFTER the four principal conditions.
      description    - Terraform-side documentation only. Never rendered: an
                       OCI policy statement has no comment syntax.
  EOT
  type = map(object({
    verb           = string
    resource_type  = string
    compartment_id = optional(string)
    condition      = optional(string)
    description    = optional(string)
  }))
  default = {}

  validation {
    condition     = alltrue([for g in values(var.grants) : contains(["inspect", "read", "use", "manage"], lower(trimspace(g.verb)))])
    error_message = "grants[*].verb must be one of inspect, read, use, manage."
  }

  validation {
    condition     = alltrue([for g in values(var.grants) : length(trimspace(g.resource_type)) > 0])
    error_message = "grants[*].resource_type must be non-empty."
  }

  validation {
    condition     = alltrue([for g in values(var.grants) : lower(trimspace(g.resource_type)) != "all-resources"])
    error_message = "grants[*].resource_type must not be `all-resources`. A shared grant of all-resources hands every consuming workload full control of the compartment - the exact opposite of what a shared, reviewable permission is for."
  }

  validation {
    condition     = alltrue([for g in values(var.grants) : g.compartment_id == null || can(regex("^ocid1\\.(compartment|tenancy)\\.", g.compartment_id))])
    error_message = "grants[*].compartment_id, when set, must be a compartment or tenancy OCID. `in compartment <name>` is lowercased server-side by the OCI API and produces a perpetual Terraform diff."
  }
}
