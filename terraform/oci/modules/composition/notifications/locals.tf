locals {
  name_prefix = "${var.project_name}-${var.environment}"

  topic_name_prefix = var.topic_name_prefix != null ? var.topic_name_prefix : "${local.name_prefix}-"

  freeform_tags = merge(
    {
      "environment" = var.environment
      "project"     = var.project_name
      "component"   = "notifications"
      "managed_by"  = "terraform"
    },
    var.freeform_tags
  )

  topics = {
    for key, cfg in var.topics : key => {
      # ONS topic names accept alphanumerics, hyphens, underscores and periods,
      # 1-256 characters, and must be unique within the compartment.
      name          = cfg.name != null ? cfg.name : "${local.topic_name_prefix}${key}"
      description   = cfg.description
      freeform_tags = merge(local.freeform_tags, cfg.freeform_tags)
      defined_tags  = merge(var.defined_tags, cfg.defined_tags)
    }
  }

  # The leading [{}] is not decoration: `merge()` with zero arguments is an
  # error, and var.topics defaults to {}, so the splat has to be guaranteed at
  # least one element.
  subscriptions = merge(concat([{}], [
    for topic_key, topic_cfg in var.topics : {
      for sub_key, sub_cfg in coalesce(topic_cfg.subscriptions, {}) :
      "${topic_key}-${sub_key}" => {
        topic_key       = topic_key
        compartment_id  = sub_cfg.compartment_id != null ? sub_cfg.compartment_id : var.compartment_id
        protocol        = sub_cfg.protocol
        endpoint        = sub_cfg.endpoint
        delivery_policy = sub_cfg.delivery_policy
        freeform_tags   = merge(local.freeform_tags, sub_cfg.freeform_tags)
        defined_tags    = merge(var.defined_tags, sub_cfg.defined_tags)
      }
    }
  ])...)
}
