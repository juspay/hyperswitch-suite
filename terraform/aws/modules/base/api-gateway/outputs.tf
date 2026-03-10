# ============================================================================
# REST API Outputs
# ============================================================================
output "rest_api_id" {
  description = "ID of the REST API"
  value       = aws_api_gateway_rest_api.this.id
}

output "rest_api_arn" {
  description = "ARN of the REST API"
  value       = aws_api_gateway_rest_api.this.arn
}

output "rest_api_name" {
  description = "Name of the REST API"
  value       = aws_api_gateway_rest_api.this.name
}

output "rest_api_root_resource_id" {
  description = "ID of the root resource"
  value       = aws_api_gateway_rest_api.this.root_resource_id
}

output "rest_api_execution_arn" {
  description = "Execution ARN of the REST API"
  value       = aws_api_gateway_rest_api.this.execution_arn
}

# ============================================================================
# Stage Outputs
# ============================================================================
output "stage_name" {
  description = "Name of the deployed stage"
  value       = aws_api_gateway_stage.this.stage_name
}

output "stage_arn" {
  description = "ARN of the deployed stage"
  value       = aws_api_gateway_stage.this.arn
}

output "invoke_url" {
  description = "URL to invoke the API at this stage"
  value       = aws_api_gateway_stage.this.invoke_url
}

# ============================================================================
# Resource Outputs
# ============================================================================
output "resource_ids" {
  description = "Map of resource path to resource ID"
  value       = { for path, r in aws_api_gateway_resource.this : path => r.id }
}

# ============================================================================
# Deployment Outputs
# ============================================================================
output "deployment_id" {
  description = "ID of the deployment"
  value       = aws_api_gateway_deployment.this.id
}
