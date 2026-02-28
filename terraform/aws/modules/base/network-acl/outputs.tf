output "nacl_id" {
  description = "The ID of the network ACL"
  value       = try(aws_network_acl.main[0].id, "")
}

output "nacl_arn" {
  description = "The ARN of the network ACL"
  value       = try(aws_network_acl.main[0].arn, "")
}

output "nacl_owner_id" {
  description = "The ID of the AWS account that owns the network ACL"
  value       = try(aws_network_acl.main[0].owner_id, "")
}
