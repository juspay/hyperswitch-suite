# =========================================================================
# DATA SOURCES
# =========================================================================

data "aws_caller_identity" "current" {}

# =========================================================================
# SECURITY - SSH KEY PAIR
# =========================================================================

resource "tls_private_key" "clickhouse" {
  count     = var.create_key_pair && var.public_key == null ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "clickhouse" {
  count      = var.create_key_pair ? 1 : 0

  key_name   = local.key_pair_name
  public_key = var.public_key != null ? var.public_key : tls_private_key.clickhouse[0].public_key_openssh

  tags = local.common_tags
}

resource "aws_ssm_parameter" "clickhouse_private_key" {
  count       = var.create_key_pair && var.public_key == null ? 1 : 0

  name        = "/${var.environment}/${var.project_name}/clickhouse/ssh-private-key"
  description = "Auto-generated SSH private key for Clickhouse instances"
  type        = "SecureString"
  value       = tls_private_key.clickhouse[0].private_key_pem

  tags = local.common_tags
}

# =========================================================================
# SECURITY - CLICKHOUSE SECURITY GROUPS
# =========================================================================

resource "aws_security_group" "keeper" {
  name        = "${local.name_prefix}-keeper-sg"
  description = "Security group for Clickhouse keeper nodes"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-keeper-sg"
  })
}

resource "aws_security_group" "server" {
  name        = "${local.name_prefix}-server-sg"
  description = "Security group for Clickhouse server nodes"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-server-sg"
  })
}

# =========================================================================
# SECURITY GROUP - INTRA-CLUSTER RULES (KEEPER)
# =========================================================================

resource "aws_security_group_rule" "keeper_self_ingress" {
  type                     = "ingress"
  description              = "Allow all TCP traffic from itself"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.keeper.id
  source_security_group_id = aws_security_group.keeper.id
}

resource "aws_security_group_rule" "keeper_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.keeper.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# =========================================================================
# SECURITY GROUP - INTRA-CLUSTER RULES (SERVER)
# =========================================================================

resource "aws_security_group_rule" "server_self_ingress" {
  type                     = "ingress"
  description              = "Allow all TCP traffic from itself"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.server.id
  source_security_group_id = aws_security_group.server.id
}

resource "aws_security_group_rule" "server_egress" {
  type              = "egress"
  description       = "Allow all outbound traffic"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.server.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# =========================================================================
# IAM - ROLE & INSTANCE PROFILE
# =========================================================================

resource "aws_iam_role" "clickhouse" {
  name = "${local.name_prefix}-role"

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

resource "aws_iam_role_policy" "clickhouse_inline" {
  for_each = local.inline_policies

  name   = each.key
  role   = aws_iam_role.clickhouse.id
  policy = each.value
}

resource "aws_iam_role_policy_attachment" "clickhouse_managed" {
  for_each = toset(local.managed_policies)

  role       = aws_iam_role.clickhouse.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "clickhouse" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.clickhouse.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance-profile"
  })
}

# =========================================================================
# NETWORK - ELASTIC NETWORK INTERFACES (KEEPERS)
# =========================================================================

resource "aws_network_interface" "keeper" {
  count = var.keeper_count

  subnet_id       = var.keeper_subnet_id
  security_groups = [aws_security_group.keeper.id]

  tags = merge(local.common_tags, {
    Name    = "clickhouse-keeper-${count.index}"
    cluster = "clickhouse-keeper"
  })

  depends_on = [aws_security_group.keeper]
}

# =========================================================================
# NETWORK - ELASTIC NETWORK INTERFACES (SERVERS)
# =========================================================================

resource "aws_network_interface" "server" {
  count = var.server_count

  subnet_id       = var.server_subnet_id
  security_groups = [aws_security_group.server.id]

  tags = merge(local.common_tags, {
    Name    = "clickhouse-node-${count.index + 1}"
    cluster = "clickhouse-server"
  })

  depends_on = [aws_security_group.server]
}

# =========================================================================
# COMPUTE - EC2 INSTANCES (KEEPERS)
# =========================================================================

resource "aws_instance" "keeper" {
  count = var.keeper_count

  ami           = var.keeper_ami_id
  instance_type = var.keeper_instance_type
  key_name      = local.key_name

  network_interface {
    network_interface_id = aws_network_interface.keeper[count.index].id
    device_index         = 0
  }

  iam_instance_profile = aws_iam_instance_profile.clickhouse.name
  user_data_base64     = base64encode(local.keeper_user_data)
  monitoring           = true

  root_block_device {
    volume_size           = var.keeper_root_volume_size
    volume_type           = var.keeper_root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = var.keeper_data_device_name
    volume_size           = var.keeper_data_volume_size
    volume_type           = var.keeper_data_volume_type
    encrypted             = true
    delete_on_termination = false
  }

  ebs_block_device {
    device_name           = var.keeper_data2_device_name
    volume_size           = var.keeper_data2_volume_size
    volume_type           = var.keeper_data2_volume_type
    encrypted             = true
    delete_on_termination = false
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, {
    Name    = "Clickhouse-Keeper-${count.index}"
    cluster = "clickhouse-keeper"
  })

  depends_on = [
    aws_network_interface.keeper,
    aws_iam_instance_profile.clickhouse,
    aws_security_group_rule.keeper_self_ingress,
    aws_security_group_rule.keeper_egress
  ]
}

# =========================================================================
# COMPUTE - EC2 INSTANCES (SERVERS)
# =========================================================================

resource "aws_instance" "server" {
  count = var.server_count

  ami           = var.server_ami_id
  instance_type = var.server_instance_type
  key_name      = local.key_name

  network_interface {
    network_interface_id = aws_network_interface.server[count.index].id
    device_index         = 0
  }

  iam_instance_profile = aws_iam_instance_profile.clickhouse.name
  user_data_base64     = base64encode(local.server_user_data)
  monitoring           = true

  root_block_device {
    volume_size           = var.server_root_volume_size
    volume_type           = var.server_root_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  ebs_block_device {
    device_name           = var.server_data_device_name
    volume_size           = var.server_data_volume_size
    volume_type           = var.server_data_volume_type
    encrypted             = true
    delete_on_termination = false
  }

  ebs_block_device {
    device_name           = var.server_data2_device_name
    volume_size           = var.server_data2_volume_size
    volume_type           = var.server_data2_volume_type
    encrypted             = true
    delete_on_termination = false
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.common_tags, {
    Name    = "Clickhouse-Server-${count.index}"
    cluster = "clickhouse-server"
  })

  depends_on = [
    aws_network_interface.server,
    aws_iam_instance_profile.clickhouse,
    aws_security_group_rule.server_self_ingress,
    aws_security_group_rule.server_egress
  ]
}