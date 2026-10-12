# shared-policy (OCI)

**This module deliberately creates no resources.** There is no `main.tf`. It is
a text factory: it renders shared permission grants into `oci_identity_policy`
statement strings, which callers concatenate into the single shared
`oke-workload-identity` policy object for their environment.

That is not a simplification of the AWS module — it is the only shape OCI
allows. `aws_iam_policy` is a detached, attachable object: created with no
subject, bound to many roles, revoked by detaching, and referenced across root
boundaries by a stable name. `oci_identity_policy` **is** the grant; its
statements name the subject, the verb, the resource type and the location at
creation time. There is no attach step, no policy OCID worth passing around, and
no singular `data "oci_identity_policy"` source.

## What that costs

| AWS | OCI |
|---|---|
| One policy object, N attachments | N statements, one per (subject x cluster) |
| Revoke = delete one attachment | Revoke = edit every consuming policy object, N plans |
| "Who has this policy?" = attachment listing | Text search, or tag the consuming policy with `grant_names` |
| `path` for grouping | Compartment scope + freeform tags. No name hierarchy |

## Naming

`shared-policy` promises a cloud object it does not create. The directory is
kept as `shared-policy` for traceability against the AWS inventory; the module
emits statements, so treat it as a statement/text factory.

## Validation

```
terraform fmt -recursive && terraform init -backend=false && terraform validate
```

A zero-resource module cannot be validated by plan output. The real gate is on
the **consumer**: its planned `oci_identity_policy.statements` must contain one
additional statement per (grant x subject x cluster), each carrying all four
`request.principal.*` conditions.