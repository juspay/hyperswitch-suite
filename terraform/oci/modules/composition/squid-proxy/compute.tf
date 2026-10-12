# VM tier: instance configuration -> instance pool -> autoscaling. Mirrors
# envoy-proxy's compute layer; this fleet is egress, behind an L4 balancer, and
# runs exactly one pool.

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

resource "oci_core_instance_configuration" "this" {
  # create_before_destroy IS LOAD-BEARING, not hygiene. Every attribute is
  # immutable so any change is a replace, and a plain destroy-then-create fails
  # with 409-Conflict because the pool still points at the old configuration
  # (scaling the pool to zero does NOT release it). create_before_destroy is
  # the only ordering OCI accepts.
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

      # image_id straight through - no OCI-published Squid image to derive one from.
      # boot_volume_size_in_gbs is a string here. kms_key_id null = Oracle-managed
      # boot-volume encryption.
      source_details {
        source_type             = "image"
        image_id                = var.image_id
        boot_volume_size_in_gbs = tostring(var.boot_volume_size_in_gbs)
        kms_key_id              = var.boot_volume_kms_key_id
      }

      # No public IP, always; egress leaves via the NAT gateway, the single
      # address a PSP or bank allowlists.
      create_vnic_details {
        subnet_id        = var.subnet_id
        assign_public_ip = false
        nsg_ids          = local.instance_nsg_ids
        display_name     = "${local.display_name}-vnic"
        freeform_tags    = local.freeform_tags
      }

      metadata = local.instance_metadata

      # Disables the IMDSv1 (/opc/v1) metadata endpoints, leaving only the
      # token-gated v2 endpoint; default true for this fleet.
      instance_options {
        are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
      }

      # Compute Instance Monitoring is the ONLY source of MEMORY_UTILIZATION
      # for autoscaling; the image must also run the Oracle Cloud Agent.
      agent_config {
        is_monitoring_disabled = false
        is_management_disabled = false

        plugins_config {
          name          = "Compute Instance Monitoring"
          desired_state = "ENABLED"
        }
      }

      # One pool, one capacity type - there is no mixed spot/on-demand pool.
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
      # ONLY the INSTANCE needs the dynamic-group-matching tag; the instance
      # configuration and pool are not principals a dynamic group can match.
      defined_tags = merge(var.defined_tags, local.identity_defined_tags)
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

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

  # Not an instance_refresh equivalent: this hook only gives an individual
  # instance a grace window before teardown; a staged, health-gated rollout is
  # scripted replacement outside Terraform. See var.enable_pre_termination_hook.
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

  # Native pool-to-backend-set registration. OPEN QUESTION: this is confirmed for
  # the classic Load Balancer but NOT for a Network Load Balancer, and
  # squid-proxy's balancer is an NLB. If the API rejects it, the fallback is
  # scripted per-instance NLB backend registration, not implemented here.
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

  # DELIBERATE: when an autoscaling configuration is attached, the service owns
  # the runtime size and Terraform only seeds it; without this every post-scaling
  # plan proposes shrinking the fleet back to min_replicas. The cost is that
  # resizing a static pool needs `terraform apply -replace` or a temporary
  # removal of this line.
  lifecycle {
    ignore_changes = [size]
  }
}

# Autoscaling: threshold policies (explicit scale-out/scale-in boundaries with
# a fixed instance-count delta), not AWS target-tracking - identical translation
# to envoy-proxy's on purpose. The boundaries are not yet oracle-gated.
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
