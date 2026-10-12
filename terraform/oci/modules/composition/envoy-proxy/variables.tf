# Identity and placement.

variable "compartment_id" {
  description = "OCID of the compartment every resource in this module is created in. A flat compartment is the deliberate first-cut simplification."
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
  description = "OCI region identifier, e.g. ap-mumbai-1. Informational - the provider carries the region - but used in the connection/config descriptions."
  type        = string
}

variable "availability_domain" {
  description = <<-EOT
    Availability domain the instance pool places instances into. Null means
    "the first AD returned for this compartment".

    This variable exists because AWS's ASG takes a LIST of subnets across
    multiple AZs and OCI's instance pool takes one placement configuration per
    AD. ap-mumbai-1 is a SINGLE-AD region (only us-ashburn-1, us-phoenix-1,
    uk-london-1, eu-frankfurt-1 and us-chicago-1 have three), so the list has
    exactly one entry here and fault-domain spread is the only availability
    lever available. See oci/vm-tier-and-images.md section 3.
  EOT
  type        = string
  default     = null
}

variable "fault_domains" {
  description = "Fault domains within the availability domain to spread pool instances over. Null lets OCI \"make a best effort to distribute instances across all fault domains based on capacity\", which is the recommended default. Every AD has exactly three fault domains."
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
  description = "OCID of the VCN. Needed only to create this module's NSGs; the pool itself is placed by subnet."
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet the Envoy instances' primary VNICs land in. This is vpc-network's `incoming-envoy` tier."
  type        = string
}

variable "lb_subnet_id" {
  description = "OCID of the subnet the load balancer's VNICs land in. This is vpc-network's `external-incoming` tier (the only tier that permits a public IP on a VNIC). Required when create_lb = true."
  type        = string
  default     = null
}

variable "create_nsg" {
  description = <<-EOT
    Whether this module creates its own Network Security Groups.

    NSGs, never security lists. Created EMPTY on purpose:
    catalog/units/oci/security-rules, the last stack phase, writes the rules
    into them by reading nsg_id / lb_nsg_id from this module's outputs. Keeping
    the object here and the rules there is what breaks the dependency cycle
    between the proxy tier and everything that talks to it. Do not add
    oci_core_network_security_group_security_rule to this module.
  EOT
  type        = bool
  default     = true
}

variable "additional_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the instances' primary VNICs, on top of this module's own. Capped by OCI at 5 NSGs per VNIC, not increasable."
  type        = list(string)
  default     = []
}

variable "additional_lb_nsg_ids" {
  description = "Extra NSG OCIDs to attach to the load balancer, on top of this module's own."
  type        = list(string)
  default     = []
}

# Compute - image, shape, deployments.

variable "image_id" {
  description = <<-EOT
    OCID of the custom image the Envoy instances boot from - a Packer-built
    image carrying Envoy, its systemd unit and the config-fetch script.

    Taken directly as an OCID rather than derived from a data source: unlike
    the `oke` unit, which picks between an OKE-published image and a custom
    one, there is no OCI-published "Envoy" image to fall back to, so there is
    nothing to derive. hashicorp/packer-plugin-oracle's `oracle-oci` builder
    is the supported build path (v1.1.2, 2026-01-16; not archived) - see
    oci/vm-tier-and-images.md section 4.

    Do NOT wire a PLACEHOLDER-* string into a stack for this. That is exactly
    the wiring gap the GCP port left behind and this port is explicitly told
    not to repeat.
  EOT
  type        = string
}

variable "shape" {
  description = "Compute shape for Envoy instances. A flexible shape (VM.Standard.E4.Flex / E5.Flex) also needs shape_ocpus and shape_memory_in_gbs."
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "shape_ocpus" {
  description = "OCPUs per instance, for flexible shapes only. One OCPU is two vCPUs."
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
  description = <<-EOT
    Customer-managed KMS key for the boot volume. Null uses Oracle-managed
    encryption, which is the documented default posture for block and boot
    volumes - the AWS module's `ebs_encrypted = true` maps to "leave this
    null", not to a flag.

    Recorded caveat (open): the schema confirms this field is optional, but
    Oracle's own text confirming encryption-on-by-default with a
    service-managed key was not retrieved first-hand. Treat "encrypted at rest
    by default" as Tier 2 until that is confirmed against the Block Volume
    security documentation.
  EOT
  type        = string
  default     = null
}

variable "disable_legacy_imds_endpoints" {
  description = "Disables the IMDSv1 (/opc/v1) metadata endpoints, leaving only the token-gated v2 endpoint. The direct analogue of AWS's metadata_options.http_tokens = \"required\". Defaults true - hardened by default, matching squid-proxy's hardcoded AWS posture rather than envoy-proxy's optional one."
  type        = bool
  default     = true
}

variable "min_replicas" {
  description = "Default pool floor, per deployment. Overridable per deployment."
  type        = number
  default     = 2
}

variable "max_replicas" {
  description = "Default pool ceiling, per deployment. Overridable per deployment."
  type        = number
  default     = 6
}

variable "deployments" {
  description = <<-EOT
    Map of concurrent Envoy deployments, for blue/green and canary rollouts.
    Each key is an identifier ("stable", "canary"). One
    oci_core_instance_configuration + oci_core_instance_pool +
    oci_autoscaling_auto_scaling_configuration is created per key.

    HOW `weight` IS HONOURED, AND WHY IT DIVERGES FROM A SIMPLE PERCENTAGE:

    AWS splits traffic with `forward.target_group[].weight` on one listener
    action - two independent target groups, one percentage, flip it and you
    are done. OCI has no listener-level weighted split across backend sets:
    oci_load_balancer_load_balancer_routing_policy selects exactly ONE named
    backend set per matched request, and per-backend `weight` exists only
    INSIDE one backend set, on individual backend entries.

    Worse, backends registered by oci_core_instance_pool.load_balancers are
    created by the pool, not declared here, so their `weight` is not settable
    from Terraform at all - the `backend` attribute on
    oci_load_balancer_backend_set is read-only.

    So in the default traffic_split_mode = "shared_backend_set", every
    deployment's pool registers into ONE backend set and each instance is one
    equally-weighted backend. The traffic share of a deployment is therefore
    its INSTANCE COUNT share, not its declared weight. This module makes that
    concrete by sizing each pool proportionally to `weight` (see locals.tf,
    `pool_size_from_weight`) and rounding up, so a 90/10 weight split on a
    10-instance fleet becomes a 9-instance and a 1-instance pool.

    Consequences to be honest about:
      * granularity is bounded by instance count, not by a percentage - you
        cannot express 99/1 on a 10-instance fleet;
      * a ramp step changes pool sizes inside the ONE backend set carrying all
        live traffic, instead of resizing an isolated canary target group -
        a larger blast radius for a botched apply than an isolated target
        group;
      * autoscaling then moves the sizes again, so the ratio is a starting
        point, not an invariant.

    The alternative, traffic_split_mode = "listener_cutover", is Oracle's own
    documented blue/green pattern: one backend set per deployment and an
    all-or-nothing listener flip via var.active_deployment. It has no
    percentage at all but has a clean rollback.

    Both are implemented; pick deliberately.

    `is_preemptible` is the spot workaround: OCI has no
    mixed_instances_policy, a pool is homogeneous in capacity type, so a
    cost-optimized blend means a second deployment key with is_preemptible =
    true and a statically chosen size. There is no dynamic allocation strategy
    and no capacity-aware placement.
  EOT
  type = map(object({
    weight         = number
    image_id       = optional(string)
    shape          = optional(string)
    ocpus          = optional(number)
    memory_in_gbs  = optional(number)
    min_replicas   = optional(number)
    max_replicas   = optional(number)
    is_preemptible = optional(bool, false)
  }))
  default = {
    stable = { weight = 100 }
  }

  validation {
    condition     = length(var.deployments) > 0
    error_message = "At least one deployment must be defined."
  }

  validation {
    condition     = alltrue([for d in values(var.deployments) : d.weight >= 0])
    error_message = "All deployment weights must be >= 0."
  }

  validation {
    condition     = sum([for d in values(var.deployments) : d.weight]) > 0
    error_message = "Deployment weights must not all be zero - the total is the denominator of the instance-count split."
  }
}

variable "traffic_split_mode" {
  description = <<-EOT
    How traffic is divided between deployments. See var.deployments for the
    full explanation of the weighted-split divergence.

      "shared_backend_set" - one backend set, every pool registered into it,
                             share is proportional to instance count.
      "listener_cutover"   - one backend set per deployment, listeners point
                             at var.active_deployment. All or nothing.

    Pick deliberately; both are implemented.
  EOT
  type        = string
  default     = "shared_backend_set"

  validation {
    condition     = contains(["shared_backend_set", "listener_cutover"], var.traffic_split_mode)
    error_message = "traffic_split_mode must be \"shared_backend_set\" or \"listener_cutover\"."
  }
}

variable "active_deployment" {
  description = "Deployment key the listeners point at when traffic_split_mode = \"listener_cutover\". Null selects the highest-weight deployment. Ignored in shared_backend_set mode. A key that is not in var.deployments fails at plan time on the backend-set index rather than with a tailored message - cross-variable validation needs Terraform 1.9 and this module targets >= 1.5.0, matching the rest of the OCI tree."
  type        = string
  default     = null
}

variable "metadata" {
  description = "Additional instance metadata (cloud-init keys and free-form values) merged over the module's own. `user_data` and `ssh_authorized_keys` are set by this module and will be overwritten if supplied here."
  type        = map(string)
  default     = {}
}

variable "custom_user_data" {
  description = "cloud-init user-data run at boot: fetches envoy.yaml from the config bucket and (re)starts envoy. Delivered base64-encoded via metadata.user_data, read by the instance from http://169.254.169.254/opc/v2/instance/metadata/ - structurally identical to an AWS launch template's user_data. Null bakes nothing in and leaves the image's own boot behaviour intact."
  type        = string
  default     = null
}

# Autoscaling.

variable "enable_autoscaling" {
  description = "Whether to attach an oci_autoscaling_auto_scaling_configuration to each pool. False leaves each pool at a static size."
  type        = bool
  default     = true
}

variable "scaling_policies" {
  description = <<-EOT
    Autoscaling configuration, applied to every deployment's pool.

    OCI's oci_autoscaling_auto_scaling_configuration supports exactly two
    policy types - `threshold` (alarm-crossing: a metric crosses a value, apply
    a FIXED instance-count delta) and `scheduled` (Quartz cron). There is no
    target-tracking controller of any kind.

    So `target_value` is kept as the input shape for continuity with the AWS
    and GCP units, and locals.tf translates each enabled signal into a PAIR of
    threshold rules:

        scale out  when metric GT  target_value                   by +step
        scale in   when metric LT (target_value - scale_in_offset) by -step

    scale_in_offset exists to create a deadband. Without one, a metric sitting
    on the target oscillates: scale out, utilization drops below target, scale
    in, utilization rises above target, forever. AWS's controller has this
    damping built in; here it is the module author's job, and getting it wrong
    is a behavioural difference an SRE notices under load, not a cosmetic one.
    pending_duration (OCI's ISO-8601 "the breach must persist this long")
    and cool_down_in_seconds (minimum 300 s, same as AWS's ASG default) are
    the other two damping controls.

    memory_target_tracking requires the Compute Instance Monitoring plugin to
    be ENABLED on the image - the exact analogue of the CloudWatch agent the
    AWS module's memory policy already depends on. This module enables the
    plugin in agent_config, but the image must also actually run the Oracle
    Cloud Agent. If it does not, the metric never arrives and the policy is a
    silent no-op.

    The threshold boundaries below are a translation of target_value = 70.0,
    not a load-tested design.
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
  description = "Cron-driven capacity policies. EXTRA capability relative to AWS - the AWS module has no scheduled policy at all - offered because OCI's threshold policy reacts more coarsely than target tracking, so a known daily traffic curve is better handled by pre-scaling than by waiting for a breach. `expression` is a Quartz cron."
  type = list(object({
    name       = string
    expression = string
    timezone   = optional(string, "UTC")
    capacity   = number
  }))
  default = []
}

# Load balancer.

variable "create_lb" {
  description = "Whether this module creates the load balancer, its backend sets and its listeners. False attaches the pools to an existing backend set via existing_load_balancer_id / existing_backend_set_name."
  type        = bool
  default     = true
}

variable "existing_load_balancer_id" {
  description = "OCID of a load balancer to attach the pools to when create_lb = false. The bring-your-own-infra escape hatch, ported unchanged from the AWS module's create_* conditionals."
  type        = string
  default     = null
}

variable "existing_backend_set_name" {
  description = "Backend set name on existing_load_balancer_id to register the pools into when create_lb = false."
  type        = string
  default     = null
}

variable "lb_is_private" {
  description = "Whether the load balancer gets a VCN-private IP instead of a public one. False for the internet-facing edge role this module plays."
  type        = bool
  default     = false
}

variable "lb_shape" {
  description = "Load balancer shape. \"flexible\" is the current-generation shape and the only one that takes a bandwidth range."
  type        = string
  default     = "flexible"
}

variable "lb_min_bandwidth_mbps" {
  description = "Minimum guaranteed bandwidth for a flexible-shape load balancer, in Mbps. This is also the billing floor."
  type        = number
  default     = 10
}

variable "lb_max_bandwidth_mbps" {
  description = "Maximum bandwidth for a flexible-shape load balancer, in Mbps."
  type        = number
  default     = 100
}

variable "lb_reserved_ip_id" {
  description = "OCID of a Reserved Public IP to pin the load balancer's address across recreation. OCI load balancers get real IPs, so a plain DNS A record at this address replaces an ALIAS-record alias entirely."
  type        = string
  default     = null
}

variable "is_delete_protection_enabled" {
  description = "Blocks deletion of the load balancer through the API. OCI's counterpart to AWS's enable_deletion_protection on the ALB."
  type        = bool
  default     = false
}

variable "backend_port" {
  description = "Port Envoy itself listens on. This is the target-group port analogue - the port backends are registered on, not the port clients connect to."
  type        = number
  default     = 8080
}

variable "lb_http_port" {
  description = "Front-end port for the plain HTTP listener."
  type        = number
  default     = 80
}

variable "lb_https_port" {
  description = "Front-end port for the HTTPS listener."
  type        = number
  default     = 443
}

variable "backend_set_policy" {
  description = "Load-balancing policy for the backend set: ROUND_ROBIN, LEAST_CONNECTIONS or IP_HASH."
  type        = string
  default     = "ROUND_ROBIN"

  validation {
    condition     = contains(["ROUND_ROBIN", "LEAST_CONNECTIONS", "IP_HASH"], var.backend_set_policy)
    error_message = "backend_set_policy must be ROUND_ROBIN, LEAST_CONNECTIONS or IP_HASH."
  }
}

variable "health_check" {
  description = "Backend health check. A direct structural match for the AWS target group's health_check block: protocol, path, expected code, interval, timeout and retries all have counterparts on oci_load_balancer_backend_set.health_checker."
  type = object({
    protocol            = optional(string, "HTTP")
    port                = optional(number, null)
    url_path            = optional(string, "/health")
    return_code         = optional(number, 200)
    interval_ms         = optional(number, 10000)
    timeout_in_millis   = optional(number, 3000)
    retries             = optional(number, 3)
    response_body_regex = optional(string, null)
  })
  default = {}
}

variable "idle_timeout_in_seconds" {
  description = "Listener idle timeout. OCI's default for an HTTP listener is 60 s; AWS's ALB default is also 60 s."
  type        = number
  default     = 60
}

# TLS.

variable "enable_https_listener" {
  description = "Whether to create the HTTPS listener. Requires ssl_certificate_ids."
  type        = bool
  default     = true
}

variable "ssl_certificate_ids" {
  description = <<-EOT
    Certificate OCIDs from the Certificates Management service to attach to
    the HTTPS listener.

    Two real gaps, both structural, neither worked around by this module:

    (a) OCI accepts only a single certificate ID per listener. No array of
        additional SNI certificates. The mitigation is to use ONE wildcard or
        SAN certificate covering every hostname served by this load balancer.
        A validation below enforces the single-ID limit rather than letting
        the API reject it at apply time.

    (b) OCI's Certificates Management service cannot issue a publicly-trusted
        DV certificate. Its config_type is limited to ISSUED_BY_INTERNAL_CA,
        MANAGED_EXTERNALLY_ISSUED_BY_INTERNAL_CA and IMPORTED. The edge
        certificate has to come from an ACME client run outside Terraform and
        be IMPORTED, and renewal becomes this platform's own scheduled job
        with a hard-outage failure mode. This module only attaches; it does
        not issue.
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = length(var.ssl_certificate_ids) <= 1
    error_message = "OCI accepts only a single certificate ID per listener (\"currently only a single Id may be passed\"). Use one wildcard/SAN certificate covering every served hostname - see the variable description."
  }
}

variable "ssl_cipher_suite_name" {
  description = "Name of an OCI-predefined or customer-defined cipher suite for the HTTPS listeners. Null takes OCI's default. The aws_lb_listener ssl_policy analogue."
  type        = string
  default     = null
}

variable "ssl_protocols" {
  description = "TLS protocol versions accepted by the HTTPS listeners, e.g. [\"TLSv1.2\", \"TLSv1.3\"]. Null takes OCI's default."
  type        = list(string)
  default     = null
}

variable "enable_http_redirect" {
  description = <<-EOT
    Whether the plain HTTP listener 301-redirects to HTTPS instead of serving.

    Implemented with oci_load_balancer_rule_set (action = REDIRECT,
    redirect_uri.protocol = HTTPS) attached to the HTTP listener, because
    OCI's listener has no redirect action of its own the way AWS's
    aws_lb_listener default_action { type = "redirect" } does. Same outcome,
    one extra resource - the redirect itself is FULL parity.
  EOT
  type        = bool
  default     = true
}

variable "mtls_listener" {
  description = <<-EOT
    Dedicated mTLS listener with client-certificate verification:
    trusted_certificate_authority_ids is the trust store and verify_depth the
    chain depth control, both confirmed on oci_load_balancer_listener's schema.
  EOT
  type = object({
    enabled                           = optional(bool, false)
    port                              = optional(number, 8443)
    trusted_certificate_authority_ids = optional(list(string), [])
    verify_depth                      = optional(number, 3)
    certificate_ids                   = optional(list(string), [])
  })
  default = {}
}

# Routing rules.

variable "listener_rules" {
  description = <<-EOT
    Advanced routing rules, compiled into one
    oci_load_balancer_load_balancer_routing_policy attached to the HTTP and
    HTTPS listeners.

    Two things to know before reaching for this:

    1. NO SOURCE-IP CONDITION. OCI has no routing-layer source-IP match.
       Source-IP allow/deny belongs in the WAF policy's
       request_access_control module, which evaluates BEFORE the routing
       policy - functionally equivalent for an allow/deny decision, but not
       an alternative route target. There is deliberately no source_ip field
       on this object, so a rule author hits a Terraform error rather than
       silently getting a rule that does not filter.

    2. THE CONDITION VOCABULARY IS NOT FULLY CONFIRMED. Host, path and header
       matching are supported in principle by OCI's condition language, but
       the exact expression grammar was not verified against a live tenancy.
       The structured fields below generate what the documentation describes;
       `raw_condition` is the escape hatch that lets an operator paste a
       known-good expression verbatim and bypass this module's generator
       entirely. If the generator turns out to be wrong, raw_condition is the
       fix that needs no module change.

    target_deployment names a key in var.deployments. Under
    traffic_split_mode = "shared_backend_set" every deployment resolves to
    the SAME backend set, so routing rules cannot separate deployments in
    that mode - they can still separate this module's traffic from an
    externally-managed backend set named in target_backend_set.
  EOT
  type = list(object({
    name               = string
    raw_condition      = optional(string)
    host               = optional(list(string))
    path_prefix        = optional(string)
    path_exact         = optional(string)
    target_deployment  = optional(string)
    target_backend_set = optional(string)
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.listener_rules : r.path_prefix == null || r.path_exact == null])
    error_message = "Each listener_rules[*] may set path_prefix or path_exact, not both."
  }

  validation {
    condition = alltrue([
      for r in var.listener_rules :
      r.raw_condition != null || r.host != null || r.path_prefix != null || r.path_exact != null
    ])
    error_message = "Each listener_rules[*] must set raw_condition, host, path_prefix or path_exact - a routing-policy rule with an empty condition is rejected by the API."
  }

  validation {
    condition = alltrue([
      for r in var.listener_rules :
      (r.target_deployment == null) != (r.target_backend_set == null)
    ])
    error_message = "Each listener_rules[*] must set exactly one of target_deployment or target_backend_set."
  }
}

# WAF.

variable "enable_waf" {
  description = "Whether to attach a WAF policy to the load balancer."
  type        = bool
  default     = true
}

variable "waf_policy_id" {
  description = <<-EOT
    OCID of an oci_waf_web_app_firewall_policy to attach. Supplied, not
    created here.

    oci_waf_web_app_firewall requires precisely backend_type =
    "LOAD_BALANCER", load_balancer_id and web_app_firewall_policy_id.

    Two recorded gaps that live one layer up from this module:
      * WAF attaches only to the LBaaS load balancer, never to the Network
        Load Balancer. Irrelevant here (this module is LBaaS) and material for
        squid-proxy, which is NLB-fronted.
      * No fail-open/fail-closed argument exists on oci_waf_web_app_firewall.
  EOT
  type        = string
  default     = null
}

# Object storage - config delivery and log archival.

variable "create_config_bucket" {
  description = "Whether to create the Object Storage bucket that carries envoy.yaml and friends."
  type        = bool
  default     = true
}

variable "config_bucket_name" {
  description = "Name of the config bucket. Null derives it from the name prefix. Bucket names are unique per namespace per region, not globally, unlike S3."
  type        = string
  default     = null
}

variable "envoy_config_content" {
  description = "Rendered contents of envoy.yaml, uploaded to the config bucket. Null skips it. Uses oci_objectstorage_object.content, so Terraform's own diff redeploys on change - equivalent to the AWS module's content + etag = filemd5() pattern, and the reason no explicit hash trigger is needed (there is no etag output attribute to key one off)."
  type        = string
  default     = null
}

variable "additional_config_files" {
  description = "Extra objects to place in the config bucket, object name -> file contents. The fileset()-driven half of the AWS module's config upload, expressed as an explicit map so the caller controls exactly what ships."
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
  description = "Days before an object in the logs bucket is deleted by the lifecycle policy."
  type        = number
  default     = 90
}

variable "log_archive_after_days" {
  description = "Days before an object in the logs bucket is moved to Archive storage. Must be less than log_retention_days. Null disables the archive tier transition."
  type        = number
  default     = 30
}

variable "bucket_versioning" {
  description = "Object versioning on both buckets: Enabled or Disabled."
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
    Whether to generate a break-glass SSH keypair, inject the public half into
    the instances and store the private half in OCI Vault.

    Every oci_vault_secret requires BOTH a vault_id and a KMS key_id, so two
    prerequisite resources must exist before the first secret can. A Default
    vault has no creation charge and software-protected keys are free, so the
    step-up is architectural rather than necessarily monetary - but it is a
    real prerequisite.

    Requires vault_id and vault_key_id. When either is null the keypair is
    still generated and injected (so the instances are reachable) but nothing
    is stored, and ssh_key_vault_secret_id outputs null - the private key then
    exists ONLY in Terraform state, which makes the state backend's encryption
    load-bearing. That is the same accepted consequence recorded in the
    database module.
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
