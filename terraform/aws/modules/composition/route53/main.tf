# ============================================================================
# Route53 Hosted Zones
# ============================================================================
resource "aws_route53_zone" "this" {
  for_each = var.route53_zones

  name              = each.value.name
  comment           = each.value.comment
  force_destroy     = each.value.force_destroy
  delegation_set_id = each.value.delegation_set_id

  # VPC association for private hosted zones
  dynamic "vpc" {
    for_each = each.value.vpc != null && each.value.vpc.vpc_id != null ? [each.value.vpc] : []
    content {
      vpc_id     = vpc.value.vpc_id
      vpc_region = vpc.value.vpc_region
    }
  }

  tags = merge(
    local.common_tags,
    each.value.tags,
    {
      Name = each.value.name
    }
  )
}

# ============================================================================
# Route53 Records (Zone-specific)
# ============================================================================
resource "aws_route53_record" "this" {
  for_each = merge([
    for zone_key, zone in var.route53_zones : {
      for record_key, record in zone.records : "${zone_key}_${record_key}" => merge(record, {
        zone_key  = zone_key
        zone_name = zone.name
      })
    }
  ]...)

  zone_id         = aws_route53_zone.this[each.value.zone_key].zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = each.value.alias == null ? each.value.ttl : null
  records         = each.value.alias == null ? each.value.records : null
  health_check_id = each.value.health_check_id
  set_identifier  = each.value.set_identifier
  allow_overwrite = each.value.allow_overwrite

  dynamic "alias" {
    for_each = each.value.alias != null ? [each.value.alias] : []
    content {
      name                   = alias.value.name
      zone_id                = alias.value.zone_id
      evaluate_target_health = alias.value.evaluate_target_health
    }
  }

  dynamic "cidr_routing_policy" {
    for_each = each.value.cidr_routing_policy != null ? [each.value.cidr_routing_policy] : []
    content {
      collection_id = cidr_routing_policy.value.collection_id
      location_name = cidr_routing_policy.value.location_name
    }
  }

  dynamic "failover_routing_policy" {
    for_each = each.value.failover_routing_policy != null ? [each.value.failover_routing_policy] : []
    content {
      type = failover_routing_policy.value.type
    }
  }

  dynamic "geolocation_routing_policy" {
    for_each = each.value.geolocation_routing_policy != null ? [each.value.geolocation_routing_policy] : []
    content {
      continent   = geolocation_routing_policy.value.continent
      country     = geolocation_routing_policy.value.country
      subdivision = geolocation_routing_policy.value.subdivision
    }
  }

  dynamic "geoproximity_routing_policy" {
    for_each = each.value.geoproximity_routing_policy != null ? [each.value.geoproximity_routing_policy] : []
    content {
      aws_region       = geoproximity_routing_policy.value.aws_region
      bias             = geoproximity_routing_policy.value.bias
      local_zone_group = geoproximity_routing_policy.value.local_zone_group
      dynamic "coordinates" {
        for_each = geoproximity_routing_policy.value.coordinates != null ? [geoproximity_routing_policy.value.coordinates] : []
        content {
          latitude  = coordinates.value.latitude
          longitude = coordinates.value.longitude
        }
      }
    }
  }

  dynamic "latency_routing_policy" {
    for_each = each.value.latency_routing_policy != null ? [each.value.latency_routing_policy] : []
    content {
      region = latency_routing_policy.value.region
    }
  }

  dynamic "weighted_routing_policy" {
    for_each = each.value.weighted_routing_policy != null ? [each.value.weighted_routing_policy] : []
    content {
      weight = weighted_routing_policy.value.weight
    }
  }

  multivalue_answer_routing_policy = each.value.multivalue_answer_routing_policy

  depends_on = [aws_route53_zone.this]
}
