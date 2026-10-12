# VM tier: instance configuration -> instance pool -> autoscaling.
# An instance pool references exactly one instance configuration, and an
# autoscaling configuration attaches to exactly one instance pool.

resource "tls_private_key" "break_glass" {
  count = var.generate_ssh_key ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# oci_vault_secret requires BOTH a vault_id and a KMS key_id. When either is
# null the key is still injected so the fleet stays reachable, but the private
# half then lives only in Terraform state.
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

resource "oci_core_instance_configuration" "this" {
  for_each = local.deployments

  # create_before_destroy IS LOAD-BEARING, not hygiene. Every attribute of
  # this resource is immutable, so ANY change is a replace, and a plain
  # destroy-then-create fails with 409-Conflict because the pool's
  # instance_configuration_id keeps pointing at the old configuration (scaling
  # the pool to zero does NOT release it). create_before_destroy produces the
  # only order that works: create the new config, repoint the pool, delete the
  # old. It does NOT retroactively re-home running instances.
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

      # image_id straight through - no OCI-published Envoy image to derive one
      # from. boot_volume_size_in_gbs is a string on this resource. kms_key_id
      # null = Oracle-managed boot-volume encryption.
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

      # IMDSv2-equivalent hardening: disables the unauthenticated /opc/v1/
      # legacy metadata endpoints alongside the token-gated /opc/v2/.
      instance_options {
        are_legacy_imds_endpoints_disabled = var.disable_legacy_imds_endpoints
      }

      # Compute Instance Monitoring is the ONLY source of MEMORY_UTILIZATION
      # for the autoscaling policy; the image must also run the Oracle Cloud
      # Agent for it to produce metrics.
      agent_config {
        is_monitoring_disabled = false
        is_management_disabled = false

        plugins_config {
          name          = "Compute Instance Monitoring"
          desired_state = "ENABLED"
        }
      }

      # A cost-optimized on-demand/spot blend is two deployments with a statically
      # chosen size split; an OCI pool is homogeneous per capacity type.
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
      # ONLY the INSTANCE needs the dynamic-group-matching tag; the instance
      # configuration and pool are not principals a dynamic group can match.
      defined_tags = merge(var.defined_tags, local.identity_defined_tags)
    }
  }

  freeform_tags = local.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_core_instance_pool" "this" {
  for_each = local.deployments

  compartment_id            = var.compartment_id
  instance_configuration_id = oci_core_instance_configuration.this[each.key].id
  display_name              = "${local.display_name}-${each.key}"
  size                      = each.value.min_replicas

  # One placement per availability domain. ap-mumbai-1 has ONE, so fault-domain
  # spread is the only availability lever.
  placement_configurations {
    availability_domain = local.availability_domain
    primary_subnet_id   = var.subnet_id
    fault_domains       = var.fault_domains
  }

  # Pool-registered backends are equal: `weight` is not settable for them
  # (oci_load_balancer_backend_set.backend is read-only), which is why
  # var.deployments' weight lands as an instance-count ratio, not a percentage.
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

  # DELIBERATE: when an autoscaling configuration is attached, the service owns
  # the pool's runtime size and Terraform only seeds it; without this every plan
  # after the first scaling event shrinks the pool back to min_replicas. The
  # cost is that resizing a static (non-autoscaled) pool needs
  # `terraform apply -replace` or a temporary removal of this line.
  lifecycle {
    ignore_changes = [size]
  }
}

# Autoscaling: OCI uses threshold policies (explicit scale-out/scale-in
# boundaries with a fixed instance-count delta), not AWS target-tracking.
# These boundaries translate the AWS module's target_value = 70.0 and are not
# yet oracle-gated.
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

  # Extra capability relative to AWS: a known daily traffic curve is better
  # pre-scaled than reacted to after a breach.
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
