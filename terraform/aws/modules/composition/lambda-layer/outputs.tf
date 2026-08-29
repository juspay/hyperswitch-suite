# ============================================================================
# Lambda Layer Module - Outputs
# ============================================================================

output "layer_arn" {
  description = "ARN of the Lambda layer (with version)"
  value       = aws_lambda_layer_version.layer.arn
}

output "layer_version_arn" {
  description = "ARN of the Lambda layer version"
  value       = aws_lambda_layer_version.layer.layer_arn
}

output "layer_name" {
  description = "Name of the Lambda layer"
  value       = aws_lambda_layer_version.layer.layer_name
}

output "version" {
  description = "Version number of the Lambda layer"
  value       = aws_lambda_layer_version.layer.version
}

output "source_code_hash" {
  description = "Hash of the layer source code"
  value       = aws_lambda_layer_version.layer.source_code_hash
}
