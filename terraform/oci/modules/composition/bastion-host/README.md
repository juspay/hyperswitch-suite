# bastion-host (OCI)

A single jump instance in a private subnet with no public IP, reachable only
through the OCI Bastion service, existing so operators can SSH-local-port-
forward to the managed data-tier endpoints that no broker can reach directly.

**Renamed** from AWS's `jump-host`, following the precedent GCP already set
(`terraform/gcp/modules/composition/bastion-host/`). The module now wraps a
specific, named cloud service - OCI **Bastion** - so naming it after the AWS
module would bury that in every reader's first impression. Check sheet §5
recommends exactly this rename.

Check sheet: `docs/multi-cloud-parity/oci/modules/jump-host.md`
(hyperswitch-infra - the sheet keeps the AWS filename; the module does not).

## Provider verification

Every argument was read out of `oracle/oci` 9.0.0's own JSON schema
(`terraform providers schema -json`). DIRECT-RESOURCE throughout.

## Resource inventory

| File | Resources |
|---|---|
| `network.tf` | `oci_core_network_security_group` x1 |
| `main.tf` | `oci_core_instance`, `oci_bastion_bastion`, `oci_logging_log_group`, `oci_logging_log`, `oci_objectstorage_bucket` (optional), `oci_objectstorage_object_lifecycle_policy` (optional) |
| `templates/` | `userdata.sh`, `connection_guide.tftpl` |

## The honesty check: OCI Bastion is not SSM Session Manager

| | SSM Session Manager (AWS) | OCI Bastion |
|---|---|---|
| SSH keypair | none, ever | **required on every session** (`key_details.public_key_content`) |
| Inbound rules on the target | **zero**, under any configuration | **one, always** - from the bastion's private endpoint IP |
| Session content recording | optional full transcript to CloudWatch or S3 | **none exists**; Audit records control-plane calls only |
| Idle timeout | `idleSessionTimeout` preference | none - only a session *lifetime* cap |
| Run-as user | `runAsDefaultUser` | `target_resource_operating_system_user_name` (Managed SSH only) |
| Transport | brokered WebSocket data channel | brokered SSH - a different trust model, not strictly weaker |
| Versioned command execution | `aws_ssm_document` | no Terraform resource; Run Command is CLI/Console-only |

Rows 1, 2 and 3 are real losses. Row 6 is a difference, not a loss.

The outcome that *does* survive: centrally brokered, time-boxed, IAM-gated
access to a private-subnet host with no permanently open SSH port to the
internet.

## What is weaker than AWS, and where the comment lives

| Feature | Verdict | Where it is commented |
|---|---|---|
| Session Manager access | SUBSTITUTE | `main.tf` `oci_bastion_bastion` header |
| Session content logging (CloudWatch) | **NONE** | `variables.tf` `enable_session_recording` |
| Session content logging (S3 + Glacier) | **NONE** | same |
| Session preferences (idle timeout, shell profile, KMS) | PARTIAL | `variables.tf` `bastion_max_session_ttl_seconds` |
| Migration-mode escape hatch | PARTIAL | `variables.tf` `enable_migration_mode`, `locals.tf` |
| Zero-ingress security group | SUBSTITUTE, **not achievable** | `network.tf`, `outputs.tf` `bastion_private_endpoint_ip` |
| IAM role / instance profile | SUBSTITUTE | `outputs.tf` header |

## Not yet implemented, deliberately

- **No `oci_bastion_session`.** Sessions are short-lived, per-operator,
  per-incident objects. Terraform-managing one would put an operator's SSH
  public key in state and tie a session's lifetime to an apply. The connection
  guide tells operators to create a `PORT_FORWARDING` session themselves.
- **No session recorder.** `enable_session_recording` creates a *destination*
  only. Adopting a self-managed recorder is an oracle-gate item (check sheet
  §8 item 2, not consulted).
- **No identity resources.** Owned by `oci/identity-model.md`.
- **No security rules.** The NSG is created empty - but see above: this is the
  one NSG in the port that cannot *stay* empty.

## Validation reached

Rung 1 (`terraform validate`) and rung 2 (`terraform fmt`). Both templates were
additionally rendered with representative values to catch template syntax that
`validate` does not evaluate. Rungs 3-5 are the orchestrator's; rung 6 is a
human decision.
