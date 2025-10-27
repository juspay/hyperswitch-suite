resource "aws_autoscaling_group" "this" {
  name                      = var.name
  vpc_zone_identifier       = var.subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  target_group_arns         = var.target_group_arns
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  enabled_metrics           = var.enabled_metrics

  launch_template {
    id      = var.launch_template_id
    version = var.launch_template_version
  }

  # Base tag for ASG itself
  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = false
  }

  # Dynamic tags from var.tags (ASG level)
  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  # Dynamic tags from var.instance_tags (propagated to instances)
  dynamic "tag" {
    for_each = var.instance_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  # Instance Refresh Configuration (optional)
  # When enabled, automatically replaces instances when launch template changes
  # with manual checkpoints for validation
  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []

    content {
      strategy = "Rolling"

      preferences {
        min_healthy_percentage = var.instance_refresh_preferences.min_healthy_percentage
        instance_warmup        = var.instance_refresh_preferences.instance_warmup
        max_healthy_percentage = var.instance_refresh_preferences.max_healthy_percentage

        # Checkpoints - ASG pauses at these percentages for manual validation
        checkpoint_percentages = var.instance_refresh_preferences.checkpoint_percentages
        checkpoint_delay       = var.instance_refresh_preferences.checkpoint_delay

        # How to handle protected/standby instances during refresh
        scale_in_protected_instances = var.instance_refresh_preferences.scale_in_protected_instances
        standby_instances            = var.instance_refresh_preferences.standby_instances
      }

      # Triggers that automatically start an instance refresh
      triggers = var.instance_refresh_triggers
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}
