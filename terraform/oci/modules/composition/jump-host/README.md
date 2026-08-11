# jump-host (OCI)

OCI equivalent of `terraform/aws/modules/composition/jump-host`. Uses `oracle-terraform-modules/compute-instance/oci`
(verified) for the instance, matching the AWS module's use of `terraform-aws-modules/ec2-instance/aws`.

## Consider OCI Bastion instead

The AWS module leans on **SSM Session Manager** so no SSH port is ever opened and every session is logged
centrally, without a persistent bastion host being the actual attack surface (the EC2 instance mainly exists to
host the SSM agent). OCI's direct analog of that pattern is the **OCI Bastion service**
(`oci_bastion_bastion` + `oci_bastion_session`) — a fully managed, ephemeral, session-based service with no
persistent compute instance at all, and built-in session logging.

This module keeps a persistent compute instance (like the AWS module's shape) for parity and because some
operational workflows expect a stable jump host. If you don't need that, replace this module with OCI Bastion
service resources instead — it's the more "native" choice and removes an always-on instance from the estate.

## Session logging

`create_session_log_bucket` provisions an Object Storage bucket (equivalent of AWS's `aws_s3_bucket.ssm_session_logs`)
for teams that want to forward shell session recordings there from the persistent jump host. If you switch to OCI
Bastion service per above, session logging is built into that service and this bucket becomes unnecessary.
