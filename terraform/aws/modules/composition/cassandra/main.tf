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

# Store auto-generated private key in SSM Parameter Store
resource "aws_ssm_parameter" "cassandra_private_key" {
  count       = var.create_key_pair && var.public_key == null ? 1 : 0
  name        = "/${var.environment}/${var.project_name}/cassandra/ssh-private-key"
  description = "Auto-generated SSH private key for Cassandra instances"
  type        = "SecureString"
  value       = tls_private_key.cassandra[0].private_key_pem

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-private-key"
    }
  )
}

# =========================================================================
# SECURITY - CASSANDRA SECURITY GROUP (via base module)
# =========================================================================
module "cassandra_sg" {
  source = "../../base/security-group"

  name        = "${local.name_prefix}-sg"
  description = "Security group for Cassandra cluster nodes"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

# =========================================================================
# SECURITY GROUP - INTRA-CLUSTER RULES (via base module)
# =========================================================================
# Self-referencing rules for inter-node communication
# These are module-internal rules and belong here.
# Cross-module rules (e.g., EKS → Cassandra, jump-host → Cassandra)
# are managed in the security-rules live layer.
module "cassandra_intra_cluster_rules" {
  source = "../../base/security-group-rules"

  security_group_id = module.cassandra_sg.sg_id

  rules = [
    {
      type        = "ingress"
      description = "Allow all TCP traffic from itself"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      sg_id       = [module.cassandra_sg.sg_id]
    },
    {
      type        = "egress"
      description = "Allow all TCP traffic to itself"
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      sg_id       = [module.cassandra_sg.sg_id]
    }
  ]
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
    ec2-describe = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces"
          ]
          Resource = "*"
        }
      ]
    })
  }

  environment_variables = {
    DEFAULT_TAG_NAME  = local.cluster_tag_name
    DEFAULT_TAG_VALUE = local.cluster_tag_value
    MAX_SEEDS         = "5"
  }

  log_retention_days = var.log_retention_days

  tags = local.common_tags
}

# =========================================================================
# SEED DISCOVERY - API GATEWAY ACCESS LOGS
# =========================================================================
resource "aws_cloudwatch_log_group" "api_gateway_access" {
  count = local.create_seed_discovery ? 1 : 0

  name              = "/aws/apigateway/${local.name_prefix}-seed-api/access"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-api-access-logs"
    }
  )
}

# =========================================================================
# SEED DISCOVERY - API GATEWAY (via base module)
# =========================================================================
module "seed_discovery_api" {
  source = "../../base/api-gateway"
  count  = local.create_seed_discovery ? 1 : 0

  name        = "${local.name_prefix}-seed-api"
  description = "API Gateway for Cassandra seed discovery"

  endpoint_type      = "PRIVATE"
  vpc_endpoint_ids   = var.api_gateway_vpce_id != null ? [var.api_gateway_vpce_id] : []

  resources = [
    {
      path_part   = "CassandraSeedNode"
      parent_path = "/"
    }
  ]

  methods = [
    {
      resource_path    = "CassandraSeedNode"
      http_method      = "GET"
      authorization    = "NONE"
      api_key_required = false
    }
  ]

  lambda_integrations = [
    {
      resource_path    = "CassandraSeedNode"
      http_method      = "GET"
      lambda_arn       = module.seed_discovery_lambda[0].function_arn
      integration_type = "AWS_PROXY"
    }
  ]

  stage_name                 = "default"
  stage_description          = "Default stage for Cassandra seed discovery API"
  access_log_destination_arn = aws_cloudwatch_log_group.api_gateway_access[0].arn

  tags = local.common_tags
}

# =========================================================================
# IAM - ROLE & INSTANCE PROFILE (via base module)
# =========================================================================
module "cassandra_iam_role" {
  source = "../../base/iam-role"

  name                    = "${local.name_prefix}-role"
  description             = "IAM role for Cassandra cluster instances"
  service_identifiers     = ["ec2.amazonaws.com"]
  create_instance_profile = true

  # Managed policies
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ]

  # Inline policies
  inline_policies = {
    # EC2 seed node policy (logs + EC2 operations for seed discovery and node management)
    cassandra-ec2-seed-node-policy = jsonencode({
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

  tags = local.common_tags
}

# =========================================================================
# NETWORK - ELASTIC NETWORK INTERFACES (for stable IPs)
# =========================================================================
resource "aws_network_interface" "cassandra" {
  count = var.node_count

  subnet_id       = local.cassandra_subnet_id
  security_groups = [module.cassandra_sg.sg_id]

  tags = merge(
    local.common_tags,
    {
      Name                 = "cassandra-node-${count.index + 1}"
      (local.eni_tag_name) = local.eni_tag_value
    }
  )

  depends_on = [module.cassandra_sg]
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

  iam_instance_profile = module.cassandra_iam_role.instance_profile_name
  user_data            = base64encode(local.user_data_config)
  monitoring           = true

  # Additional EBS volume for Cassandra data
  ebs_block_device {
    device_name = var.ebs_device_name
    volume_size = var.ebs_volume_size
    volume_type = var.ebs_volume_type
    encrypted   = true
  }

  # IMDSv2 enforcement (security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
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
    module.cassandra_iam_role,
    module.cassandra_intra_cluster_rules,
    module.seed_discovery_api
  ]
}
