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

  lifecycle {
    create_before_destroy = true
  }
}
