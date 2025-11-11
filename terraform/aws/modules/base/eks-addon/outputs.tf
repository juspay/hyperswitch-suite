output "addon_id" {
  description = "The ID of the EKS addon"
  value       = aws_eks_addon.this.id
}

output "addon_arn" {
  description = "The ARN of the EKS addon"
  value       = aws_eks_addon.this.arn
}

output "addon_version" {
  description = "The version of the EKS addon"
  value       = aws_eks_addon.this.addon_version
}
