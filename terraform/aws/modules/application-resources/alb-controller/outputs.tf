# ============================================================================
# Outputs
# ============================================================================

output "alb_controller_role_arn" {
  description = "The ARN of the AWS Load Balancer Controller IAM role"
  value       = module.aws_load_balancer_controller_irsa.iam_role_arn
}

output "alb_controller_service_account" {
  description = "Service Account Name of AWS Load Balancer Controller"
  value       = kubernetes_service_account_v1.alb_controller[*].metadata[0].name
}
