# =============================================================================
# The VM tier: instance configuration -> instance pool -> autoscaling
# =============================================================================
# The mirror image of envoy-proxy's compute layer, and deliberately kept the
# same shape: same 1:1:1 chain, same threshold translation, same agent config.
# The differences are that this fleet is egress not ingress, sits behind an L4
# balancer, and runs exactly one pool (the AWS module has no multi-deployment
# feature to port).

# -----------------------------------------------------------------------------
# Break-glass SSH key (SUBSTITUTE - check sheet feature 11)
# -----------------------------------------------------------------------------
resource "tls_private_key" "break_glass" {
  count = var.generate_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "oci_vault_secret" "break_glass" {
  count = local.vault_secret_enabled ? 1 : 0

  compartment_id = var.compartment_id
  vault_id       = var.vault_id
  key_id         = var.vault_key_id

  secret_name = replace("${local.name_prefix}-break-glass-ssh-key", "-", "_")
  description = "Break-glass SSH private key for the ${local.display_name} egress proxy fleet in ${var.region}."

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
  # See envoy-proxy/compute.tf for the full reasoning. Short version: every
  # attribute here is immutable so any change is a replace, and a plain
  # destroy-then-create fails with 409-Conflict because the POOL still points
  # at the old configuration - scaling the pool to zero does NOT release it.
  # create_before_destroy is the only ordering OCI accepts.
  lifecycle {
    create_before_destroy = true
  }

  compartment_id = var.compartment_id
  display_name   = "${local.display_name}-ic"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id      = var.compartment_id
      availability_domain = local.availability_domain
      display_name        = local.display_name
      shape               = var.shape

      shape_config {
        ocpus         = var.shape_ocpus
        memory_in_gbs = var.shape_memory_in_gbs
      }

      # image_id taken straight through - there is no OCI-published Squid image
      # to derive one from. boot_volume_size_in_gbs is a string here, not a
      # number. kms_key_id null = Oracle-managed boot-volume encryption, the
      # mapping for the AWS launch template's hardcoded ebs.encrypted = true.
      source_details {
        source_type             = "image"
        image_id                = var.image_id
        boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
        kms_key_id              = var.boot_volume_kms_key_id
      }

      # assign_public_ip false, always. vpc-network's outgoing-proxy tier sets
      # prohibit_public_ip_on_vnic = true anyway, which is STRONGER than AWS's
      # map_public_ip_on_launch - it forbids a public IP outright rather than
      # only changing the default. Egress leaves via the NAT gateway, which is
      # the single address a PSP or bank allowlists.
      create_vnic_details {
        subnet_id        = var.subnet_id
        assign_public_ip = false
        nsg_ids          = local.instance_nsg_ids
        display_name     = "${local.display_name}-vnic"
        freeform_tags    = local.freeform_tags
      }

      metadata = local.instance_metadata

      # The AWS base/launch-template hardcodes http_tokens = "required" for
      # this fleet. This is its counterpart, and it defaults true rather than
      # being an optional knob for the same reason.
      instance_options {
        are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
      }

      # Compute Instance Monitoring is the CloudWatch agent's counterpart and
      # the only source of MEMORY_UTILIZATION for autoscaling. Necessary but
      # not sufficient - the image must run the Oracle Cloud Agent.
      agent_config {
        is_monitoring_disabled = false
        is_management_disabled = false

        plugins_config {
          name          = "Compute Instance Monitoring"
          desired_state = "ENABLED"
        }
      }

      # PARTIAL - check sheet feature 5. One pool, one capacity type; there is
      # no mixed_instances_policy. See var.is_preemptible for why enabling this
      # on the egress path deserves more thought than on the ingress path.
      dynamic "preemptible_instance_config" {
        for_each = var.is_preemptible ? [1] : []

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
  compartment_id            = var.compartment_id
  instance_configuration_id = oci_core_instance_configuration.this.id
  display_name              = local.display_name
  size                      = var.min_replicas

  placement_configurations {
    availability_domain = local.availability_domain
    primary_subnet_id   = var.subnet_id
    fault_domains       = var.fault_domains
  }

  # PARTIAL - check sheet feature 6. This is NOT an instance_refresh
  # equivalent. AWS declares a whole staged rollout in one block
  # (min_healthy_percentage, checkpoint_percentages, checkpoint_delay), all
  # health-gated by the service. OCI's pool has no such thing; this hook only
  # gives an individual instance a grace window before it is torn down. A
  # staged, health-gated rollout is scripted replacement living outside
  # Terraform. See var.enable_pre_termination_hook.
  dynamic "lifecycle_management" {
    for_each = var.enable_pre_termination_hook ? [1] : []

    content {
      lifecycle_actions {
        pre_termination {
          is_enabled = true
          timeout    = var.pre_termination_timeout

          on_timeout {
            preserve_boot_volume_mode  = "DELETE"
            preserve_block_volume_mode = "DELETE"
          }
        }
      }
    }
  }

  # Native pool-to-backend-set registration. READ THE OPEN-QUESTION COMMENT ON
  # local.pool_load_balancer_id BEFORE TRUSTING THIS FOR AN NLB: the block is
  # confirmed for the classic Load Balancer and NOT confirmed for the Network
  # Load Balancer, and squid-proxy's balancer is an NLB. If the API rejects it,
  # the fallback is scripted per-instance oci_network_load_balancer_backend
  # registration, which is not implemented here.
  dynamic "load_balancers" {
    for_each = local.attach_to_lb ? [1] : []

    content {
      load_balancer_id = local.pool_load_balancer_id
      backend_set_name = local.pool_backend_set_name
      port             = var.squid_port
      vnic_selection   = "PrimaryVnic"
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags

  # See the same block in envoy-proxy/compute.tf for the full reasoning: the
  # autoscaling service owns the runtime size and Terraform only seeds it, so
  # without this every post-scaling plan proposes shrinking the fleet back to
  # min_replicas. The cost is that resizing a NON-autoscaled pool needs
  # `terraform apply -replace` or a temporary removal of this line; Terraform
  # cannot make a lifecycle block conditional.
  lifecycle {
    ignore_changes = [size]
  }
}

# -----------------------------------------------------------------------------
# Autoscaling configuration (SUBSTITUTE - check sheet feature 4)
# -----------------------------------------------------------------------------
# threshold, not target tracking. Identical translation to envoy-proxy's, on
# purpose - vm-tier-and-images.md §3 says this redesign should be solved once,
# not per-module, and until a shared base/vm-pool module passes the gate,
# "identical" is the next best thing to "shared".
#
# THE BOUNDARIES HAVE NOT PASSED THE ORACLE GATE (check sheet §8 item 2).
resource "oci_autoscaling_auto_scaling_configuration" "this" {
  count = local.autoscaling_enabled ? 1 : 0

  compartment_id       = var.compartment_id
  display_name         = "${local.display_name}-autoscale"
  cool_down_in_seconds = var.scaling_policies.cool_down_in_seconds
  is_enabled           = true

  auto_scaling_resources {
    id   = oci_core_instance_pool.this.id
    type = "instancePool"
  }

  dynamic "policies" {
    for_each = length(local.threshold_rules) > 0 ? [1] : []

    content {
      display_name = "threshold"
      policy_type  = "threshold"
      is_enabled   = true

      capacity {
        initial = var.min_replicas
        min     = var.min_replicas
        max     = var.max_replicas
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

  dynamic "policies" {
    for_each = { for p in var.scheduled_scaling_policies : p.name => p }

    content {
      display_name = policies.value.name
      policy_type  = "scheduled"
      is_enabled   = true

      capacity {
        initial = policies.value.capacity
        min     = var.min_replicas
        max     = var.max_replicas
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
