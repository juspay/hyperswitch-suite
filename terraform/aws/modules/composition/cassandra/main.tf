# =========================================================================
# DATA SOURCES
# =========================================================================
data "aws_availability_zones" "available" {
  state = "available"
}

# =========================================================================
# SECURITY - SSH KEY PAIR
# =========================================================================
# Auto-generate SSH key pair if public_key not provided
resource "tls_private_key" "cassandra" {
  count     = var.create_key_pair && var.public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair (from provided or generated public key)
resource "aws_key_pair" "cassandra" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = local.key_pair_name
  public_key = var.public_key != null ? var.public_key : tls_private_key.cassandra[0].public_key_openssh

  tags = local.common_tags
}

# =========================================================================
# SECURITY - CASSANDRA SECURITY GROUP
# =========================================================================
resource "aws_security_group" "cassandra" {
  name        = "${local.name_prefix}-sg"
  description = "Security group for Cassandra cluster nodes"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

# =========================================================================
# SECURITY GROUP RULES - SELF (Intra-cluster communication)
# =========================================================================
resource "aws_security_group_rule" "cassandra_self_ingress" {
  type                     = "ingress"
  description              = "Allow all TCP traffic from itself"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cassandra.id
  source_security_group_id = aws_security_group.cassandra.id
}

resource "aws_security_group_rule" "cassandra_self_egress" {
  type                     = "egress"
  description              = "Allow all TCP traffic to itself"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cassandra.id
  source_security_group_id = aws_security_group.cassandra.id
}

# =========================================================================
# SECURITY GROUP RULES - VPC ENDPOINT (AWS API access)
# =========================================================================
resource "aws_security_group_rule" "cassandra_vpc_endpoint_egress" {
  count = var.vpc_endpoint_security_group_id != null ? 1 : 0

  type                     = "egress"
  description              = "HTTPS access to VPC endpoints"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cassandra.id
  source_security_group_id = var.vpc_endpoint_security_group_id
}

resource "aws_security_group_rule" "vpc_endpoint_cassandra_ingress" {
  count = var.vpc_endpoint_security_group_id != null ? 1 : 0

  type                     = "ingress"
  description              = "HTTPS access from Cassandra"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = var.vpc_endpoint_security_group_id
  source_security_group_id = aws_security_group.cassandra.id
}

# =========================================================================
# MONITORING - CLOUDWATCH LOGS (for EC2 instances)
# =========================================================================
resource "aws_cloudwatch_log_group" "cassandra" {
  name              = "/aws/ec2/cassandra/${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-logs"
    }
  )
}

# =========================================================================
# SEED DISCOVERY - LAMBDA FUNCTION (via base module)
# =========================================================================
module "seed_discovery_lambda" {
  source = "../../base/lambda"
  count  = local.create_seed_discovery ? 1 : 0

  function_name = "${local.name_prefix}-seed-discovery"
  description   = "Discovers Cassandra seed nodes by querying EC2 instance tags"
  runtime       = "nodejs20.x"
  handler       = "index.handler"
  timeout       = 30
  memory_size   = 128

  source_code_path = var.seed_discovery_lambda_source_path

  managed_policy_arns = []
  inline_policies = {
    ec2-operations = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:CreateNetworkInterface",
            "ec2:DeleteNetworkInterface",
            "ec2:TerminateInstances"
          ]
          Resource = "*"
        }
      ]
    })
  }

  environment_variables = {
    DEFAULT_TAG_NAME  = local.cluster_tag_name
    DEFAULT_TAG_VALUE = local.cluster_tag_value
  }

  log_retention_days = var.log_retention_days

  tags = local.common_tags
}

# =========================================================================
# SEED DISCOVERY - API GATEWAY (via base module)
# =========================================================================
module "seed_discovery_api" {
  source = "../../base/api-gateway"
  count  = local.create_seed_discovery ? 1 : 0

  name        = "${local.name_prefix}-seed-api"
  description = "API Gateway for Cassandra seed discovery"

  endpoint_type    = "PRIVATE"
  vpc_endpoint_ids = var.api_gateway_vpce_id != null ? [var.api_gateway_vpce_id] : []

  resources = [
    {
      path_part   = "CassandraSeedNode"
      parent_path = "/"
    }
  ]

  methods = [
    {
      resource_path    = "CassandraSeedNode"
      http_method      = "ANY"
      authorization    = "NONE"
      api_key_required = false
    }
  ]

  lambda_integrations = [
    {
      resource_path    = "CassandraSeedNode"
      http_method      = "ANY"
      lambda_arn       = module.seed_discovery_lambda[0].function_arn
      integration_type = "AWS_PROXY"
    }
  ]

  stage_name        = "default"
  stage_description = "Default stage for Cassandra seed discovery API"

  tags = local.common_tags
}

# =========================================================================
# IAM - ROLE & INSTANCE PROFILE
# =========================================================================
resource "aws_iam_role" "cassandra" {
  name        = "${local.name_prefix}-role"
  description = "IAM role for Cassandra cluster instances"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cassandra_ec2" {
  name = "cassandra-ec2-seed-node-policy"
  role = aws_iam_role.cassandra.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:TerminateInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "cassandra" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.cassandra.name

  tags = local.common_tags
}

# =========================================================================
# NETWORK - ELASTIC NETWORK INTERFACES (for stable IPs)
# =========================================================================
resource "aws_network_interface" "cassandra" {
  count = var.node_count

  subnet_id       = local.cassandra_subnet_id
  security_groups = [aws_security_group.cassandra.id]

  tags = merge(
    local.common_tags,
    {
      Name                 = "cassandra-node-${count.index + 1}"
      (local.eni_tag_name) = local.eni_tag_value
    }
  )

  depends_on = [aws_security_group.cassandra]
}

# =========================================================================
# COMPUTE - EC2 INSTANCES
# =========================================================================
resource "aws_instance" "cassandra" {
  count = var.node_count

  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = local.key_name

  network_interface {
    network_interface_id = aws_network_interface.cassandra[count.index].id
    device_index         = 0
  }

  iam_instance_profile = aws_iam_instance_profile.cassandra.name
  user_data            = base64encode(local.user_data_config)
  monitoring           = true

  # Additional EBS volume for Cassandra data
  ebs_block_device {
    device_name = var.ebs_device_name
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    encrypted   = true
  }

  # IMDSv2 configuration
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name                     = "cassandra-node-${count.index + 1}"
      (local.cluster_tag_name) = local.cluster_tag_value
    }
  )

  depends_on = [
    aws_network_interface.cassandra,
    aws_iam_instance_profile.cassandra,
    aws_security_group_rule.cassandra_self_ingress,
    aws_security_group_rule.cassandra_self_egress,
    aws_security_group_rule.cassandra_vpc_endpoint_egress,
    aws_security_group_rule.vpc_endpoint_cassandra_ingress,
    module.seed_discovery_api
  ]
}