# clickhouse (OCI)

Self-managed ClickHouse (Keeper + server tiers) on OCI Compute, behind an
internal OCI Load Balancer. The OCI port of
`terraform/aws/modules/composition/clickhouse`.

Check sheet: `docs/multi-cloud-parity/oci/modules/clickhouse.md`
(hyperswitch-infra).

## What this is

The AWS original runs both tiers on raw EC2, so `SELF-MANAGED` is **parity**.
ClickHouse Cloud is third-party SaaS, not an OCI-native service, so there is no
managed alternative on any of the three clouds.

## Provider verification

Every argument was read from `oracle/oci` **9.0.0**'s own JSON schema in-session.

## The four divergences that matter

1. **iSCSI by default across four volume classes** (`storage.tf`). The gap is the
   attachment mechanism, not capacity - OCI's IOPS ceiling is well above gp3's.
   New failure mode: a node boots, mounts nothing, serves from an empty
   filesystem. `is_agent_auto_iscsi_login_enabled = true` (verified present in
   9.0.0) removes most of the guest-side scripting; the fail-fast mount check in
   the image is still outstanding, and rung-6 testing must **reboot** a node.
2. **Static addressing is IP-centric** (`network.tf`), and here the blast radius
   is widest of the three VM modules: both tiers' user data bakes peer IPs in via
   `{{keeper_ips}}` / `{{server_ips}}`, so a missed re-point breaks every sibling
   node's assumption, not just the replaced one. **Pin
   `keeper_reserved_ip_addresses` and `server_reserved_ip_addresses`** - see the
   cycle note in `locals.tf`.
3. **The load balancer is a removed blocker, not just parity**
   (`load-balancer.tf`). AWS's `alb_subnet_ids` requires two AZs; an OCI LB does
   not. In a one-AD region the AWS rule ported literally could never be
   satisfied. Backends register on the **primary** IP, not the reserved secondary
   one, because the guest brings the secondary up itself.
4. **No instance profile** (`identity.tf`). Compartment-wide dynamic-group rule,
   wider than the AWS role it replaces.

## Kept, not simplified

Four data-volume classes (`keeper_data`, `keeper_data2`, `server_data`,
`server_data2`), all `prevent_destroy = true`. GCP's port collapsed to one disk;
`prod/eu-west-1` carries an EBS volume-import block, which is evidence the
attach-to-a-fresh-instance operation has already happened in production.
Diverging would be a data migration. Check sheet open question 9.1.

## Known blockers

- No image pipeline behind `keeper_image_id` / `server_image_id`.
- In-guest device path for an iSCSI volume unresolved (check sheet 9.2).
- Whether the LB needs its own subnet tier is unresolved (check sheet 9.3);
  `data-stack` is the working assumption.
- `load_balancer_ip` is an IP, not a DNS name. DNS is `cloud-dns`'s problem
  (check sheet 9.4).

## Validation reached

Rungs 1 and 2 only.
