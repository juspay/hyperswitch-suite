# ============================================================================
# LOCALS
# ============================================================================
locals {
  # IAM role name
  iam_role_name = var.iam_role_name != null ? var.iam_role_name : "${var.function_name}-role"

  # Determine if VPC configuration is needed
  vpc_config = var.vpc_id != null && length(var.subnet_ids) > 0 ? {
    subnet_ids         = var.subnet_ids
    security_group_ids = var.security_group_ids
  } : null

  # Source code handling
  use_inline_code = var.source_code_content != null
  use_file_code   = var.source_code_path != null && !local.use_inline_code
}

# ============================================================================
# CLOUDWATCH LOG GROUP
# ============================================================================
resource "aws_cloudwatch_log_group" "this" {
  count = var.create_log_group ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name = "/aws/lambda/${var.function_name}"
    }
  )
}

# ============================================================================
# IAM ROLE (if creating new role)
# ============================================================================
data "aws_iam_policy_document" "assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name                 = local.iam_role_name
  description          = var.iam_role_description
  assume_role_policy   = data.aws_iam_policy_document.assume_role[0].json
  path                 = "/"
  permissions_boundary = null

  tags = merge(
    var.tags,
    {
      Name = local.iam_role_name
    }
  )
}

# Attach basic execution role if creating new role
resource "aws_iam_role_policy_attachment" "basic_execution" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Attach VPC access role if VPC configuration is provided
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = var.create_iam_role && local.vpc_config != null ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Attach additional managed policies
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.create_iam_role ? toset(var.managed_policy_arns) : toset([])

  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# Create inline policies
resource "aws_iam_role_policy" "inline" {
  for_each = var.create_iam_role ? var.inline_policies : {}

  name   = each.key
  role   = aws_iam_role.this[0].id
  policy = each.value
}

# ============================================================================
# SOURCE CODE ARCHIVE
# ============================================================================
data "archive_file" "this" {
  count = local.use_inline_code || local.use_file_code ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/lambda-${var.function_name}.zip"

  dynamic "source" {
    for_each = local.use_inline_code ? [1] : []
    content {
      content  = var.source_code_content
      filename = var.source_code_filename
    }
  }

  dynamic "source_dir" {
    for_each = local.use_file_code && fileexists(var.source_code_path) && !can(file(var.source_code_path)) ? [1] : []
    content {
      path = var.source_code_path
    }
  }

  # For single file source
  dynamic "source" {
    for_each = local.use_file_code && can(file(var.source_code_path)) ? [1] : []
    content {
      content  = file(var.source_code_path)
      filename = basename(var.source_code_path)
    }
  }
}

# ============================================================================
# LAMBDA FUNCTION
# ============================================================================
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  description   = var.description
  role          = var.create_iam_role ? aws_iam_role.this[0].arn : var.iam_role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Source code
  filename         = data.archive_file.this[0].output_path
  source_code_hash = data.archive_file.this[0].output_base64sha256

  # Environment variables
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # VPC configuration
  dynamic "vpc_config" {
    for_each = local.vpc_config != null ? [local.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.this,
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.vpc_access
  ]

  tags = merge(
    var.tags,
    {
      Name = var.function_name
    }
  )
}
