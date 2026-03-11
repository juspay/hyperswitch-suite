# ============================================================================
# Environment & Project Configuration
# ============================================================================
variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., sandbox, dev, prod)"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

# ============================================================================
# Route53 Zone Configuration
# ============================================================================
variable "route53_zones" {
  description = "Map of Route53 zones to create with their records"
  type = map(object({
    name              = string
    comment           = optional(string, null)
    force_destroy     = optional(bool, false)
    delegation_set_id = optional(string, null)
    vpc = optional(object({
      vpc_id     = string
      vpc_region = optional(string, null)
    }), null)
    tags = optional(map(string), {})
    records = optional(map(object({
      name    = string
      type    = string
      ttl     = optional(number, 300)
      records = optional(list(string), null)
      alias = optional(object({
        name                   = string
        zone_id                = string
        evaluate_target_health = optional(bool, false)
      }), null)
      health_check_id = optional(string, null)
      set_identifier  = optional(string, null)
      allow_overwrite = optional(bool, false)
      weighted_routing_policy = optional(object({
        weight = number
      }), null)
      failover_routing_policy = optional(object({
        type = string
      }), null)
      geolocation_routing_policy = optional(object({
        continent   = optional(string, null)
        country     = optional(string, null)
        subdivision = optional(string, null)
      }), null)
      latency_routing_policy = optional(object({
        region = string
      }), null)
      cidr_routing_policy = optional(object({
        collection_id = string
        location_name = string
      }), null)
      geoproximity_routing_policy = optional(object({
        aws_region       = optional(string, null)
        bias             = optional(number, null)
        local_zone_group = optional(string, null)
        coordinates = optional(object({
          latitude  = string
          longitude = string
        }), null)
      }), null)
      multivalue_answer_routing_policy = optional(bool, false)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for zone_key, zone in var.route53_zones : alltrue([
        for record_key, record in zone.records : (
          (record.alias == null && record.records != null) ||
          (record.alias != null && record.records == null)
        )
      ])
    ])
    error_message = "Each record must have either 'alias' or 'records' defined, but not both. 'alias' and 'records' are mutually exclusive."
  }
}

# ============================================================================
# Tags
# ============================================================================
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
