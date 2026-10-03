output "distribution_id" {
  description = "The identifier for the CloudFront distribution"
  value       = module.distribution.cloudfront_distribution_id
}

output "distribution_arn" {
  description = "The ARN for the CloudFront distribution"
  value       = module.distribution.cloudfront_distribution_arn
}

output "domain_name" {
  description = "The domain name corresponding to the CloudFront distribution"
  value       = module.distribution.cloudfront_distribution_domain_name
}

output "hosted_zone_id" {
  description = "The CloudFront Route 53 zone ID"
  value       = module.distribution.cloudfront_distribution_hosted_zone_id
}

output "status" {
  description = "The current status of the distribution"
  value       = module.distribution.cloudfront_distribution_status
}

output "etag" {
  description = "The current version of the distribution's information"
  value       = module.distribution.cloudfront_distribution_etag
}

output "oac_objects" {
  description = "Map of OAC name to full object (contains id, arn, etc)"
  value       = module.distribution.cloudfront_origin_access_controls
}
