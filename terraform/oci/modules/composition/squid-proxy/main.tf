locals {
  name_prefix = "${var.environment}-${var.project_name}-squid"
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# ============================================================================
# Object Storage buckets for config/logs (equivalent of AWS S3 buckets via
# ../../base/s3-bucket)
# ============================================================================
resource "oci_objectstorage_bucket" "config" {
  count = var.create_config_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "${local.name_prefix}-config"
  versioning     = "Enabled"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_objectstorage_bucket" "logs" {
  count = var.create_logs_bucket ? 1 : 0

  compartment_id = var.compartment_id
  namespace      = data.oci_objectstorage_namespace.this.namespace
  name           = "${local.name_prefix}-logs"
  versioning     = "Disabled"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# IAM - Dynamic Group + Policy
# ============================================================================
resource "oci_identity_dynamic_group" "squid" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for Squid proxy instances"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.squid-proxy.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "squid" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Policy for Squid proxy instances"

  statements = concat(
    [
      "Allow dynamic-group ${oci_identity_dynamic_group.squid.name} to use metrics in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${oci_identity_dynamic_group.squid.name} to use log-content in compartment id ${var.compartment_id}",
    ],
    var.create_config_bucket ? [
      "Allow dynamic-group ${oci_identity_dynamic_group.squid.name} to read objects in compartment id ${var.compartment_id} where target.bucket.name = '${local.name_prefix}-config'",
    ] : [],
    var.create_logs_bucket ? [
      "Allow dynamic-group ${oci_identity_dynamic_group.squid.name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${local.name_prefix}-logs'",
    ] : [],
  )

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Network Security Groups
# ============================================================================
resource "oci_core_network_security_group" "asg" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-instance-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group" "nlb" {
  count = var.create_nlb ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-nlb-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "instance_from_nlb" {
  count = var.create_nlb ? 1 : 0

  network_security_group_id = oci_core_network_security_group.asg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.nlb[0].id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Allow traffic from NLB to Squid instances"
  tcp_options {
    destination_port_range {
      min = var.squid_port
      max = var.squid_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "nlb_to_instance" {
  count = var.create_nlb ? 1 : 0

  network_security_group_id = oci_core_network_security_group.nlb[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.asg.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Allow outbound traffic from NLB to Squid instances"
  tcp_options {
    destination_port_range {
      min = var.squid_port
      max = var.squid_port
    }
  }
}

# ============================================================================
# Instance Configuration (equivalent of AWS Launch Template)
# ============================================================================
resource "oci_core_instance_configuration" "squid" {
  compartment_id = var.compartment_id
  display_name   = local.name_prefix

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id = var.compartment_id
      shape          = var.shape

      shape_config {
        ocpus         = var.instance_ocpus
        memory_in_gbs = var.instance_memory_in_gbs
      }

      source_details {
        source_type             = "image"
        image_id                = var.image_id
        boot_volume_size_in_gbs = var.root_volume_size_in_gbs
      }

      create_vnic_details {
        subnet_id        = var.proxy_subnet_id
        nsg_ids          = [oci_core_network_security_group.asg.id]
        assign_public_ip = false
      }

      metadata = merge(
        var.ssh_authorized_keys != null ? { ssh_authorized_keys = var.ssh_authorized_keys } : {},
        var.user_data != null ? { user_data = base64encode(var.user_data) } : {},
      )

      freeform_tags = merge(var.freeform_tags, { "${var.environment}.squid-proxy" = "true" })
      defined_tags  = var.defined_tags
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Instance Pool (equivalent of AWS Auto Scaling Group)
# ============================================================================
resource "oci_core_instance_pool" "squid" {
  compartment_id            = var.compartment_id
  display_name              = "${local.name_prefix}-pool"
  instance_configuration_id = oci_core_instance_configuration.squid.id
  size                      = var.size

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = var.proxy_subnet_id
  }

  dynamic "load_balancers" {
    for_each = var.create_nlb ? [1] : []
    content {
      load_balancer_id = oci_network_load_balancer_network_load_balancer.squid[0].id
      backend_set_name = oci_network_load_balancer_backend_set.squid[0].name
      port             = var.squid_port
      vnic_selection   = "PrimaryVnic"
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_objectstorage_bucket.config]
}

# ============================================================================
# Network Load Balancer (equivalent of AWS NLB + target group + TCP/TLS
# listeners)
# ============================================================================
resource "oci_network_load_balancer_network_load_balancer" "squid" {
  count = var.create_nlb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-nlb"
  subnet_id      = var.lb_subnet_id
  is_private     = true

  network_security_group_ids = [oci_core_network_security_group.nlb[0].id]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_network_load_balancer_backend_set" "squid" {
  count = var.create_nlb ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.squid[0].id
  name                     = "${local.name_prefix}-bes"
  policy                   = "FIVE_TUPLE"

  health_checker {
    protocol = "TCP"
    port     = var.squid_port
  }
}

resource "oci_network_load_balancer_listener" "squid" {
  count = var.create_nlb ? 1 : 0

  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.squid[0].id
  name                     = "${local.name_prefix}-listener"
  default_backend_set_name = oci_network_load_balancer_backend_set.squid[0].name
  port                     = var.squid_port
  protocol                 = "TCP"
}
