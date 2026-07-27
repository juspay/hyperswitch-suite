output "fis_role_arn" {
  description = "ARN of the FIS IAM role"
  value       = aws_iam_role.fis_execution.arn
}

output "fis_role_name" {
  description = "Name of the FIS IAM role"
  value       = aws_iam_role.fis_execution.name
}

output "failover_experiment_id" {
  description = "ID of the Aurora failover experiment template"
  value       = length(aws_fis_experiment_template.aurora_failover) > 0 ? aws_fis_experiment_template.aurora_failover[0].id : null
}

output "reboot_experiment_id" {
  description = "ID of the RDS reboot experiment template"
  value       = length(aws_fis_experiment_template.rds_reboot) > 0 ? aws_fis_experiment_template.rds_reboot[0].id : null
}

output "combined_experiment_id" {
  description = "ID of the combined failover + wait + reboot experiment template"
  value       = length(aws_fis_experiment_template.combined_failover_reboot) > 0 ? aws_fis_experiment_template.combined_failover_reboot[0].id : null
}

output "network_disruption_experiment_id" {
  description = "ID of the network connectivity loss experiment template"
  value       = length(awscc_fis_experiment_template.network_disruption) > 0 ? awscc_fis_experiment_template.network_disruption[0].id : null
}

output "az_interruption_experiment_id" {
  description = "ID of the AZ power interruption experiment template"
  value       = length(awscc_fis_experiment_template.az_power_interruption) > 0 ? awscc_fis_experiment_template.az_power_interruption[0].id : null
}

output "stop_condition_alarm_arn" {
  description = "ARN of the CloudWatch alarm used as the stop condition"
  value       = aws_cloudwatch_metric_alarm.fis_stop_condition.arn
}

output "cpu_stress_experiment_id" {
  description = "ID of the CPU stress Lambda experiment template"
  value       = length(aws_fis_experiment_template.cpu_stress_lambda) > 0 ? aws_fis_experiment_template.cpu_stress_lambda[0].id : null
}

output "memory_stress_experiment_id" {
  description = "ID of the memory stress Lambda experiment template"
  value       = length(aws_fis_experiment_template.memory_stress_lambda) > 0 ? aws_fis_experiment_template.memory_stress_lambda[0].id : null
}

output "connection_exhaustion_experiment_id" {
  description = "ID of the connection exhaustion Lambda experiment template"
  value       = length(aws_fis_experiment_template.connection_exhaustion_lambda) > 0 ? aws_fis_experiment_template.connection_exhaustion_lambda[0].id : null
}

output "redis_cpu_stress_experiment_id" {
  description = "ID of the Redis CPU stress Lambda experiment template"
  value       = length(aws_fis_experiment_template.redis_cpu_stress_lambda) > 0 ? aws_fis_experiment_template.redis_cpu_stress_lambda[0].id : null
}

output "redis_memory_stress_experiment_id" {
  description = "ID of the Redis memory stress Lambda experiment template"
  value       = length(aws_fis_experiment_template.redis_memory_stress_lambda) > 0 ? aws_fis_experiment_template.redis_memory_stress_lambda[0].id : null
}

output "redis_connection_exhaustion_experiment_id" {
  description = "ID of the Redis connection exhaustion Lambda experiment template"
  value       = length(aws_fis_experiment_template.redis_connection_exhaustion_lambda) > 0 ? aws_fis_experiment_template.redis_connection_exhaustion_lambda[0].id : null
}

output "redis_failover_experiment_id" {
  description = "ID of the Redis replication group failover (standalone) experiment template"
  value       = length(aws_fis_experiment_template.redis_failover) > 0 ? aws_fis_experiment_template.redis_failover[0].id : null
}

output "redis_failover_under_stress_experiment_id" {
  description = "ID of the Redis failover under CPU stress experiment template"
  value       = length(aws_fis_experiment_template.redis_failover_under_stress) > 0 ? aws_fis_experiment_template.redis_failover_under_stress[0].id : null
}

output "network_latency_experiment_ids" {
  description = "Map of network latency injection experiment template IDs keyed by target (Service name or default)"
  value       = { for k, tmpl in aws_fis_experiment_template.network_latency : k => tmpl.id }
}

output "network_latency_simple_experiment_ids" {
  description = "Map of simple network latency (all traffic) experiment template IDs keyed by target (Service name or default)"
  value       = { for k, tmpl in aws_fis_experiment_template.network_latency_simple : k => tmpl.id }
}

output "ec2_termination_experiment_id" {
  description = "ID of the EC2 instance termination experiment template"
  value       = length(aws_fis_experiment_template.ec2_termination) > 0 ? aws_fis_experiment_template.ec2_termination[0].id : null
}
