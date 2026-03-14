################################################################################
# Domain Outputs
################################################################################

output "domain_arn" {
  description = "The Amazon Resource Name (ARN) of the domain"
  value       = module.opensearch.domain_arn
}

output "domain_id" {
  description = "The unique identifier for the domain"
  value       = module.opensearch.domain_id
}

output "domain_name" {
  description = "The name of the domain"
  value       = local.domain_name
}

output "domain_endpoint" {
  description = "Domain-specific endpoint used to submit index, search, and data upload requests"
  value       = module.opensearch.domain_endpoint
}

output "domain_endpoint_v2" {
  description = "V2 domain endpoint that works with both IPv4 and IPv6 addresses"
  value       = module.opensearch.domain_endpoint_v2
}

################################################################################
# Dashboard (Kibana) Outputs
################################################################################

output "dashboard_endpoint" {
  description = "Domain-specific endpoint for Dashboard without https scheme"
  value       = module.opensearch.domain_dashboard_endpoint
}

output "dashboard_endpoint_v2" {
  description = "V2 domain endpoint for Dashboard that works with both IPv4 and IPv6 addresses"
  value       = module.opensearch.domain_dashboard_endpoint_v2
}

output "kibana_url" {
  description = "Full Kibana/Dashboards URL for the domain"
  value       = "https://${module.opensearch.domain_endpoint}/_dashboards/"
}

output "kibana_url_legacy" {
  description = "Full Kibana URL for the domain (legacy Elasticsearch)"
  value       = "https://${module.opensearch.domain_endpoint}/_plugin/kibana/"
}

################################################################################
# Security Group Outputs
################################################################################

output "security_group_arn" {
  description = "Amazon Resource Name (ARN) of the security group"
  value       = var.create_security_group ? aws_security_group.this[0].arn : null
}

output "security_group_id" {
  description = "ID of the security group"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "all_security_group_ids" {
  description = "All security group IDs attached to the OpenSearch domain"
  value       = concat(var.existing_security_group_ids, var.create_security_group ? [aws_security_group.this[0].id] : [])
}

################################################################################
# CloudWatch Logs Outputs
################################################################################

output "cloudwatch_log_groups" {
  description = "Map of CloudWatch log groups created and their attributes"
  value       = module.opensearch.cloudwatch_logs
}

################################################################################
# Service Linked Role Output
################################################################################

output "service_linked_role_arn" {
  description = "ARN of the OpenSearch service-linked role"
  value       = var.create_service_linked_role ? aws_iam_service_linked_role.opensearch[0].arn : null
}

output "service_linked_role_name" {
  description = "Name of the OpenSearch service-linked role"
  value       = var.create_service_linked_role ? aws_iam_service_linked_role.opensearch[0].name : null
}

################################################################################
# Connection Info
################################################################################

output "connection_info" {
  description = "Connection information for the OpenSearch domain"
  value = {
    endpoint           = module.opensearch.domain_endpoint
    dashboard_endpoint = module.opensearch.domain_dashboard_endpoint
    kibana_url         = module.opensearch.domain_endpoint != null ? "https://${module.opensearch.domain_endpoint}/_dashboards/" : null
    engine_version     = var.engine_version
    region             = coalesce(var.region, data.aws_region.current.region)

  }
}

################################################################################
# VPC Information
################################################################################

output "vpc_id" {
  description = "VPC ID where the OpenSearch domain is deployed"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs where the OpenSearch domain is deployed"
  value       = var.subnet_ids
}
