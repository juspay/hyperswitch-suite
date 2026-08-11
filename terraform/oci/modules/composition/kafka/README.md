# kafka (OCI)

OCI equivalent of `terraform/aws/modules/composition/kafka` (self-managed KRaft-mode Kafka brokers + controller on
EC2). Same pattern as `../cassandra`/`../clickhouse`: `oracle-terraform-modules/compute-instance/oci` (verified)
for compute, plain `oci` provider resources for NSGs/IAM. See `../cassandra/README.md` for the general AWS→OCI
resource mapping (security groups→NSGs, instance profile→dynamic group, EBS→block volume).

`depends_on = [module.controller_node]` on the broker module reproduces the AWS module's
`time_sleep.wait_for_controller` ordering constraint (controller must exist before brokers start) — actual
readiness (KRaft quorum, not just "instance exists") still needs to be handled in cloud-init/user_data, same as
the AWS module.
