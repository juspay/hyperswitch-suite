# ============================================================================
# LOCALS
# ============================================================================
locals {
  # Build a map of path_part -> resource for easy lookup
  resource_map = {
    for r in var.resources : r.path_part => r
  }

  # Get region from provider
  region = data.aws_region.current.region
}

# ============================================================================
# DATA SOURCES
# ============================================================================
data "aws_region" "current" {}

# ============================================================================
# REST API
# ============================================================================
resource "aws_api_gateway_rest_api" "this" {
  name        = var.name
  description = var.description

  endpoint_configuration {
    types            = [var.endpoint_type]
    vpc_endpoint_ids = var.endpoint_type == "PRIVATE" ? var.vpc_endpoint_ids : null
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
    }
  )
}

# ============================================================================
# RESOURCES
# ============================================================================
resource "aws_api_gateway_resource" "this" {
  for_each = { for r in var.resources : r.path_part => r }

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part

  depends_on = [aws_api_gateway_rest_api.this]
}

# ============================================================================
# METHODS
# ============================================================================
resource "aws_api_gateway_method" "this" {
  for_each = { for i, m in var.methods : "${m.resource_path}-${m.http_method}" => m }

  rest_api_id      = aws_api_gateway_rest_api.this.id
  resource_id      = each.value.resource_path == "/" ? aws_api_gateway_rest_api.this.root_resource_id : aws_api_gateway_resource.this[each.value.resource_path].id
  http_method      = each.value.http_method
  authorization    = each.value.authorization
  authorizer_id    = each.value.authorizer_id
  api_key_required = each.value.api_key_required

  request_parameters = each.value.request_parameters
}

# ============================================================================
# LAMBDA INTEGRATIONS
# ============================================================================
resource "aws_api_gateway_integration" "lambda" {
  for_each = { for i, li in var.lambda_integrations : "${li.resource_path}-${li.http_method}" => li }

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_path == "/" ? aws_api_gateway_rest_api.this.root_resource_id : aws_api_gateway_resource.this[each.value.resource_path].id
  http_method = aws_api_gateway_method.this[each.key].http_method

  integration_http_method = "POST"
  type                    = each.value.integration_type
  uri                     = "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/${each.value.lambda_arn}/invocations"

  depends_on = [aws_api_gateway_method.this]
}

# ============================================================================
# METHOD RESPONSES (for Lambda proxy integration)
# ============================================================================
resource "aws_api_gateway_method_response" "this" {
  for_each = { for i, li in var.lambda_integrations : "${li.resource_path}-${li.http_method}" => li }

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_path == "/" ? aws_api_gateway_rest_api.this.root_resource_id : aws_api_gateway_resource.this[each.value.resource_path].id
  http_method = aws_api_gateway_method.this[each.key].http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_integration.lambda]
}

# ============================================================================
# INTEGRATION RESPONSES
# ============================================================================
resource "aws_api_gateway_integration_response" "this" {
  for_each = { for i, li in var.lambda_integrations : "${li.resource_path}-${li.http_method}" => li }

  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = each.value.resource_path == "/" ? aws_api_gateway_rest_api.this.root_resource_id : aws_api_gateway_resource.this[each.value.resource_path].id
  http_method = aws_api_gateway_method.this[each.key].http_method
  status_code = aws_api_gateway_method_response.this[each.key].status_code

  depends_on = [aws_api_gateway_integration.lambda]
}

# ============================================================================
# LAMBDA PERMISSIONS
# ============================================================================
resource "aws_lambda_permission" "api_gateway" {
  for_each = { for i, li in var.lambda_integrations : "${li.resource_path}-${li.http_method}" => li }

  statement_id  = "AllowAPIGatewayInvoke-${replace(each.key, "/", "-")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/${each.value.http_method}${each.value.resource_path == "/" ? "" : each.value.resource_path}"

  depends_on = [aws_api_gateway_rest_api.this]
}

# ============================================================================
# DEPLOYMENT
# ============================================================================
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      for r in aws_api_gateway_resource.this : r.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration_response.this
  ]
}

# ============================================================================
# STAGE
# ============================================================================
resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name
  description   = var.stage_description

  variables = var.stage_variables

  dynamic "access_log_settings" {
    for_each = var.access_log_destination_arn != null ? [1] : []
    content {
      destination_arn = var.access_log_destination_arn
      format          = var.access_log_format != null ? var.access_log_format : jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        routeKey       = "$context.routeKey"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
      })
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-${var.stage_name}"
    }
  )
}
