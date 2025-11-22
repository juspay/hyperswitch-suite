output "nacl_id" {
  description = "The ID of the network ACL"
  value       = aws_network_acl.main.id
}

output "nacl_arn" {
  description = "The ARN of the network ACL"
  value       = aws_network_acl.main.arn
}

output "nacl_owner_id" {
  description = "The ID of the AWS account that owns the network ACL"
  value       = aws_network_acl.main.owner_id
}
