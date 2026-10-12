# =============================================================================
# The VM tier: instance configuration -> instance pool -> autoscaling
# =============================================================================
# The 1:1:1 chain that replaces AWS's launch template -> ASG -> scaling policy.
# An instance pool references exactly one instance configuration, and an
# autoscaling configuration attaches to exactly one instance pool
# (auto_scaling_resources.type = "instancePool" is the only supported type).
# No extra abstraction layer, no missing piece.
# See docs/multi-cloud-parity/oci/vm-tier-and-images.md section 3.

# -----------------------------------------------------------------------------
# Break-glass SSH key (SUBSTITUTE - check sheet feature 13)
# -----------------------------------------------------------------------------
resource "tls_private_key" "break_glass" {
  count = var.generate_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# SSM Parameter Store's free Standard-tier String type has no OCI counterpart:
# oci_vault_secret requires BOTH a vault_id and a KMS key_id, so a Vault and a
# Key are prerequisites this AWS module never had to create for itself. When
# either is null the key is still generated and injected - so the fleet stays
# reachable - but the private half then lives only in Terraform state.
resource "oci_vault_secret" "break_glass" {
  count = local.vault_secret_enabled ? 1 : 0

  compartment_id = var.compartment_id
  vault_id       = var.vault_id
  key_id         = var.vault_key_id

  secret_name = replace("${local.name_prefix}-break-glass-ssh-key", "-", "_")
  description = "Break-glass SSH private key for the ${local.display_name} fleet in ${var.region}. OCI Bastion or an operator jump path is the primary access route; this key is the fallback."

  secret_content {
    content_type = "BASE64"
    content      = base64encode(tls_private_key.break_glass[0].private_key_pem)
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Instance configuration - the launch template analogue
# -----------------------------------------------------------------------------
resource "oci_core_instance_configuration" "this" {
  for_each = local.deployments

  # ---------------------------------------------------------------------------
  # create_before_destroy IS LOAD-BEARING, not hygiene.
  #
  # Every attribute of this resource is immutable, so ANY change - a new
  # metadata key, a defined tag, a different user_data - is a replace. Without
  # this, Terraform's default order is destroy-then-create, and the destroy
  # fails outright:
  #   409-Conflict, The Instance Configuration ocid1.instanceconfiguration...
  #   is associated to one or more Instance Pools.
  #
  # The association that blocks it is the POOL's, not the instances'. Confirmed
  # the hard way 2026-09-10: the pool was scaled to 0 and every member
  # terminated, and the delete STILL 409'd, because oci_core_instance_pool
  # .instance_configuration_id continues to point at it. So "cycle the
  # instances first" does not help - only repointing the pool does, and
  # Terraform will not repoint the pool until the new configuration exists.
  #
  # create_before_destroy produces the only order that works:
  #   1. create the new configuration
  #   2. update the pool's instance_configuration_id to it
  #   3. delete the old configuration, now unreferenced
  #
  # NOTE what this still does NOT do: existing RUNNING members keep booting
  # from whatever configuration they were launched with. OCI does not
  # retroactively re-home them. Picking up a changed configuration therefore
  # still requires replacing the instances - this lifecycle block only makes
  # the Terraform apply succeed.
  # ---------------------------------------------------------------------------
  lifecycle {
    create_before_destroy = true
  }

  compartment_id = var.compartment_id
  display_name   = "${local.display_name}-${each.key}-ic"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id      = var.compartment_id
      availability_domain = local.availability_domain
      display_name        = "${local.display_name}-${each.key}"
      shape               = each.value.shape

      shape_config {
        ocpus         = each.value.ocpus
        memory_in_gbs = each.value.memory_in_gbs
      }

      # image_id straight through, no data-source derivation. There is no
      # OCI-published Envoy image to fall back to, so unlike the oke unit's
      # image_type = custom-or-oke branch there is nothing to branch on.
      # boot_volume_size_in_gbs is a string on this resource, not a number.
      #
      # kms_key_id null = Oracle-managed boot-volume encryption, which is the
      # documented default posture and the mapping for AWS's ebs_encrypted =
      # true. Recorded as needing final confirmation (check sheet open
      # question 4) - the schema confirms the field is optional but Oracle's
      # own default-encrypted statement was not retrieved first-hand.
      source_details {
        source_type             = "image"
        image_id                = each.value.image_id
        boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
        kms_key_id              = var.boot_volume_kms_key_id
      }

      create_vnic_details {
        subnet_id        = var.subnet_id
        assign_public_ip = false
        nsg_ids          = local.instance_nsg_ids
        display_name     = "${local.display_name}-${each.key}-vnic"
        freeform_tags    = local.freeform_tags
      }

      metadata = local.instance_metadata

      # IMDSv2-equivalent hardening. OCI's metadata service already exposes a
      # token-gated /opc/v2/ endpoint; this disables the unauthenticated
      # /opc/v1/ legacy endpoints alongside it, which is what AWS's
      # metadata_options.http_tokens = "required" achieves.
      instance_options {
        are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
      }

      # The Compute Instance Monitoring plugin is the CloudWatch agent's
      # counterpart and is the ONLY source of MEMORY_UTILIZATION for the
      # autoscaling policy. Enabling it here is necessary but not sufficient -
      # the image must actually run the Oracle Cloud Agent.
      agent_config {
        is_monitoring_disabled = false
        is_management_disabled = false

        plugins_config {
          name          = "Compute Instance Monitoring"
          desired_state = "ENABLED"
        }
      }

      # PARTIAL - check sheet feature 9. AWS's mixed_instances_policy blends
      # on-demand and spot inside ONE scaling group with an allocation
      # strategy. An OCI pool is homogeneous: one instance configuration, one
      # capacity type. A cost-optimized blend is therefore two deployments
      # with a statically chosen size split, and there is no dynamic,
      # capacity-aware allocation strategy to replace spot_allocation_strategy
      # or on_demand_percentage_above_base_capacity.
      dynamic "preemptible_instance_config" {
        for_each = each.value.is_preemptible ? [1] : []

        content {
          preemption_action {
            type                 = "TERMINATE"
            preserve_boot_volume = false
          }
        }
      }

      freeform_tags = local.freeform_tags
      # Merged with local.identity_defined_tags (identity.tf) - only the
      # INSTANCE needs the dynamic-group-matching tag; the instance
      # configuration and pool resources below are not principals a dynamic
      # group can match against.
      defined_tags = merge(var.defined_tags, local.identity_defined_tags)
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

# -----------------------------------------------------------------------------
# Instance pool - the ASG analogue
# -----------------------------------------------------------------------------
resource "oci_core_instance_pool" "this" {
  for_each = local.deployments

  compartment_id            = var.compartment_id
  instance_configuration_id = oci_core_instance_configuration.this[each.key].id
  display_name              = "${local.display_name}-${each.key}"
  size                      = each.value.min_replicas

  # One placement configuration per availability domain, per Oracle's own
  # guidance. ap-mumbai-1 has ONE, so this list has one entry and fault-domain
  # spread is the only availability lever - a materially smaller availability
  # radius than an AWS ASG across three real AZs. That is a fact about the
  # region, not a gap in OCI's Terraform surface.
  # fault_domains left null lets OCI "make a best effort to distribute
  # instances across all fault domains based on capacity".
  placement_configurations {
    availability_domain = local.availability_domain
    primary_subnet_id   = var.subnet_id
    fault_domains       = var.fault_domains
  }

  # Native pool-to-backend-set registration, the direct analogue of an AWS
  # ASG's traffic_source_attachments: instances are registered and deregistered
  # against the backend set as the pool scales, with no per-instance Terraform
  # resource. Confirmed for the classic Load Balancer, which is what this
  # module uses.
  #
  # Note what is NOT here: a `weight`. Backends created this way are equal, and
  # oci_load_balancer_backend_set.backend is a read-only attribute, so a
  # per-backend weight cannot be set from Terraform for a pool-registered
  # backend at all. That is the mechanical reason var.deployments' weight is
  # honoured as an instance-count ratio rather than a traffic percentage.
  dynamic "load_balancers" {
    for_each = local.attach_to_lb ? [1] : []

    content {
      load_balancer_id = local.load_balancer_id
      backend_set_name = var.create_lb ? oci_load_balancer_backend_set.this[local.pool_backend_set[each.key]].name : local.attach_backend_set_name
      port             = var.backend_port
      vnic_selection   = "PrimaryVnic"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # DELIBERATE, and a real trade-off worth understanding before changing it.
  #
  # When an autoscaling configuration is attached, the SERVICE owns the pool's
  # runtime size; Terraform only seeds it. Without this, every plan after the
  # first scaling event proposes shrinking the pool back to min_replicas, and
  # an unattended apply would do exactly that mid-load.
  #
  # The cost: this also ignores size drift on a pool with autoscaling DISABLED,
  # so resizing a static pool needs `terraform apply -replace` on the pool, or
  # a temporary removal of this line. AWS's ASG has the same tension and the
  # same conventional answer (ignore_changes on desired_capacity); OCI cannot
  # make the lifecycle block conditional, so the autoscaled case wins.
  lifecycle {
    ignore_changes = [size]
  }
}

# -----------------------------------------------------------------------------
# Autoscaling configuration (SUBSTITUTE - check sheet feature 8)
# -----------------------------------------------------------------------------
# threshold, not target tracking. See var.scaling_policies and locals.tf's
# threshold_rules for the full translation and its behavioural cost; the short
# version is that AWS states one target and a managed controller converges on
# it, while this states explicit scale-out and scale-in boundaries and a fixed
# instance-count delta per breach. Threshold policies react more coarsely and
# can hunt near the boundary; pending_duration and cool_down_in_seconds are the
# only damping available.
#
# THE BOUNDARIES BELOW HAVE NOT PASSED THE ORACLE GATE (framework §4.1, check
# sheet §8 item 2, status: not yet consulted). They are a faithful translation
# of the AWS module's target_value = 70.0, not a load-tested design.
resource "oci_autoscaling_auto_scaling_configuration" "this" {
  for_each = local.autoscaled_deployments

  compartment_id       = var.compartment_id
  display_name         = "${local.display_name}-${each.key}-autoscale"
  cool_down_in_seconds = var.scaling_policies.cool_down_in_seconds
  is_enabled           = true

  auto_scaling_resources {
    id   = oci_core_instance_pool.this[each.key].id
    type = "instancePool"
  }

  dynamic "policies" {
    for_each = length(local.threshold_rules) > 0 ? [1] : []

    content {
      display_name = "${each.key}-threshold"
      policy_type  = "threshold"
      is_enabled   = true

      capacity {
        initial = each.value.min_replicas
        min     = each.value.min_replicas
        max     = each.value.max_replicas
      }

      dynamic "rules" {
        for_each = { for r in local.threshold_rules : r.display_name => r }

        content {
          display_name = rules.value.display_name

          action {
            type  = rules.value.action_type
            value = rules.value.action_value
          }

          metric {
            metric_type      = rules.value.metric_type
            metric_source    = "COMPUTE_AGENT"
            pending_duration = rules.value.pending_duration

            threshold {
              operator = rules.value.operator
              value    = rules.value.value
            }
          }
        }
      }
    }
  }

  # EXTRA capability relative to AWS, not a gap being papered over: OCI's
  # scheduled policy type has no counterpart in the AWS module. It is offered
  # because a threshold policy reacts to a breach that has already happened,
  # so a known daily traffic curve is better pre-scaled than waited for.
  dynamic "policies" {
    for_each = { for p in var.scheduled_scaling_policies : p.name => p }

    content {
      display_name = policies.value.name
      policy_type  = "scheduled"
      is_enabled   = true

      capacity {
        initial = policies.value.capacity
        min     = each.value.min_replicas
        max     = each.value.max_replicas
      }

      execution_schedule {
        type       = "cron"
        expression = policies.value.expression
        timezone   = policies.value.timezone
      }
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}
