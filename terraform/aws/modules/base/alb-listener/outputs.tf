output "listener_id" {
  description = "ID of the listener"
  value       = try(aws_lb_listener.this[0].id, "")
}

output "listener_arn" {
  description = "ARN of the listener"
  value       = try(aws_lb_listener.this[0].arn, "")
}

output "listener_port" {
  description = "Port of the listener"
  value       = try(aws_lb_listener.this[0].port, null)
}

output "listener_protocol" {
  description = "Protocol of the listener"
  value       = try(aws_lb_listener.this[0].protocol, "")
}
