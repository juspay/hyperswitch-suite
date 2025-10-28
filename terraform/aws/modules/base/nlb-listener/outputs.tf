output "listener_id" {
  description = "ID of the listener"
  value       = aws_lb_listener.this.id
}

output "listener_arn" {
  description = "ARN of the listener"
  value       = aws_lb_listener.this.arn
}

output "listener_port" {
  description = "Port of the listener"
  value       = aws_lb_listener.this.port
}

output "listener_protocol" {
  description = "Protocol of the listener"
  value       = aws_lb_listener.this.protocol
}
