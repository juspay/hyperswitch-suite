output "access_entry_arn" {
  description = "The ARN of the access entry"
  value       = aws_eks_access_entry.this.access_entry_arn
}

output "access_entry_id" {
  description = "The ID of the access entry"
  value       = aws_eks_access_entry.this.id
}

output "access_policy_associations" {
  description = "Map of access policy associations"
  value       = aws_eks_access_policy_association.this
}
