output "oidc_provider_arn" {
  description = "The ARN of the OIDC provider"
  value       = aws_iam_openid_connect_provider.this.arn
}

output "oidc_provider_url" {
  description = "The URL of the OIDC provider"
  value       = aws_iam_openid_connect_provider.this.url
}

output "oidc_provider_id" {
  description = "The ID of the OIDC provider"
  value       = aws_iam_openid_connect_provider.this.id
}
