locals {
  name_prefix = "${var.environment}-${var.project_name}-locker"
}

# ============================================================================
# Network Security Groups (locker instances + LB)
# ============================================================================
resource "oci_core_network_security_group" "locker" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group" "lb" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-lb-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "locker_from_lb" {
  network_security_group_id = oci_core_network_security_group.locker.id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.lb.id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Allow traffic from LB to locker instance"
  tcp_options {
    destination_port_range {
      min = var.locker_port
      max = var.locker_port
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_to_locker" {
  network_security_group_id = oci_core_network_security_group.lb.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.locker.id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Allow LB to send traffic to locker instance"
  tcp_options {
    destination_port_range {
      min = var.locker_port
      max = var.locker_port
    }
  }
}

# Dedicated NSG attached to the PostgreSQL DB system's network_details.nsg_ids
# (equivalent of AWS aws_security_group_rule.rds_ingress_from_locker - the DB
# system doesn't create its own NSG, so this module creates one and passes it
# to the nested `database` module below)
resource "oci_core_network_security_group" "database_access" {
  count = var.create_locker_database ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.name_prefix}-db-access-nsg"
  freeform_tags  = var.freeform_tags
  defined_tags   = var.defined_tags
}

resource "oci_core_network_security_group_security_rule" "database_ingress_from_locker" {
  count = var.create_locker_database ? 1 : 0

  network_security_group_id = oci_core_network_security_group.database_access[0].id
  direction                 = "INGRESS"
  protocol                  = "6"
  source                    = oci_core_network_security_group.locker.id
  source_type               = "NETWORK_SECURITY_GROUP"
  description               = "Allow PostgreSQL access from locker instance"
  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

resource "oci_core_network_security_group_security_rule" "locker_to_database" {
  count = var.create_locker_database ? 1 : 0

  network_security_group_id = oci_core_network_security_group.locker.id
  direction                 = "EGRESS"
  protocol                  = "6"
  destination               = oci_core_network_security_group.database_access[0].id
  destination_type          = "NETWORK_SECURITY_GROUP"
  description               = "Allow locker instance to connect to PostgreSQL"
  tcp_options {
    destination_port_range {
      min = 5432
      max = 5432
    }
  }
}

# ============================================================================
# IAM - Dynamic Group + Policy (equivalent of AWS IAM role + logs/ecr/kms/s3
# custom policies + AWS managed policy attachments)
# ============================================================================
resource "oci_identity_dynamic_group" "locker" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-dynamic-group"
  description    = "Instance principal dynamic group for the locker card vault instance"
  matching_rule  = "ALL {instance.compartment.id = '${var.compartment_id}', tag.${var.environment}.locker.value = 'true'}"

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_identity_policy" "locker" {
  compartment_id = var.compartment_id
  name           = "${local.name_prefix}-policy"
  description    = "Policy for the locker card vault instance (OCIR pull, Object Storage, Vault, logging)"

  statements = concat(
    [
      "Allow dynamic-group ${oci_identity_dynamic_group.locker.name} to read repos in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${oci_identity_dynamic_group.locker.name} to manage objects in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${oci_identity_dynamic_group.locker.name} to use log-content in compartment id ${var.compartment_id}",
      "Allow dynamic-group ${oci_identity_dynamic_group.locker.name} to use metrics in compartment id ${var.compartment_id}",
    ],
    length(var.vault_key_ids) > 0 ? [
      "Allow dynamic-group ${oci_identity_dynamic_group.locker.name} to use keys in compartment id ${var.compartment_id} where target.key.id = '${join("','", var.vault_key_ids)}'",
    ] : [],
    var.additional_policy_statements,
  )

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Compute Instances
# ============================================================================
module "locker_instances" {
  source  = "oracle-terraform-modules/compute-instance/oci"
  version = "2.4.1"

  compartment_ocid = var.compartment_id

  instance_count        = var.instance_count
  instance_display_name = "${local.name_prefix}-instance"

  shape                       = var.shape
  instance_flex_ocpus         = var.instance_ocpus
  instance_flex_memory_in_gbs = var.instance_memory_in_gbs

  source_type = "image"
  source_ocid = var.image_id

  subnet_ocids         = [var.locker_subnet_id]
  primary_vnic_nsg_ids = [oci_core_network_security_group.locker.id]
  assign_public_ip     = false

  user_data = var.user_data

  freeform_tags = merge(var.freeform_tags, { "${var.environment}.locker" = "true" })
  defined_tags  = var.defined_tags
}

# ============================================================================
# Load Balancer (equivalent of AWS internal ALB + per-instance target groups
# for weighted routing)
# ============================================================================
resource "oci_load_balancer_load_balancer" "locker" {
  compartment_id = var.compartment_id
  display_name   = "${local.name_prefix}-lb"
  shape          = "flexible"
  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 100
  }
  subnet_ids                 = [var.lb_subnet_id]
  is_private                 = true
  network_security_group_ids = [oci_core_network_security_group.lb.id]

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

resource "oci_load_balancer_backend_set" "locker" {
  name             = "${local.name_prefix}-bes"
  load_balancer_id = oci_load_balancer_load_balancer.locker.id
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol    = "HTTP"
    port        = var.locker_port
    url_path    = "/health"
    return_code = 200
  }
}

resource "oci_load_balancer_backend" "locker" {
  count = var.instance_count

  load_balancer_id = oci_load_balancer_load_balancer.locker.id
  backendset_name  = oci_load_balancer_backend_set.locker.name
  ip_address       = module.locker_instances.private_ip[count.index]
  port             = var.locker_port
}

resource "oci_load_balancer_listener" "locker" {
  name                     = "${local.name_prefix}-listener"
  load_balancer_id         = oci_load_balancer_load_balancer.locker.id
  default_backend_set_name = oci_load_balancer_backend_set.locker.name
  port                     = var.locker_port
  protocol                 = "HTTP"
}

# ============================================================================
# Optional embedded database (equivalent of AWS locker/database.tf)
# ============================================================================
module "database" {
  count  = var.create_locker_database ? 1 : 0
  source = "../database"

  compartment_id = var.compartment_id
  environment    = var.environment
  project_name   = "${var.project_name}-locker"

  display_name             = "${local.name_prefix}-db"
  shape                    = var.database_shape
  subnet_id                = coalesce(var.database_subnet_id, var.locker_subnet_id)
  nsg_ids                  = [oci_core_network_security_group.database_access[0].id]
  admin_password_secret_id = var.database_admin_password_secret_id

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}
