# IAM Role for EKS Node Groups
# Created independently since node groups are managed outside the EKS module
resource "aws_iam_role" "node_group" {
  name = "${var.environment}-${var.project_name}-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

# Attach required AWS managed policies for EKS node groups
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# AWS X-Ray for distributed tracing
resource "aws_iam_role_policy_attachment" "node_group_AWSXrayFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayFullAccess"
  role       = aws_iam_role.node_group.name
}

# CloudWatch Agent for metrics and logs
resource "aws_iam_role_policy_attachment" "node_group_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group.name
}

# Custom policy for enhanced CloudWatch and EC2 observability
resource "aws_iam_policy" "node_group_observability" {
  name        = "${var.environment}-${var.project_name}-node-observability"
  description = "Enhanced observability permissions for EKS nodes"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsObservability"
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport",
          "logs:DescribeLogGroups",
          "logs:GetLogGroupFields",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults",
          "logs:GetLogEvents",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_observability" {
  policy_arn = aws_iam_policy.node_group_observability.arn
  role       = aws_iam_role.node_group.name
}

# Independent EKS Managed Node Group
resource "aws_eks_node_group" "custom_nodes" {
  for_each = var.node_groups

  cluster_name         = module.eks.cluster_name
  node_group_name_prefix = "${each.key}-"
  node_role_arn        = aws_iam_role.node_group.arn
  # Use per-node-group subnets if specified, otherwise use cluster subnets
  subnet_ids      = lookup(each.value, "subnet_ids", var.subnet_ids)

  scaling_config {
    desired_size = lookup(each.value, "desired_size", 2)
    max_size     = lookup(each.value, "max_size", 4)
    min_size     = lookup(each.value, "min_size", 1)
  }

  update_config {
    max_unavailable_percentage = lookup(each.value, "max_unavailable_percentage", 33)
  }

  # Use custom launch template if defined, otherwise use default shared template
  launch_template {
    id = lookup(each.value, "custom_launch_template_config", null) != null ? aws_launch_template.custom_node_group[each.key].id : aws_launch_template.eks_nodes.id
    version = "$Latest"
  }

  # Capacity type
  capacity_type = lookup(each.value, "capacity_type", "ON_DEMAND")

  # Labels and tags
  labels = lookup(each.value, "labels", {})
  
  tags = merge(var.tags, {
    Name = "${var.environment}-${var.project_name}-${each.key}"
  })

  # Ensure proper lifecycle
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [
      scaling_config[0].desired_size,
      launch_template[0].version
    ]
  }

  depends_on = [
    module.eks,
  ]
}
