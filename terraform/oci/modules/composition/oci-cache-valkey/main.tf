# OCI Cache (Valkey) - the AWS ElastiCache / GCP Memorystore-for-Valkey analogue.
# Strategy: DIRECT-RESOURCE (no usable provider registry module exists for this
# service). One OCI resource replaces two AWS ones: there is no
# aws_elasticache_subnet_group counterpart (subnet_id is an argument on the
# cluster), and the AWS security group becomes a module-owned, EMPTY
# oci_core_network_security_group that the security-last phase unit fills in.

# Module-owned network access-control object. Created EMPTY on purpose: the
# security-last stack phase (security-rules) writes the rules into it, reading
# nsg_id from this module's output. Do not add rules here - that reintroduces
# the dependency cycle the security-last split exists to break.
resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${local.display_name}-nsg"

  freeform_tags = local.common_freeform_tags
}

# Engine parameters. Count-gated and OFF by default: every live AWS unit uses
# the stock default.valkey8.cluster.on group, so the first cut creates zero.
resource "oci_redis_oci_cache_config_set" "main" {
  count = var.create_config_set ? 1 : 0

  compartment_id   = var.compartment_id
  display_name     = "${local.display_name}-config"
  software_version = var.software_version
  description      = var.config_set_description

  configuration_details {
    dynamic "items" {
      for_each = var.config_set_parameters
      content {
        config_key   = items.key
        config_value = items.value
      }
    }
  }

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition     = !var.create_config_set || length(var.config_set_parameters) > 0
      error_message = "create_config_set is true but config_set_parameters is empty - an OCI Cache Config Set requires at least one configuration item."
    }
  }
}

# The cluster.
resource "oci_redis_redis_cluster" "main" {
  compartment_id = var.compartment_id
  display_name   = local.display_name

  # Engine: one field where AWS has engine + engine_version.
  software_version = var.software_version

  # Topology. shard_count is only sent when SHARDED; OCI rejects it otherwise.
  cluster_mode       = var.cluster_mode
  shard_count        = local.is_sharded ? var.shard_count : null
  node_count         = var.node_count
  node_memory_in_gbs = var.node_memory_in_gbs

  # Network placement. subnet_id is pre-existing (owned by vpc-network);
  # nsg_ids merges the module-owned NSG with any additional ones.
  subnet_id = var.subnet_id
  nsg_ids   = local.nsg_ids

  oci_cache_config_set_id = local.config_set_id

  # Create-time restore, mutually exclusive. backup_id ~ AWS snapshot_name;
  # import_from_object_storage ~ AWS snapshot_arns. Neither applies after create.
  backup_id = var.backup_id

  dynamic "import_from_object_storage_details" {
    for_each = var.import_from_object_storage == null ? [] : [var.import_from_object_storage]
    content {
      bucket    = import_from_object_storage_details.value.bucket
      namespace = import_from_object_storage_details.value.namespace

      dynamic "objects" {
        for_each = import_from_object_storage_details.value.objects
        content {
          object = objects.value
        }
      }
    }
  }

  # Arguments deliberately NOT set because they do not exist on this resource
  # (security-relevant divergences, others in variables.tf):
  #   transit_encryption - TLS is mandatory on with no off switch; the AWS units
  #     run transit_encryption_enabled = false, which this module cannot replicate.
  #   at_rest_encryption / kms_key - no argument exists and OCI's at-rest
  #     behaviour for this service is undocumented - unverified, not equivalent.
  #   automatic_failover / multi_az - implicit (node_count > 1 = primary +
  #     auto-promoting replicas). ap-mumbai-1 has 1 AD / 3 fault domains, so
  #     isolation is fault-domain-level only; an AD-level event is a regional risk
  #     no configuration can mitigate.
  #   az/slot placement, maintenance window, auto-minor-version-upgrade,
  #   notification_arn, log delivery - no argument exists.
  #   port - 6379, not settable.

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    # Cross-variable rules live here rather than in `validation` blocks so the
    # module holds on Terraform >= 1.5 (cross-variable validation needs >= 1.9).
    precondition {
      condition     = !local.is_sharded || var.shard_count != null
      error_message = "cluster_mode = \"SHARDED\" requires shard_count to be set (odd, 3-99)."
    }

    precondition {
      condition     = local.is_sharded || var.shard_count == null
      error_message = "shard_count is only valid when cluster_mode = \"SHARDED\". Leave it null for a NONSHARDED cluster."
    }

    precondition {
      # Non-sharded clusters top out at 5 nodes (1 primary + 4 read replicas).
      # The per-shard ceiling for SHARDED clusters was not verified, so it is
      # deliberately not asserted here rather than guessed.
      condition     = local.is_sharded || var.node_count <= 5
      error_message = "A NONSHARDED OCI Cache cluster supports at most 5 nodes in total. Use cluster_mode = \"SHARDED\" (odd shard_count >= 3) to go wider."
    }

    precondition {
      condition     = var.backup_id == null || var.import_from_object_storage == null
      error_message = "backup_id and import_from_object_storage are mutually exclusive create-time restore sources - set at most one."
    }

    precondition {
      condition     = !(var.create_config_set && var.oci_cache_config_set_id != null)
      error_message = "Set either create_config_set (module-owned config set) or oci_cache_config_set_id (pre-existing), not both."
    }
  }
}

# CROSS-REGION GLOBAL REPLICATION: NONE.
# This is where aws_elasticache_global_replication_group would have been. It is
# not here because OCI has no cross-region, continuously-replicating cache
# primitive - not a weaker one, none. The five AWS outputs
# global_replication_group_{id,arn,name,suffix}, is_primary_cluster and
# is_secondary_cluster therefore have no counterpart and are NOT emitted.
# The documented mitigation is backup -> export to Object Storage -> cross-region
# replication -> re-import into a NEW cluster: backup/restore DR, not live
# replication (RPO bounded by backup frequency, RTO includes provisioning a new
# cluster, nothing promotes automatically). OUT OF SCOPE here and blocked on the
# oracle gate - only the first link (backup + export trigger) exists below.

# Backup. One resource = one backup, not a schedule. Off by default.
resource "oci_redis_oci_cache_backup" "main" {
  count = var.create_backup ? 1 : 0

  compartment_id    = var.compartment_id
  display_name      = "${local.display_name}-backup"
  source_cluster_id = oci_redis_redis_cluster.main.id

  retention_period_in_days = var.backup_retention_period_in_days
  backup_source            = var.backup_source

  # Incrementing this pushes the backup into Object Storage - link 2 of the DR
  # substitute chain. Links 3 and 4 are not this module's.
  export_to_object_storage_trigger = var.backup_export_to_object_storage_trigger

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags
}

# AUTH. Native multi-user ACLs where AWS has a single auth_token string.
# Empty by default - AUTH is unset in every live AWS unit reviewed.
resource "oci_redis_oci_cache_user" "main" {
  for_each = var.cache_users

  compartment_id = var.compartment_id
  name           = each.key
  description    = each.value.description
  acl_string     = each.value.acl_string
  status         = each.value.status

  authentication_mode {
    authentication_type = each.value.authentication_type
    # Already-hashed digests only. This module never sees a plaintext password.
    hashed_passwords = lookup(var.cache_user_hashed_passwords, each.key, null)
  }

  freeform_tags = local.common_freeform_tags
  defined_tags  = var.defined_tags

  lifecycle {
    precondition {
      condition = each.value.authentication_type != "PASSWORD" || contains(
        nonsensitive(keys(var.cache_user_hashed_passwords)), each.key
      )
      error_message = "cache_users entry uses authentication_type = PASSWORD but has no matching key in cache_user_hashed_passwords."
    }
  }
}

resource "oci_redis_redis_cluster_attach_oci_cache_user" "main" {
  count = length(var.cache_users) > 0 ? 1 : 0

  redis_cluster_id = oci_redis_redis_cluster.main.id
  oci_cache_users  = sort([for u in oci_redis_oci_cache_user.main : u.id])
}
