# Identity and placement.

variable "compartment_id" {
  description = "OCID of the compartment every resource in this module is created in. Replaces the implicit AWS account scope; a flat compartment is the deliberate first-cut simplification (prerequisite P5, oci/identity-model.md)."
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy OCID. Needed only because oci_identity_dynamic_group (identity.tf, this fleet's instance-principal identity) is forced to the tenancy-root compartment by the API itself - every other resource in this module stays compartment-scoped."
  type        = string
}

variable "environment" {
  description = "Environment name (dev, integ, sandbox, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name, used in resource naming and freeform tags"
  type        = string
  default     = "hyperswitch"
}

variable "region" {
  description = "OCI region identifier, e.g. ap-mumbai-1. Informational - the provider carries the region."
  type        = string
}

variable "availability_domain" {
  description = "Availability domain the instance pool places instances into. Null means \"the first AD returned for this compartment\". ap-mumbai-1 is single-AD, so fault-domain spread is the only availability lever - see oci/vm-tier-and-images.md section 3."
  type        = string
  default     = null
}

variable "fault_domains" {
  description = "Fault domains within the availability domain to spread pool instances over. Null lets OCI distribute on a best-effort basis across all three."
  type        = list(string)
  default     = null
}

variable "freeform_tags" {
  description = "Freeform tags merged over the module's own set. The AWS tags_all analogue."
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags (namespace.key = value). Passed straight through because they require a tag namespace this module does not own."
  type        = map(string)
  default     = {}
}

# Network.

variable "vcn_id" {
  description = "OCID of the VCN. Needed only to create this module's NSGs."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the Squid instances' primary VNICs land in. This is vpc-network's `outgoing-proxy` tier - the only tier carrying a NAT route, and therefore the sanctioned internet egress path for the whole platform."
  type        = string
}

variable "nlb_subnet_id" {
  description = "OCID of the subnet the Network Load Balancer's VNIC lands in. Null places it in the same subnet as the instances, which is the usual arrangement for an internal L4 balancer. OCI's NLB takes ONE subnet (singular), not a list - it is regional, so there is no per-AZ fan-out to express."
  type        = string
  default     = null
}

variable "create_nsg" {
  description = <<-EOT
    Whether this module creates its own Network Security Groups.

    NSGs, never security lists - the binding decision in
    oci/network-security-model.md section 5 (Option A). Created EMPTY: the
    security-rules unit, in the last stack phase, writes the rules by reading
    nsg_id / nlb_nsg_id from this module's outputs. Do not add
    oci_core_network_security_group_security_rule to this module.
  EOT
  type        = bool
  default     = true
}

variable "additional_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the instances' primary VNICs. Capped by OCI at 5 NSGs per VNIC, not increasable."
  type        = list(string)
  default     = []
}

variable "additional_nlb_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the Network Load Balancer."
  type        = list(string)
  default     = []
}

# Compute.

variable "image_id" {
  description = <<-EOT
    OCID of the custom image the Squid instances boot from - a Packer-built
    image carrying Squid, its systemd unit, and the 15-minute whitelist-refresh
    timer that makes feature 8's hot reload work.

    THE IMAGE IS A HARD PRECONDITION FOR CORRECTNESS HERE, not just for boot.
    This module ships allowedlist.txt to Object Storage; the cron/systemd timer
    that fetches it and runs `squid -k reconfigure` lives in the IMAGE. Without
    it, the allowlist object is inert and every allowlist change silently does
    nothing. That contract ported cleanly from AWS's AMI userdata to GCP's
    Packer image (squid-whitelist-fetch.service, live-tested 2026-08-20); on
    OCI only the fetch tooling changes - `oci os object get` in place of
    `gsutil cp`.

    Do NOT wire a PLACEHOLDER-* string into a stack for this.
  EOT
  type        = string
}

variable "shape" {
  description = "Compute shape for Squid instances. A flexible shape also needs shape_ocpus and shape_memory_in_gbs."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "shape_ocpus" {
  description = "OCPUs per instance, for flexible shapes only."
  type        = number
  default     = 2
}

variable "shape_memory_in_gbs" {
  description = "Memory per instance in GB, for flexible shapes only."
  type        = number
  default     = 16
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB. Minimum 50 on OCI."
  type        = number
  default     = 50
}

variable "boot_volume_kms_key_id" {
  description = "Customer-managed KMS key for the boot volume. Null uses Oracle-managed encryption, the documented default and the mapping for the AWS launch template's hardcoded ebs.encrypted = true. Default-encrypted behaviour is Tier 2 pending confirmation (check sheet open question)."
  type        = string
  default     = null
}

variable "disable_legacy_imds_endpoints" {
  description = "Disables the IMDSv1 (/opc/v1) metadata endpoints. The AWS base/launch-template HARDCODES metadata_options.http_tokens = \"required\" for this fleet rather than exposing it, so this defaults true and should stay true."
  type        = bool
  default     = true
}

variable "is_preemptible" {
  description = <<-EOT
    Run the pool on preemptible capacity.

    PARTIAL - check sheet feature 5. AWS's mixed_instances_policy blends
    on-demand and spot inside ONE scaling group with an allocation strategy. An
    OCI pool is homogeneous: one instance configuration, one capacity type. So
    this is an all-or-nothing switch on the whole fleet, and a cost-optimized
    blend needs a SECOND instantiation of this module with a statically chosen
    size - there is no dynamic, capacity-aware allocation strategy to replace
    spot_allocation_strategy.

    Consider carefully before enabling on the EGRESS path: a reclaimed
    preemptible instance takes outbound payment-processor calls with it.
  EOT
  type        = bool
  default     = false
}

variable "min_replicas" {
  description = "Pool floor and the size Terraform seeds the pool at."
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Pool ceiling for the autoscaling policy."
  type        = number
  default     = 6
}

variable "metadata" {
  description = "Additional instance metadata merged over the module's own. `user_data` and `ssh_authorized_keys` are set by this module and will be overwritten if supplied here."
  type        = map(string)
  default     = {}
}

variable "custom_user_data" {
  description = "cloud-init user-data run at boot: fetches squid.conf and allowedlist.txt from the config bucket and (re)starts Squid. Delivered base64-encoded via metadata.user_data, read from http://169.254.169.254/opc/v2/instance/metadata/ - structurally identical to an AWS launch template's user_data."
  type        = string
  default     = null
}

# Autoscaling.

variable "enable_autoscaling" {
  description = "Whether to attach an oci_autoscaling_auto_scaling_configuration to the pool."
  type        = bool
  default     = true
}

variable "scaling_policies" {
  description = <<-EOT
    Autoscaling configuration.

    SUBSTITUTE - check sheet feature 4, identical finding to envoy-proxy's
    feature 8 and deliberately implemented identically here so the two modules
    do not drift. AWS uses TargetTrackingScaling: state one target utilization
    and a managed controller converges on it. OCI's autoscaling configuration
    supports only `threshold` (alarm-crossing, fixed instance-count delta) and
    `scheduled` (Quartz cron). There is no target-tracking controller.

    target_value is kept as the input shape and locals.tf translates each
    enabled signal into a PAIR of threshold rules with a deadband
    (scale_in_offset) between them, because a threshold policy with no deadband
    oscillates around the target. pending_duration and cool_down_in_seconds
    (minimum 300 s) are the only other damping controls.

    memory_target_tracking requires the Compute Instance Monitoring plugin on
    the image - the CloudWatch agent's counterpart, and the same precondition
    the AWS module's memory policy already carries. Without a working Oracle
    Cloud Agent the metric never arrives and the policy is a silent no-op.

    NOT ORACLE-GATED (framework §4.1, check sheet §8 item 2).
  EOT
  type = object({
    cool_down_in_seconds = optional(number, 300)

    cpu_target_tracking = optional(object({
      enabled          = optional(bool, true)
      target_value     = optional(number, 70)
      scale_in_offset  = optional(number, 30)
      scale_out_step   = optional(number, 1)
      scale_in_step    = optional(number, 1)
      pending_duration = optional(string, "PT5M")
    }), {})

    memory_target_tracking = optional(object({
      enabled          = optional(bool, false)
      target_value     = optional(number, 70)
      scale_in_offset  = optional(number, 30)
      scale_out_step   = optional(number, 1)
      scale_in_step    = optional(number, 1)
      pending_duration = optional(string, "PT5M")
    }), {})
  })
  default = {}

  validation {
    condition     = var.scaling_policies.cool_down_in_seconds >= 300
    error_message = "cool_down_in_seconds must be >= 300 - OCI's documented minimum."
  }

  validation {
    condition = (
      var.scaling_policies.cpu_target_tracking.target_value > var.scaling_policies.cpu_target_tracking.scale_in_offset
      && var.scaling_policies.memory_target_tracking.target_value > var.scaling_policies.memory_target_tracking.scale_in_offset
    )
    error_message = "scale_in_offset must be smaller than target_value; otherwise the scale-in threshold is negative and the rule can never fire."
  }
}

variable "scheduled_scaling_policies" {
  description = "Cron-driven capacity policies. EXTRA capability relative to AWS. `expression` is a Quartz cron."
  type = list(object({
    name       = string
    expression = string
    timezone   = optional(string, "UTC")
    capacity   = number
  }))
  default = []
}

variable "enable_pre_termination_hook" {
  description = <<-EOT
    Enables the instance pool's lifecycle_management pre_termination hook - a
    grace window before an instance is torn down.

    This is the closest thing OCI has to AWS's `instance_refresh`, and it is
    NOT close (PARTIAL - check sheet feature 6). AWS declares a whole staged
    rollout in one block: min_healthy_percentage, checkpoint_percentages,
    checkpoint_delay, all health-gated and orchestrated by the service. OCI's
    instance pool has no equivalent at all; this hook only softens an
    individual instance's termination. A staged, health-gated rollout on OCI is
    scripted replacement (terminate N, let the pool self-heal from the current
    instance configuration, wait for backend-set health, repeat) living OUTSIDE
    Terraform's plan/apply cycle.

    That matters more here than on envoy-proxy: a botched rollout on the EGRESS
    path can silently break outbound payment-processor calls until a specific
    downstream integration is exercised, where an ingress mistake is visible
    immediately. Where the replacement script lives is itself an oracle-gate
    item (check sheet §8 item 3, not consulted).
  EOT
  type        = bool
  default     = false
}

variable "pre_termination_timeout" {
  description = "Grace period in seconds for the pre-termination hook, when enabled."
  type        = number
  default     = 300
}

# Load balancer (L4).

variable "create_nlb" {
  description = "Whether this module creates the internal Network Load Balancer, its backend set and its listener. False attaches the pool to an existing backend set."
  type        = bool
  default     = true
}

variable "existing_load_balancer_id" {
  description = "OCID of a load balancer to register the pool against when create_nlb = false. The bring-your-own-infra escape hatch. See the note on oci_core_instance_pool.load_balancers in compute.tf before relying on this with an NLB OCID."
  type        = string
  default     = null
}

variable "existing_backend_set_name" {
  description = "Backend set name on existing_load_balancer_id to register the pool into when create_nlb = false."
  type        = string
  default     = null
}

variable "nlb_is_private" {
  description = "Whether the NLB gets a VCN-local private IP instead of a public one. TRUE, and it should stay true: this is the internal egress proxy, and a public forward proxy is an open relay."
  type        = bool
  default     = true
}

variable "nlb_reserved_ip_id" {
  description = "OCID of a Reserved IP to pin the NLB's address across recreation. Every OKE workload's proxy environment variable points at this address, so pinning it turns a fleet-wide reconfiguration into a no-op."
  type        = string
  default     = null
}

variable "nlb_preserve_source_destination" {
  description = "Whether the NLB's BACKEND SET preserves the original client source IP (oci_network_load_balancer_backend_set.is_preserve_source), so Squid's access log shows the real client rather than the balancer's. OCI does the readdressing; the backend does not need any special VNIC configuration for this mode."
  type        = bool
  default     = false
}

# Split out of nlb_preserve_source_destination (they are not the same feature).
# This is OCI's deeper bump-in-the-wire mode and REQUIRES
# skip_source_dest_check = true on the backend VNICs or the OS drops every
# packet as spoofed; this module sets no such attribute, so enabling it breaks
# the proxy at the network layer with no Terraform-side error.
variable "nlb_transparent_mode" {
  description = "Whether the NLB itself runs in IP-transparency / bump-in-the-wire mode (is_preserve_source_destination on the NLB resource, not the backend set). Requires skip_source_dest_check on backend VNICs, which this module does not yet set - do not enable until that lands."
  type        = bool
  default     = false
}

variable "squid_port" {
  description = "Port Squid listens on, and the front-end port of the NLB listener. Both ends are the same because an L4 balancer does not rewrite ports by convention here."
  type        = number
  default     = 3128
}

variable "backend_set_policy" {
  description = "Load-balancing policy for the NLB backend set: FIVE_TUPLE, THREE_TUPLE or TWO_TUPLE."
  type        = string
  default     = "FIVE_TUPLE"

  validation {
    condition     = contains(["FIVE_TUPLE", "THREE_TUPLE", "TWO_TUPLE"], var.backend_set_policy)
    error_message = "backend_set_policy must be FIVE_TUPLE, THREE_TUPLE or TWO_TUPLE - an NLB has no ROUND_ROBIN."
  }
}

variable "health_check" {
  description = "Backend health check on the NLB backend set. Defaults to a plain TCP connect on the Squid port, which is what the AWS target group does for this fleet."
  type = object({
    protocol            = optional(string, "TCP")
    port                = optional(number, null)
    url_path            = optional(string, null)
    return_code         = optional(number, null)
    interval_in_millis  = optional(number, 10000)
    timeout_in_millis   = optional(number, 3000)
    retries             = optional(number, 3)
    response_body_regex = optional(string, null)
  })
  default = {}
}

variable "tcp_idle_timeout" {
  description = "Idle timeout in seconds for the NLB's TCP listener. Squid CONNECT tunnels to slow payment processors can be long-lived; too low a value tears them down mid-transaction."
  type        = number
  default     = 300
}

variable "tls_termination_mode" {
  description = <<-EOT
    How the encrypted proxy path is provided. NONE - check sheet feature 3.

    OCI's Network Load Balancer CANNOT TERMINATE TLS AT ALL. This is not a
    partial-feature gap: oci_network_load_balancer_network_load_balancer's
    listener block exposes protocol, tcp_idle_timeout, l3ip_idle_timeout and
    udp_idle_timeout and has NO ssl_configuration block of any kind, confirmed
    directly from the schema. The classic oci_load_balancer_listener has one;
    the NLB does not. It is a pure L3/L4 passthrough product.

    So AWS's `enable_tls_listener = true` (a base/nlb-listener with protocol
    TLS, tls_certificate_arn, tls_ssl_policy, tls_alpn_policy) has nothing to
    port to, and this enum forces the replacement to be chosen explicitly per
    environment rather than silently defaulting to "encryption disappeared".

      "none"       - plain TCP. The current default and the honest one while
                     the gate is unconsulted.
      "instance"   - TLS terminated on each Squid instance via Squid's own
                     https_port directive. Preserves the NLB's passthrough and
                     source-IP semantics; pushes certificate distribution and
                     renewal onto every proxy node, via the same Object Storage
                     config path used for squid.conf. A cert rotation becomes a
                     fleet-wide config push instead of one listener update.
                     This module ships the cert material as config objects if
                     you supply it in additional_config_files; the https_port
                     directive itself belongs in squid_config_content.
      "classic_lb" - move this fleet onto the classic Load Balancer, which does
                     support ssl_configuration, at the cost of the NLB's pure
                     L3/L4 passthrough and source-IP preservation.

    "classic_lb" IS DELIBERATELY REJECTED BY VALIDATION rather than
    half-implemented. It is a genuine architecture fork for this module - a
    different load-balancer product, different backend-set resource, different
    health-checker shape and a source-IP behaviour change that Squid's access
    log and any downstream IP allowlisting depend on. Check sheet §8 item 1
    routes exactly this choice to the oracle gate, and the gate has NOT been
    consulted. Shipping an ungated fork silently is the failure mode the gate
    exists to prevent; failing the plan with this message is not.
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "instance", "classic_lb"], var.tls_termination_mode)
    error_message = "tls_termination_mode must be \"none\", \"instance\" or \"classic_lb\"."
  }

  validation {
    condition     = var.tls_termination_mode != "classic_lb"
    error_message = "tls_termination_mode = \"classic_lb\" is not implemented. Moving squid-proxy from the Network Load Balancer to the classic Load Balancer is an architecture fork (it trades away L3/L4 passthrough and source-IP preservation) and is an oracle-gate decision under framework §4.1 - see docs/multi-cloud-parity/oci/modules/squid-proxy.md §4 and §8 item 1. The gate has not been consulted. Use \"instance\" for on-node TLS, or \"none\"."
  }
}

# Object storage - config delivery, whitelist, log archival.

variable "create_config_bucket" {
  description = "Whether to create the Object Storage bucket carrying squid.conf and allowedlist.txt."
  type        = bool
  default     = true
}

variable "config_bucket_name" {
  description = "Name of the config bucket. Null derives it from the name prefix. Bucket names are unique per namespace per region, not globally, unlike S3."
  type        = string
  default     = null
}

variable "squid_config_content" {
  description = "Rendered contents of squid.conf, uploaded to the config bucket. Uses oci_objectstorage_object.content so Terraform's own diff redeploys on change - the equivalent of the AWS module's content + etag = filemd5() pattern, and necessary because there is no etag output attribute to key a trigger off."
  type        = string
  default     = null
}

variable "squid_allowlist_content" {
  description = <<-EOT
    Contents of allowedlist.txt - the domain allowlist every outbound call from
    the platform is checked against.

    FULL parity (check sheet feature 8), and the one feature in this module
    whose whole point is that changing it does NOT replace an instance: the
    image's 15-minute timer refetches this object and runs
    `squid -k reconfigure`. Changing this variable is a config push, not a
    rollout. That contract is only honoured if the image actually carries the
    timer - see var.image_id.
  EOT
  type        = string
  default     = null
}

variable "allowlist_object_name" {
  description = "Object name the allowlist is written to. Must match what the image's refresh script fetches; changing one without the other silently breaks the hot reload."
  type        = string
  default     = "allowedlist.txt"
}

variable "config_object_name" {
  description = "Object name squid.conf is written to. Must match what the image's boot script fetches."
  type        = string
  default     = "squid.conf"
}

variable "additional_config_files" {
  description = "Extra objects to place in the config bucket, object name -> file contents. The fileset()-driven half of the AWS module's config upload, expressed as an explicit map."
  type        = map(string)
  default     = {}
}

variable "create_logs_bucket" {
  description = "Whether to create the access-log archival bucket."
  type        = bool
  default     = true
}

variable "logs_bucket_name" {
  description = "Name of the logs bucket. Null derives it from the name prefix."
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Days before an object in the logs bucket is deleted. The AWS module configures NO lifecycle rules on its logs bucket at all, so this is a deliberate improvement rather than a port - Squid access logs on the egress path are the audit trail for every outbound call and are worth an explicit retention decision."
  type        = number
  default     = 90
}

variable "log_archive_after_days" {
  description = "Days before an object in the logs bucket is moved to Archive storage. Must be less than log_retention_days. Null disables the transition."
  type        = number
  default     = 30
}

variable "bucket_versioning" {
  description = "Object versioning on both buckets: Enabled or Disabled. Enabled matters more here than on envoy-proxy - it is the rollback path for a bad allowlist push."
  type        = string
  default     = "Enabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.bucket_versioning)
    error_message = "bucket_versioning must be Enabled or Disabled."
  }
}

variable "bucket_kms_key_id" {
  description = "Customer-managed key for both buckets. Null uses Oracle-managed encryption."
  type        = string
  default     = null
}

# Break-glass SSH key.

variable "generate_ssh_key" {
  description = <<-EOT
    Whether to generate a break-glass SSH keypair, inject the public half and
    store the private half in OCI Vault.

    SUBSTITUTE - check sheet feature 11, identical to envoy-proxy's feature 13.
    Every oci_vault_secret requires BOTH a vault_id and a KMS key_id; SSM
    Parameter Store's free Standard-tier String type has no counterpart. When
    either is null the key is still generated and injected but nothing is
    stored, and the private half then exists only in Terraform state.
  EOT
  type        = bool
  default     = true
}

variable "ssh_public_keys" {
  description = "Additional SSH public keys to authorize on the instances, on top of the generated break-glass key."
  type        = list(string)
  default     = []
}

variable "vault_id" {
  description = "OCID of the OCI Vault the break-glass private key is stored in. Null skips storage."
  type        = string
  default     = null
}

variable "vault_key_id" {
  description = "OCID of the KMS key encrypting the secret. Required by oci_vault_secret alongside vault_id - there is no keyless secret."
  type        = string
  default     = null
}
