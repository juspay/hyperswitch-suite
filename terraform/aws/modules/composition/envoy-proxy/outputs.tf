output "lb_arn" {
  description = "ARN of the Load Balancer"
  value       = var.create_lb ? module.alb[0].arn : var.existing_lb_arn
}

output "lb_dns_name" {
  description = "DNS name of the Load Balancer (null if using existing LB)"
  value       = var.create_lb ? module.alb[0].dns_name : null
}

output "lb_zone_id" {
  description = "Zone ID of the Load Balancer (null if using existing LB)"
  value       = var.create_lb ? module.alb[0].zone_id : null
}

output "target_group_arns" {
  description = "Map of deployment names to target group ARNs"
  value       = { for v in local.deployments : v.deployment => v.target_group_arns }
}

output "launch_template_id" {
  description = "ID of the launch template (created or existing)"
  value       = local.launch_template_id
}

output "launch_template_version" {
  description = "Version of the launch template being used"
  value       = local.launch_template_version
}

output "launch_template_created" {
  description = "Whether launch template was created by this module (true) or using existing (false)"
  value       = !var.use_existing_launch_template
}

output "asg_ids" {
  description = "Map of deployment names to Auto Scaling Group IDs"
  value = {
    for k, v in module.asg : local.deployments[k].deployment => v.autoscaling_group_id
  }
}

output "asg_names" {
  description = "Map of deployment names to Auto Scaling Group names"
  value = {
    for k, v in module.asg : local.deployments[k].deployment => v.autoscaling_group_name
  }
}

output "asg_security_group_id" {
  description = "Security group ID for ASG instances"
  value       = module.asg_security_group.security_group_id
}

output "lb_security_group_id" {
  description = "Security group ID for load balancer (null if using existing LB)"
  value       = var.create_lb ? module.lb_security_group[0].security_group_id : null
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket for logs (created or existing)"
  value       = local.logs_bucket_name
}

output "logs_bucket_arn" {
  description = "ARN of the S3 bucket for logs (created or existing)"
  value       = local.logs_bucket_arn
}

output "logs_bucket_created" {
  description = "Whether logs bucket was created by this module (true) or using existing (false)"
  value       = var.create_logs_bucket
}

output "config_bucket_name" {
  description = "Name of the S3 bucket for configuration (created or existing)"
  value       = local.config_bucket_name
}

output "config_bucket_arn" {
  description = "ARN of the S3 bucket for configuration (created or existing)"
  value       = local.config_bucket_arn
}

output "config_bucket_created" {
  description = "Whether config bucket was created by this module (true) or using existing (false)"
  value       = var.create_config_bucket
}

output "iam_role_arn" {
  description = "ARN of the IAM role (created or existing)"
  value       = local.iam_role_arn
}

output "iam_role_name" {
  description = "Name of the IAM role (created or existing)"
  value       = local.iam_role_name
}

output "iam_role_created" {
  description = "Whether IAM role was created by this module (true) or using existing (false)"
  value       = var.create_iam_role
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile (created or existing)"
  value       = local.instance_profile_name
}

output "ssh_key_name" {
  description = "Name of the SSH key pair"
  value       = var.generate_ssh_key ? module.key_pair[0].key_pair_name : var.key_name
}

output "ssh_key_generated" {
  description = "Whether SSH key was auto-generated (true) or using existing key (false)"
  value       = var.generate_ssh_key
}

output "ssh_key_parameter_name" {
  description = "AWS Systems Manager Parameter Store name containing the private SSH key (only if auto-generated)"
  value       = var.generate_ssh_key ? aws_ssm_parameter.envoy_private_key[0].name : null
}

output "ssh_key_pair_id" {
  description = "EC2 Key Pair ID (only if auto-generated)"
  value       = var.generate_ssh_key ? module.key_pair[0].key_pair_id : null
}

output "ssh_key_retrieval_command" {
  description = "Command to retrieve the private SSH key from Parameter Store (only if auto-generated)"
  value = var.generate_ssh_key ? "aws ssm get-parameter --name \"${aws_ssm_parameter.envoy_private_key[0].name}\" --with-decryption --query 'Parameter.Value' --output text > ${module.key_pair[0].key_pair_name}.pem && chmod 400 ${module.key_pair[0].key_pair_name}.pem" : null
}

output "config_version" {
  description = "Current configuration version hash"
  value       = substr(md5(local.envoy_config_content), 0, 8)
}
