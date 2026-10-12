# bastion-host (OCI)

A single jump instance in a private subnet with no public IP, reachable only
through the OCI Bastion service, so operators can SSH-local-port-forward to
managed data-tier endpoints that no broker can reach directly.

## Resources

| File | Resources |
|---|---|
| `network.tf` | `oci_core_network_security_group` x1 |
| `main.tf` | `oci_core_instance`, `oci_bastion_bastion`, `oci_logging_log_group`, `oci_logging_log`, `oci_objectstorage_bucket` (optional), `oci_objectstorage_object_lifecycle_policy` (optional) |
| `templates/` | `userdata.sh`, `connection_guide.tftpl` |

## Operational notes

OCI Bastion requires an SSH keypair on every session, opens one inbound rule
from the Bastion's private endpoint IP, and does not record session content
(Audit covers control-plane calls only). The outcome that survives is centrally
brokered, time-boxed, IAM-gated access to a private-subnet host with no
permanently open internet SSH port.

## Deliberately not implemented

- **No `oci_bastion_session`.** Sessions are short-lived, per-operator,
  per-incident objects. The connection guide tells operators to create a
  `PORT_FORWARDING` session themselves.
- **No session recorder.** `enable_session_recording` creates a destination
  only.
- **No identity resources** (dynamic group / IAM policy).
- **No security rules.** The NSG is created empty — but it is the one NSG that
  cannot *stay* empty, because the Bastion service's data-plane VNIC needs that
  single ingress rule.

## Validation

`terraform validate` and `terraform fmt` pass; both templates are additionally
rendered with representative values to catch template syntax `validate` does not
evaluate.