# =========================================================================
# SECURITY - SSH KEY PAIR
# =========================================================================

resource "tls_private_key" "kafka" {
  count     = var.create_key_pair && var.public_key == null ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kafka" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = local.key_pair_name
  public_key = var.public_key != null ? var.public_key : tls_private_key.kafka[0].public_key_openssh

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kafka_private_key" {
  count       = var.create_key_pair && var.public_key == null ? 1 : 0
  name        = "/${var.environment}/${var.project_name}/kafka/ssh-private-key"
  description = "Auto-generated SSH private key for Kafka instances"
  type        = "SecureString"
  value       = tls_private_key.kafka[0].private_key_pem

  tags = local.common_tags
}

# =========================================================================
# SECURITY - KAFKA SECURITY GROUPS
# =========================================================================

resource "aws_security_group" "broker" {
  name        = "${local.name_prefix}-broker-sg"
  description = "Security group for Kafka broker nodes"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

resource "aws_security_group" "controller" {
  name        = "${local.name_prefix}-controller-sg"
  description = "Security group for Kafka controller nodes"
  vpc_id      = var.vpc_id

  tags = local.common_tags
}

# =========================================================================
# SECURITY GROUP - INTRA-CLUSTER RULES (BROKER)
# =========================================================================

resource "aws_security_group_rule" "broker_self_ingress" {
  type              = "ingress"
  description       = "Allow all TCP traffic from itself"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.broker.id
  source_security_group_id = aws_security_group.broker.id
}

# =========================================================================
# SECURITY GROUP - INTRA-CLUSTER RULES (CONTROLLER)
# =========================================================================

resource "aws_security_group_rule" "controller_self_ingress" {
  type              = "ingress"
  description       = "Allow all TCP traffic from itself"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.controller.id
  source_security_group_id = aws_security_group.controller.id
}

# =========================================================================
# IAM - ROLE & INSTANCE PROFILE
# =========================================================================

resource "aws_iam_role" "kafka" {
  name        = "${local.name_prefix}-role"
  description = "IAM role for Kafka cluster instances"

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

resource "aws_iam_role_policy" "kafka_ec2" {
  name = "ec2-data-system-policy"
  role = aws_iam_role.kafka.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ec2:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "autoscaling:*"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = [
              "autoscaling.amazonaws.com",
              "ec2scheduled.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "kafka_sts" {
  name = "sts-assume-role"
  role = aws_iam_role.kafka.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "kafka" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.kafka.name

  tags = local.common_tags
}

# =========================================================================
# NETWORK - ELASTIC NETWORK INTERFACES (BROKERS)
# =========================================================================

resource "aws_network_interface" "broker" {
  count = var.broker_count

  subnet_id       = var.broker_subnet_id
  security_groups = [aws_security_group.broker.id]

  tags = merge(local.common_tags, {
    Name    = "kafka-broker-${count.index + 1}"
    cluster = "kafkabroker"
  })

  depends_on = [aws_security_group.broker]
}

# =========================================================================
# NETWORK - ELASTIC NETWORK INTERFACES (CONTROLLERS)
# =========================================================================

resource "aws_network_interface" "controller" {
  subnet_id       = var.controller_subnet_id
  security_groups = [aws_security_group.controller.id]

  tags = merge(local.common_tags, {
    Name    = "kafka-controller"
    cluster = "kafkacontroller"
  })

  depends_on = [aws_security_group.controller]
}

# =========================================================================
# COMPUTE - EC2 INSTANCES (BROKERS)
# =========================================================================

resource "aws_instance" "broker" {
  count = var.broker_count

  ami           = var.broker_ami_id
  instance_type = var.broker_instance_type
  key_name      = local.key_name

  network_interface {
    network_interface_id = aws_network_interface.broker[count.index].id
    device_index         = 0
  }

  iam_instance_profile = aws_iam_instance_profile.kafka.name
  user_data_base64     = base64encode(local.broker_user_data)
  monitoring           = true

  root_block_device {
    volume_size           = var.broker_root_volume_size
    volume_type           = var.broker_root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = var.broker_data_device_name
    volume_size           = var.broker_data_volume_size
    volume_type           = var.broker_data_volume_type
    encrypted             = true
    delete_on_termination = false
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, {
    Name    = "Kafka-Broker-${count.index + 1}"
    cluster = "kafkabroker"
  })

  depends_on = [
    aws_network_interface.broker,
    aws_iam_instance_profile.kafka,
    aws_security_group_rule.broker_self_ingress
  ]
}

# =========================================================================
# COMPUTE - EC2 INSTANCE (CONTROLLER - SINGLE)
# =========================================================================

resource "aws_instance" "controller" {
  ami           = var.controller_ami_id
  instance_type = var.controller_instance_type
  key_name      = local.key_name

  network_interface {
    network_interface_id = aws_network_interface.controller.id
    device_index         = 0
  }

  iam_instance_profile = aws_iam_instance_profile.kafka.name
  user_data_base64     = base64encode(local.controller_user_data)
  monitoring           = true

  root_block_device {
    volume_size           = var.controller_root_volume_size
    volume_type           = var.controller_root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = var.controller_metadata_device_name
    volume_size           = var.controller_metadata_volume_size
    volume_type           = var.controller_metadata_volume_type
    encrypted             = true
    delete_on_termination = false
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, {
    Name    = "Kafka-Controller"
    cluster = "kafkacontroller"
  })

  depends_on = [
    aws_network_interface.controller,
    aws_iam_instance_profile.kafka,
    aws_security_group_rule.controller_self_ingress
  ]
}
