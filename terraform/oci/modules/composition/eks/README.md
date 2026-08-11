# eks (OCI) → OKE

OCI equivalent of `terraform/aws/modules/composition/eks`. Uses the official, **verified** Terraform Registry module
[`oracle-terraform-modules/oke/oci`](https://registry.terraform.io/modules/oracle-terraform-modules/oke/oci/latest)
(v5.5.0) rather than hand-rolled `oci_containerengine_*` resources — this is the direct analog of the AWS module's
use of `terraform-aws-modules/eks`.

## Networking

`create_vcn = false` — the VCN and subnets come from the `vpc-network` composition module and are passed in as
existing-resource references (`subnets = { <role> = { id = ..., create = "never" } }`), the same relationship the
AWS `eks` module has with `vpc-network` (it takes `vpc_id`/`subnet_ids` as inputs, it doesn't create them).

## Required: `oci.home` provider alias

The `oke` module needs a second `oci` provider configuration pointed at your tenancy's **home region**
(`configuration_aliases = [oci.home]`) — some IAM/tag-namespace resources it creates must live in the home
region regardless of which region the cluster itself is deployed to. The calling layer (e.g. `terraform/oci/live/<env>`)
must declare and pass it:

```hcl
provider "oci" {
  region = var.region # e.g. us-ashburn-1 - the cluster's region
}

provider "oci" {
  alias  = "home"
  region = var.home_region # e.g. us-ashburn-1 - your tenancy's home region
}

module "eks" {
  source = "../../modules/composition/eks"
  providers = {
    oci      = oci
    oci.home = oci.home
  }
  # ...
}
```

## Mapping notes

| AWS | OCI |
|---|---|
| EKS managed node groups | OKE worker pools (`worker_pools`, node-pool mode) |
| VPC CNI | Native Pod Networking (`cni_type = "npn"`) |
| IRSA (IAM Roles for Service Accounts) | OKE Workload Identity, via `oidc_discovery_enabled = true` + OCI IAM policies scoped to the cluster's OIDC issuer |
| `cluster_endpoint_public_access` | `control_plane_is_public` |
| EBS CSI driver IRSA role | Not needed — the OCI Block Volume CSI driver is bundled with OKE and uses instance principal auth by default |

`worker_pools` is passed straight through to the oke module (its type is deliberately `any` — same pattern as the
AWS module's `var.node_groups`). See the
[oke module's worker variables](https://github.com/oracle-terraform-modules/terraform-oci-oke/blob/main/variables-workers.tf)
for every supported field.
