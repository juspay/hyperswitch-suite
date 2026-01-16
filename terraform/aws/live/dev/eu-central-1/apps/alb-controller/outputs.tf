output "alb_controller_role_arn" {
  description = "The ARN of the AWS Load Balancer Controller IAM role"
  value       = module.aws_load_balancer_controller.alb_controller_role_arn
}

output "alb_controller_service_account" {
  description = "Service Account Name of AWS Load Balancer Controller"
  value       = module.aws_load_balancer_controller.alb_controller_service_account
}
