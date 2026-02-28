resource "aws_autoscaling_group" "this" {
  count = var.create ? 1 : 0

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
  max_instance_lifetime     = var.max_instance_lifetime > 0 ? var.max_instance_lifetime : null
  capacity_rebalance        = var.capacity_rebalance

  # Use either launch_template (simple) or mixed_instances_policy (spot + on-demand)
  dynamic "launch_template" {
    for_each = var.enable_mixed_instances_policy ? [] : [1]
    content {
      id      = var.launch_template_id
      version = var.launch_template_version
    }
  }

  # Mixed Instances Policy for Spot + On-Demand instances
  dynamic "mixed_instances_policy" {
    for_each = var.enable_mixed_instances_policy ? [1] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = var.launch_template_id
          version            = var.launch_template_version
        }
      }

      instances_distribution {
        on_demand_base_capacity                  = var.mixed_instances_policy.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.mixed_instances_policy.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.mixed_instances_policy.spot_allocation_strategy
        spot_instance_pools                      = var.mixed_instances_policy.spot_instance_pools
        spot_max_price                           = var.mixed_instances_policy.spot_max_price != "" ? var.mixed_instances_policy.spot_max_price : null
      }
    }
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

      # Triggers - Note: In Terraform AWS Provider 5.0+, launch_template changes
      # automatically trigger instance refresh, so we filter it out to avoid warnings
      # Only add tag keys here if you want tag changes to trigger refresh
      triggers = length(var.instance_refresh_triggers) > 0 ? [
        for trigger in var.instance_refresh_triggers : trigger if trigger != "launch_template"
      ] : []
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# =========================================================================
# Auto Scaling Policies - Target Tracking
# =========================================================================

# CPU Target Tracking Scaling Policy
# Automatically scales to maintain target CPU utilization
# AWS manages both scale-up and scale-down automatically
resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count = var.create && var.enable_scaling_policies && var.scaling_policies.cpu_target_tracking.enabled ? 1 : 0

  name                   = "${var.name}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.scaling_policies.cpu_target_tracking.target_value
  }
}

# Memory Target Tracking Scaling Policy
# Automatically scales to maintain target memory utilization
# Note: Requires CloudWatch agent installed on instances to publish memory metrics
resource "aws_autoscaling_policy" "memory_target_tracking" {
  count = var.create && var.enable_scaling_policies && var.scaling_policies.memory_target_tracking.enabled ? 1 : 0

  name                   = "${var.name}-memory-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this[0].name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "mem_used_percent"
      namespace   = "CWAgent"
      statistic   = "Average"

      metric_dimension {
        name  = "AutoScalingGroupName"
        value = aws_autoscaling_group.this.name
      }
    }
    target_value = var.scaling_policies.memory_target_tracking.target_value
  }
}
