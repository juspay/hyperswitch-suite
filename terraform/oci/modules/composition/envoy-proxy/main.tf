locals {
  name_prefix = "${var.environment}-${var.project_name}-envoy"
}

data "oci_objectstorage_namespace" "this" {
  compartment_id = var.compartment_id
}

# ============================================================================
# Object Storage buckets for config/logs
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
resource "oci_identity_dynamic_group" "envoy" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for Envoy proxy instances"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.envoy-proxy.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "envoy" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Policy for Envoy proxy instances"

  statements = concat(
    [
      "Allow dynamic-group ${oci_identity_dynamic_group.envoy.name} to use metrics in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${oci_identity_dynamic_group.envoy.name} to use log-content in compartment id ${var.compartment_id}",
    ],
    var.create_config_bucket ? [
      "Allow dynamic-group ${oci_identity_dynamic_group.envoy.name} to read objects in compartment id ${var.compartment_id} where target.bucket.name = '${local.name_prefix}-config'",
    ] : [],
    var.create_logs_bucket ? [
      "Allow dynamic-group ${oci_identity_dynamic_group.envoy.name} to manage objects in compartment id ${var.compartment_id} where target.bucket.name = '${local.name_prefix}-logs'",
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

resource "oci_core_network_security_group" "lb" {
  count = var.create_lb ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-lb-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "instance_from_lb" {
  count = var.create_lb ? 1 : 0

  network_security_group_id = oci_core_network_security_group.asg.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.lb[0].id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Allow traffic from LB to Envoy"
  tcp_options {
    destination_port_range {
      min = var.envoy_traffic_port
      max = var.envoy_traffic_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_to_instance" {
  count = var.create_lb ? 1 : 0

  network_security_group_id = oci_core_network_security_group.lb[0].id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.asg.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Allow traffic to Envoy ASG on traffic port"
  tcp_options {
    destination_port_range {
      min = var.envoy_traffic_port
      max = var.envoy_traffic_port
    }
  }
}

# ============================================================================
# Instance Configuration (equivalent of AWS Launch Template)
# ============================================================================
resource "oci_core_instance_configuration" "envoy" {
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

      freeform_tags = merge(var.freeform_tags, { "${var.environment}.envoy-proxy" = "true" })
      defined_tags  = var.defined_tags
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Instance Pool (equivalent of AWS Auto Scaling Group)
# ============================================================================
resource "oci_core_instance_pool" "envoy" {
  compartment_id            = var.compartment_id
  display_name              = "${local.name_prefix}-pool"
  instance_configuration_id = oci_core_instance_configuration.envoy.id
  size                      = var.size

  placement_configurations {
    availability_domain = var.availability_domain
    primary_subnet_id   = var.proxy_subnet_id
  }

  dynamic "load_balancers" {
    for_each = var.create_lb ? [1] : []
    content {
      load_balancer_id = oci_load_balancer_load_balancer.envoy[0].id
      backend_set_name = oci_load_balancer_backend_set.envoy[0].name
      port             = var.envoy_traffic_port
      vnic_selection   = "PrimaryVnic"
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags

  depends_on = [oci_objectstorage_bucket.config]
}

# ============================================================================
# Load Balancer (L7 - equivalent of AWS ALB, since the AWS module supports
# HTTP/HTTPS/mTLS listeners with header/path-based routing)
# ============================================================================
resource "oci_load_balancer_load_balancer" "envoy" {
  count = var.create_lb ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-lb"
  shape          = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }

  subnet_ids                 = [var.lb_subnet_id]
  is_private                 = var.lb_internal
  network_security_group_ids = [oci_core_network_security_group.lb[0].id]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_load_balancer_backend_set" "envoy" {
  count = var.create_lb ? 1 : 0

  name             = "${local.name_prefix}-bes"
  load_balancer_id = oci_load_balancer_load_balancer.envoy[0].id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol    = var.health_check.protocol
    port        = var.health_check.port
    url_path    = var.health_check.protocol == "HTTP" ? var.health_check.path : null
    return_code = var.health_check.protocol == "HTTP" ? 200 : null
  }
}

resource "oci_load_balancer_listener" "http" {
  count = var.create_lb ? 1 : 0

  name                     = "${local.name_prefix}-http"
  load_balancer_id         = oci_load_balancer_load_balancer.envoy[0].id
  default_backend_set_name = oci_load_balancer_backend_set.envoy[0].name
  port                     = var.http_listener_port
  protocol                 = "HTTP"
}

resource "oci_load_balancer_listener" "https" {
  count = var.create_lb && var.enable_https_listener ? 1 : 0

  name                     = "${local.name_prefix}-https"
  load_balancer_id         = oci_load_balancer_load_balancer.envoy[0].id
  default_backend_set_name = oci_load_balancer_backend_set.envoy[0].name
  port                     = var.https_listener_port
  protocol                 = "HTTP" # backend protocol; SSL terminates at the listener via ssl_configuration below

  ssl_configuration {
    certificate_ids = var.https_certificate_ids
  }
}

# mTLS listener - equivalent of AWS aws_lb_listener.envoy_mtls
# (mutual_authentication block). OCI LB enforces client-certificate
# verification via ssl_configuration.verify_peer_certificate +
# trusted_certificate_authority_ids on a dedicated listener/port, rather
# than a separate "mutual_authentication" sub-block.
resource "oci_load_balancer_listener" "mtls" {
  count = var.create_lb && var.enable_mtls_listener ? 1 : 0

  name                     = "${local.name_prefix}-mtls"
  load_balancer_id         = oci_load_balancer_load_balancer.envoy[0].id
  default_backend_set_name = oci_load_balancer_backend_set.envoy[0].name
  port                     = var.mtls_listener_port
  protocol                 = "HTTP"

  ssl_configuration {
    certificate_ids                   = var.https_certificate_ids
    verify_peer_certificate           = true
    trusted_certificate_authority_ids = var.mtls_trusted_ca_ids
  }
}
