# ============================================================================
# Output values from the Istio module deployment
# ============================================================================

output "lb_security_group_id" {
  description = "ID of the created load balancer security group"
  value       = module.istio.lb_security_group_id
}
