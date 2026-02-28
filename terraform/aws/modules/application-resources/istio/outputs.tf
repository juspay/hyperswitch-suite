# ============================================================================
# Outputs
# ============================================================================

output "lb_security_group_id" {
  description = "ID of the created load balancer security group"
  value       = var.create ? aws_security_group.lb_security_group[*].id : []
}

