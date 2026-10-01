# ============================================================================
# Lambda Layer Module - Main
# Creates an AWS Lambda Layer for shared dependencies
# ============================================================================

resource "aws_lambda_layer_version" "layer" {
  layer_name          = var.layer_name
  description         = var.description
  filename            = var.zip_path
  source_code_hash    = var.source_hash != "" ? var.source_hash : filebase64sha256(var.zip_path)
  compatible_runtimes = var.compatible_runtimes
  license_info        = var.license_info
}
