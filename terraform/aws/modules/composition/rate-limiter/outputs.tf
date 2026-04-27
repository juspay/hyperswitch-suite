# =========================================================================
# NLB OUTPUTS
# =========================================================================
output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.this[0].arn : null
}

output "nlb_id" {
  description = "ID of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.this[0].id : null
}

output "nlb_name" {
  description = "Name of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.this[0].name : null
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.this[0].dns_name : null
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.this[0].zone_id : null
}

output "nlb_arn_suffix" {
  description = "ARN suffix of the Network Load Balancer"
  value       = var.create_nlb ? aws_lb.this[0].arn_suffix : null
}

# =========================================================================
# TARGET GROUP OUTPUTS
# =========================================================================
output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.create_nlb ? aws_lb_target_group.this[0].arn : null
}

output "target_group_id" {
  description = "ID of the target group"
  value       = var.create_nlb ? aws_lb_target_group.this[0].id : null
}

output "target_group_name" {
  description = "Name of the target group"
  value       = var.create_nlb ? aws_lb_target_group.this[0].name : null
}

# =========================================================================
# SECURITY GROUP OUTPUTS
# =========================================================================
output "nlb_security_group_id" {
  description = "ID of the NLB security group"
  value       = var.create_nlb ? module.nlb_security_group[0].security_group_id : null
}

output "nlb_security_group_arn" {
  description = "ARN of the NLB security group"
  value       = var.create_nlb ? module.nlb_security_group[0].security_group_arn : null
}

output "asg_security_group_id" {
  description = "ID of the ASG security group"
  value       = module.asg_security_group.security_group_id
}

output "asg_security_group_arn" {
  description = "ARN of the ASG security group"
  value       = module.asg_security_group.security_group_arn
}

# =========================================================================
# LISTENER OUTPUTS
# =========================================================================
output "listener_arns" {
  description = "Map of listener keys to listener ARNs"
  value       = var.create_nlb ? { for key, listener in aws_lb_listener.this : key => listener.arn } : {}
}

output "listener_ids" {
  description = "Map of listener keys to listener IDs"
  value       = var.create_nlb ? { for key, listener in aws_lb_listener.this : key => listener.id } : {}
}

# =========================================================================
# AUTO SCALING GROUP OUTPUTS
# =========================================================================
output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_arn
}

output "asg_min_size" {
  description = "Minimum size of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_min_size
}

output "asg_max_size" {
  description = "Maximum size of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_max_size
}

output "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  value       = module.asg.autoscaling_group_desired_capacity
}

# =========================================================================
# LAUNCH TEMPLATE OUTPUTS
# =========================================================================
output "launch_template_id" {
  description = "ID of the launch template"
  value       = var.use_existing_launch_template ? var.existing_launch_template_id : aws_launch_template.this[0].id
}

output "launch_template_arn" {
  description = "ARN of the launch template"
  value       = var.use_existing_launch_template ? null : aws_launch_template.this[0].arn
}

output "launch_template_default_version" {
  description = "Default version of the launch template"
  value       = var.use_existing_launch_template ? var.existing_launch_template_version : aws_launch_template.this[0].default_version
}

# =========================================================================
# IAM OUTPUTS
# =========================================================================
output "iam_role_arn" {
  description = "ARN of the IAM role"
  value       = var.create_iam_role ? module.iam_role[0].iam_role_arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = var.create_iam_role ? module.iam_role[0].iam_role_name : var.iam_role_name
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile"
  value       = var.create_iam_role ? module.iam_role[0].iam_instance_profile_arn : null
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = var.create_iam_role ? module.iam_role[0].iam_instance_profile_name : var.iam_instance_profile_name
}

# =========================================================================
# CLOUDWATCH OUTPUTS
# =========================================================================
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = var.create_log_group ? aws_cloudwatch_log_group.this[0].arn : null
}

# =========================================================================
# S3 CONFIG BUCKET OUTPUTS
# =========================================================================
output "config_bucket_name" {
  description = "Name of the S3 config bucket"
  value       = local.config_bucket_name
}

output "config_bucket_arn" {
  description = "ARN of the S3 config bucket"
  value       = local.config_bucket_arn
}

output "config_bucket_id" {
  description = "ID of the S3 config bucket"
  value       = local.config_bucket_name
}

# =========================================================================
# ELASTICACHE OUTPUTS
# =========================================================================
output "elasticache_replication_group_id" {
  description = "ID of the ElastiCache Replication Group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_id : null
}

output "elasticache_replication_group_arn" {
  description = "ARN of the ElastiCache Replication Group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_arn : null
}

output "elasticache_primary_endpoint_address" {
  description = "Address of the primary endpoint for the replication group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_primary_endpoint_address : null
}

output "elasticache_reader_endpoint_address" {
  description = "Address of the reader endpoint for the replication group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_reader_endpoint_address : null
}

output "elasticache_port" {
  description = "Port number for the replication group"
  value       = var.elasticache_config.enabled ? module.elasticache[0].replication_group_port : null
}

output "elasticache_connection_info" {
  description = "Connection information for the ElastiCache cluster"
  value       = var.elasticache_config.enabled ? module.elasticache[0].connection_info : null
}
