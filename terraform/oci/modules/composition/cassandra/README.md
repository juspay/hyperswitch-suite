# cassandra (OCI)

OCI equivalent of `terraform/aws/modules/composition/cassandra` (self-managed Cassandra on EC2). Uses the official,
verified [`oracle-terraform-modules/compute-instance/oci`](https://registry.terraform.io/modules/oracle-terraform-modules/compute-instance/oci/latest)
registry module (v2.4.1) for the compute nodes — the direct analog of the AWS module's `aws_instance` resources —
plus plain `oci` provider resources for networking/IAM (no verified module covers NSGs or dynamic groups).

## Mapping notes

| AWS | OCI |
|---|---|
| `aws_security_group` + `aws_security_group_rule` | `oci_core_network_security_group` + `oci_core_network_security_group_security_rule` |
| EC2 key pair + SSM private-key parameter | `ssh_authorized_keys` on the compute instance (no separate key-pair resource in OCI) |
| IAM role + instance profile | Dynamic Group + Policy (Instance Principals — OCI compute instances authenticate as dynamic-group members directly, there's no "instance profile" attachment step) |
| Elastic Network Interface (stable IP) per node | Handled by the compute-instance module's primary VNIC per instance |
| Attached EBS data volume | `block_storage_sizes_in_gbs` on the compute-instance module (creates + attaches a block volume per instance) |
| CloudWatch Log Group | `oci_logging_log_group` |

## Known simplification: seed discovery

The AWS module stands up a Lambda function + private API Gateway that queries EC2 instance tags to discover
Cassandra seed nodes at boot. This module does **not** rebuild that as OCI Functions + API Gateway — it's a
sizeable amount of infrastructure for what's fundamentally a service-discovery problem. Instead, use one of:

- OCI **Service Connector Hub** + Search to expose instance metadata to booting nodes, or
- static seed IPs from `module.cassandra_nodes.private_ip` (stable, since each instance's VNIC persists across
  the instance's lifecycle) wired into cloud-init via `user_data`, or
- an OCI Function replicating the AWS Lambda's tag-query logic, added on top of this module if the static-IP
  approach isn't acceptable operationally.
