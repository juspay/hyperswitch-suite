output "nlb_arn" {
  description = "ARN of the Network Load Balancer"
  value       = var.create_nlb ? module.nlb[0].nlb_arn : var.existing_lb_arn
}

output "nlb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = var.create_nlb ? module.nlb[0].nlb_dns_name : null
}

output "nlb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = var.create_nlb ? module.nlb[0].nlb_zone_id : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.create_target_group ? module.target_group[0].tg_arn : var.existing_tg_arn
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

output "asg_id" {
  description = "ID of the Auto Scaling Group"
  value       = module.asg.asg_id
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.asg_name
}

output "asg_security_group_id" {
  description = "Security group ID for ASG instances"
  value       = module.asg_security_group.sg_id
}

output "lb_security_group_id" {
  description = "Security group ID for load balancer (null if using existing NLB)"
  value       = var.create_nlb ? module.lb_security_group[0].sg_id : null
}

output "logs_bucket_name" {
  description = "Name of the S3 bucket for logs"
  value       = module.logs_bucket.bucket_id
}

output "logs_bucket_arn" {
  description = "ARN of the S3 bucket for logs"
  value       = module.logs_bucket.bucket_arn
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
  value       = var.generate_ssh_key ? aws_key_pair.squid_key_pair[0].key_name : var.key_name
}

output "ssh_key_generated" {
  description = "Whether SSH key was auto-generated (true) or using existing key (false)"
  value       = var.generate_ssh_key
}

output "ssh_key_parameter_name" {
  description = "AWS Systems Manager Parameter Store name containing the private SSH key (only if auto-generated)"
  value       = var.generate_ssh_key ? aws_ssm_parameter.squid_private_key[0].name : null
}

output "ssh_key_pair_id" {
  description = "EC2 Key Pair ID (only if auto-generated)"
  value       = var.generate_ssh_key ? aws_key_pair.squid_key_pair[0].key_pair_id : null
}

output "ssh_key_retrieval_command" {
  description = "Command to retrieve the private SSH key from Parameter Store (only if auto-generated)"
  value = var.generate_ssh_key ? "aws ssm get-parameter --name \"${aws_ssm_parameter.squid_private_key[0].name}\" --with-decryption --query 'Parameter.Value' --output text > ${aws_key_pair.squid_key_pair[0].key_name}.pem && chmod 400 ${aws_key_pair.squid_key_pair[0].key_name}.pem" : null
}
