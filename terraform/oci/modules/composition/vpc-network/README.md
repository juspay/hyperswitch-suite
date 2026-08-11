# vpc-network (OCI)

OCI equivalent of `terraform/aws/modules/composition/vpc-network`.

Maps AWS VPC concepts to OCI:

| AWS | OCI |
|---|---|
| VPC | VCN (`oci_core_vcn`) |
| Internet Gateway | Internet Gateway (`oci_core_internet_gateway`) |
| NAT Gateway | NAT Gateway (`oci_core_nat_gateway`) |
| S3 Gateway VPC Endpoint | Service Gateway (`oci_core_service_gateway`) — private route to Object Storage and other OCI services |
| Subnet (per-AZ) | Subnet (regional) |
| Route Table | Route Table |
| Security Group (subnet-adjacent) | Security List (permissive baseline) + Network Security Groups (actual enforcement, created by consuming modules) |

## Why one subnet per tier, not per-AZ

The AWS module creates one subnet per (tier × availability zone) because AWS subnets are AZ-scoped. OCI subnets are **regional** — they span all availability/fault domains in the region — so a single subnet per tier already gives the same multi-AZ reach that AWS gets by fanning out subnets. Compute instances, OKE node pools, and DB systems each pick their own availability/fault domain placement independently of subnet.

## No `base` module

Per the port's conventions (see `../README.md`), there is no `oci/modules/base/vpc` or `oci/modules/base/subnet` — this module talks to the `oci` provider directly, since no verified Terraform Registry module models this many custom subnet tiers with independent routing.

## Usage

```hcl
module "vpc_network" {
  source = "../../modules/composition/vpc-network"

  compartment_id = var.compartment_id
  environment    = var.environment
  project_name   = var.project_name

  vcn_name        = "${var.environment}-${var.project_name}-vcn"
  vcn_cidr_blocks = ["10.0.0.0/16"]
  vcn_dns_label   = "hsvcn"

  subnet_tiers = {
    external-incoming = { cidr_block = "10.0.0.0/24",  dns_label = "extin",  is_public = true,  route_via = "igw" }
    management         = { cidr_block = "10.0.1.0/24",  dns_label = "mgmt",   is_public = true,  route_via = "igw" }
    eks-workers         = { cidr_block = "10.0.16.0/21", dns_label = "workers", route_via = "nat" }
    eks-control-plane   = { cidr_block = "10.0.24.0/28", dns_label = "ekscp",  route_via = "nat" }
    database            = { cidr_block = "10.0.25.0/24", dns_label = "db",     route_via = "none" }
    locker-database      = { cidr_block = "10.0.26.0/26", dns_label = "lockdb", route_via = "none" }
    locker-server         = { cidr_block = "10.0.27.0/26", dns_label = "lockern", route_via = "none" }
    elasticache         = { cidr_block = "10.0.28.0/24", dns_label = "cache",  route_via = "none" }
    data-stack           = { cidr_block = "10.0.29.0/24", dns_label = "data",   route_via = "none" }
    incoming-envoy       = { cidr_block = "10.0.30.0/24", dns_label = "envoy",  route_via = "nat" }
    outgoing-proxy       = { cidr_block = "10.0.31.0/24", dns_label = "outprx", route_via = "nat" }
    utils               = { cidr_block = "10.0.32.0/24", dns_label = "utils",  route_via = "nat" }
  }
}
```
