# kafka (OCI)

Self-managed Apache Kafka in KRaft mode on OCI Compute. The OCI port of
`terraform/aws/modules/composition/kafka`.

Check sheet: `docs/multi-cloud-parity/oci/modules/kafka.md` (hyperswitch-infra).
Cross-cutting VM-tier analysis: `docs/multi-cloud-parity/oci/vm-tier-and-images.md`.

## What this is, and what it is not

The AWS original is **not** Amazon MSK. It is raw EC2 running Kafka, so this is
a compute-to-compute port and `SELF-MANAGED` is **parity, not a regression**
(framework.md §2).

OCI does have a managed alternative AWS's architecture never offered -
**OCI Streaming with Apache Kafka** (`oci_managed_kafka_kafka_cluster`). It is
deliberately not used here, matching AWS and GCP precedent. That is a recorded
default, not a decision: check sheet §8 item 1, **oracle gate NOT CONSULTED**.

## Provider verification

Every argument used was read from `oracle/oci` **9.0.0**'s own JSON schema
(`terraform providers schema -json`) in-session, not from memory.

## The three divergences that matter

1. **Static addressing is IP-centric, not NIC-centric** (`network.tf`).
   AWS's `aws_network_interface` is reattachable to a different instance; a VNIC
   is not. The stable object here is `oci_core_private_ip` with
   `lifetime = "RESERVED"`, re-pointed to the replacement's VNIC in place. The
   address is a **secondary** IP on the primary VNIC, so the guest must add it
   to the interface at boot - a step AWS's ENI model never needed.
2. **No instance profile** (`identity.tf`). Instance principals bind through a
   dynamic group's matching rule, and that rule **cannot match a freeform tag**,
   only compartment/instance/defined-tag. The default rule is therefore
   compartment-wide - wider than the AWS role it replaces. Open.
3. **One availability domain** (`compute.tf`). `ap-mumbai-1` has a single AD.
   Quorum placement is across the three **fault domains**, which survives a rack
   failure but not an AD event.

## Deliberate functional change from AWS

`controller_count` defaults to **3**, where the AWS module hardcodes exactly one
controller. Three controllers is a real KRaft quorum; one is a metadata SPOF.
The AWS catalog unit calls its footprint "cost-optimized for passive/DR", so the
single controller may be deliberate. Check sheet §8 item 4 / open question 9.4,
**oracle gate NOT CONSULTED**. Set `controller_count = 1` to reproduce AWS.

## Known blockers

- **No image pipeline.** `broker_image_id` / `controller_image_id` have no
  built images behind them. Do not apply the consuming unit with a placeholder -
  that is precisely the state the GCP port is still stuck in.
- **No Vault.** `vault_secret` is inert until a Vault + KMS key exist in the
  compartment; until then the generated SSH private key lives only in state.
- **Shape availability in `ap-mumbai-1` unverified** (check sheet 9.1).

## Validation reached

Rung 1 (`terraform validate`) and rung 2 (`terraform fmt`) only. `terragrunt
plan` is the orchestrator's step.
