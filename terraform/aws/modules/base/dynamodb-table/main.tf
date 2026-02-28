resource "aws_dynamodb_table" "this" {
  count = var.create ? 1 : 0

  name         = var.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  # Required attributes
  dynamic "attribute" {
    for_each = var.attributes
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }

  # Provisioned throughput (only used when billing_mode = "PROVISIONED")
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_point_in_time_recovery
  }

  # Server-side encryption
  server_side_encryption {
    enabled     = var.enable_encryption
    kms_key_arn = var.kms_key_arn
  }

  # TTL configuration (optional)
  dynamic "ttl" {
    for_each = var.ttl_attribute_name != null ? [1] : []
    content {
      enabled        = var.ttl_enabled
      attribute_name = var.ttl_attribute_name
    }
  }

  # Global Secondary Indexes (optional)
  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name            = global_secondary_index.value.name
      hash_key        = global_secondary_index.value.hash_key
      range_key       = global_secondary_index.value.range_key
      projection_type = global_secondary_index.value.projection_type
      read_capacity   = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity  = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  # Local Secondary Indexes (optional)
  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name            = local_secondary_index.value.name
      range_key       = local_secondary_index.value.range_key
      projection_type = local_secondary_index.value.projection_type
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.table_name
    }
  )
}
