# Node Pool Security

Creates one empty worker NSG and one empty pod NSG per named security profile.
Depends only on a compartment and VCN, so it can run before OKE without a cycle.
Creates no rules, attachments, node pools, or IAM resources. Consumers attach
the returned groups; the separate security-rule owner supplies their rules.

Requires Terraform >= 1.5.0 and `oracle/oci ~> 9.0`, supplied by the caller.
The native mock tests require Terraform >= 1.9.

```hcl
module "node_pool_security" {
  source = "../node-pool-security"

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  environment    = "prd"
  project_name   = "hyperswitch"
  profiles       = toset(["card-vault"])
}
```

`compartment_id`, `vcn_id`, `environment`, and `profiles` are required.
`project_name` defaults to `hyperswitch`; `freeform_tags` defaults to `{}`.
Caller tags override `environment`, `project`, `component`, and `managed_by`.
Profile names must be non-null and non-blank. An empty set creates nothing.
Names preserve identifiers: `<project>-<environment>-oke-<profile>-workers-nsg`
and `<project>-<environment>-oke-<profile>-pods-nsg`.

The `profiles` output maps each name to `{ worker_nsg_id, pod_nsg_id }`.
Empty NSGs alone do not grant access or enforce isolation. Production-only
selection is caller policy, not a module default. Remote consumption requires
publishing this source and selecting a real immutable ref.

Run `terraform init -backend=false`, `terraform validate`, and `terraform test`.
Tests use mock providers, not OCI credentials or infrastructure.
