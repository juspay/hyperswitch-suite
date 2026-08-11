# security-rules (OCI)

OCI equivalent of `terraform/aws/modules/composition/security-rules`. Same design and rule-placement pattern as
the AWS module (see the AWS module's header comment): NSGs are created inside their owning composition module;
cross-module connectivity rules (e.g. jump host → locker SSH) are defined at the live layer and passed into this
module grouped by NSG; same-module-internal rules (e.g. NLB → instance) stay in the owning composition module.

`oci_core_network_security_group_security_rule` replaces `aws_security_group_rule`; the `protocol` field uses OCI's
numeric protocol convention (`"6"` = TCP, `"17"` = UDP, `"1"` = ICMP, `"all"` = all protocols) rather than AWS's
string names.
