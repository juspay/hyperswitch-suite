# cassandra (OCI)

Self-managed Apache Cassandra on OCI Compute. The OCI port of
`terraform/aws/modules/composition/cassandra`.

Check sheet: `docs/multi-cloud-parity/oci/modules/cassandra.md` (hyperswitch-infra).

## What this is

The AWS original runs Cassandra on raw EC2, so `SELF-MANAGED` is **parity, not a
regression**. Unlike `../kafka` there is no managed alternative to weigh: no
managed Cassandra-compatible OCI service exists.

## Provider verification

Every argument was read from `oracle/oci` **9.0.0**'s own JSON schema in-session.

## The four divergences that matter

1. **Static addressing is IP-centric** (`network.tf`). No reattachable ENI on
   OCI; the stable object is `oci_core_private_ip` with `lifetime = "RESERVED"`,
   re-pointed in place. It is a **secondary** IP on the primary VNIC, so the
   guest must add it to the interface at boot.
2. **iSCSI by default** (`storage.tf`). Chosen for gp3-equivalent IOPS
   consistency. New failure mode with no AWS precedent: a node can boot, mount
   nothing, and run on an empty filesystem silently.
   `is_agent_auto_iscsi_login_enabled = true` (verified present in 9.0.0)
   removes most of the guest-side scripting the check sheet assumed; the
   fail-fast mount check in the image is still outstanding.
3. **Seed discovery is OFF by default** (`seed-discovery.tf`), where AWS's
   `create_seed_discovery` is on. Static reserved-IP injection replaces it -
   **but only when `reserved_ip_addresses` is pinned**, because a reserved IP
   created on a VNIC cannot feed the user_data of the instance that VNIC belongs
   to without a cycle. Pin the addresses.
4. **No instance profile** (`identity.tf`). Dynamic-group matching rules cannot
   match a freeform tag, so the default rule is compartment-wide - wider than
   the AWS role it replaces.

## Resolved while building

- `oci_apigateway_deployment` **does** accept an `oci_functions_function`
  backend (`type = "ORACLE_FUNCTIONS_BACKEND"`, `function_id`). Check sheet open
  question 9.1: answered yes, from the provider schema.

## Known blockers

- No image pipeline behind `image_id`.
- No OCIR container image behind `seed_discovery_image` (check sheet 9.3).
- No Vault; the generated SSH key lives only in state until one exists.
- In-guest device path for an iSCSI volume unresolved (check sheet 9.2).

## Validation reached

Rungs 1 and 2 only.
