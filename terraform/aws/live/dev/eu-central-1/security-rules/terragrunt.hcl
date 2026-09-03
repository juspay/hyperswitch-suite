include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "../../../../modules/composition/security-rules"
}

dependency "vpc" {
  config_path = "../vpc-network"

  mock_outputs = {
    eks_workers_subnet_cidr_blocks = ["10.0.32.0/21", "10.0.40.0/21", "10.0.48.0/21"]
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "locker" {
  config_path = "../locker"

  mock_outputs = {
    security_group_id     = "sg-XXXXXXXXXXXXXXXXX"
    alb_security_group_id = "sg-YYYYYYYYYYYYYYYYY"
    db_security_group_id  = "sg-ZZZZZZZZZZZZZZZZZ"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "squid_proxy" {
  config_path = "../squid-proxy"

  mock_outputs = {
    asg_security_group_id = "sg-XXXXXXXXXXXXXXXXX"
    nlb_security_group_id = "sg-YYYYYYYYYYYYYYYYY"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "envoy_proxy" {
  config_path = "../envoy-proxy"

  mock_outputs = {
    asg_security_group_id = "sg-XXXXXXXXXXXXXXXXX"
    lb_security_group_id  = "sg-YYYYYYYYYYYYYYYYY"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "jump_host" {
  config_path = "../jump-host"

  mock_outputs = {
    jump_security_group_id = "sg-XXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "cassandra" {
  config_path = "../cassandra"

  mock_outputs = {
    cassandra_security_group_id = "sg-XXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

dependency "database" {
  config_path = "../database"

  mock_outputs = {
    security_group_id = "sg-XXXXXXXXXXXXXXXXX"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

inputs = {
  ingress_rules = [
    {
      sg_id = dependency.locker.outputs.security_group_id
      rules = [
        {
          description = "SSH access from jump host"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
        },
      ]
    },
    {
      sg_id = dependency.locker.outputs.alb_security_group_id
      rules = [
        {
          description = "HTTPS access from jump host"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
        },
      ]
    },
    {
      sg_id = dependency.squid_proxy.outputs.asg_security_group_id
      rules = [
        {
          description = "Allow traffic from EKS worker subnets"
          from_port   = 3128
          to_port     = 3128
          protocol    = "tcp"
          cidr        = dependency.vpc.outputs.eks_workers_subnet_cidr_blocks
        },
      ]
    },
    {
      sg_id = dependency.envoy_proxy.outputs.asg_security_group_id
      rules = [
        {
          description = "Allow SSH from jumpbox"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
        },
      ]
    },
    {
      sg_id = dependency.envoy_proxy.outputs.lb_security_group_id
      rules = [
        {
          description = "Allow HTTP from anywhere (IPv4)"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
        {
          description = "Allow HTTPS from anywhere (IPv4)"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
      ]
    },
    {
      sg_id = dependency.cassandra.outputs.cassandra_security_group_id
      rules = [
        {
          description = "SSH access from jump host"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.jump_host.outputs.jump_security_group_id]
        },
      ]
    },
  ]

  egress_rules = [
    {
      sg_id = dependency.locker.outputs.security_group_id
      rules = [
        {
          description = "HTTPS access for ECR, S3, and AWS services"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
        {
          description = "HTTP access for package downloads"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
        {
          description = "PostgreSQL access to RDS database"
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          sg_id       = [dependency.database.outputs.security_group_id]
        },
      ]
    },
    {
      sg_id = dependency.squid_proxy.outputs.asg_security_group_id
      rules = [
        {
          description = "Allow HTTPS to internet"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
      ]
    },
    {
      sg_id = dependency.envoy_proxy.outputs.asg_security_group_id
      rules = [
        {
          description = "Allow DNS UDP"
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr        = ["0.0.0.0/0"]
        },
        {
          description = "Allow DNS TCP"
          from_port   = 53
          to_port     = 53
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
        {
          description = "Allow HTTPS to S3"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr        = ["0.0.0.0/0"]
        },
        {
          description = "Allow traffic to Istio Internal LB"
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr        = [include.root.locals.vpc_cidr]
        },
      ]
    },
    {
      sg_id = dependency.envoy_proxy.outputs.lb_security_group_id
      rules = [
        {
          description = "Allow traffic to backend service"
          from_port   = 5000
          to_port     = 5000
          protocol    = "tcp"
          cidr        = [include.root.locals.vpc_cidr]
        },
      ]
    },
    {
      sg_id = dependency.jump_host.outputs.jump_security_group_id
      rules = [
        {
          description = "SSH to locker instance"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.locker.outputs.security_group_id]
        },
        {
          description = "SSH to envoy instances"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.envoy_proxy.outputs.asg_security_group_id]
        },
        {
          description = "SSH to squid proxy"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.squid_proxy.outputs.asg_security_group_id]
        },
        {
          description = "SSH to cassandra cluster"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          sg_id       = [dependency.cassandra.outputs.cassandra_security_group_id]
        },
        {
          description = "Monitoring system access"
          from_port   = 1514
          to_port     = 1514
          protocol    = "tcp"
          cidr        = [include.root.locals.vpc_cidr]
        },
        {
          description = "Database access (PostgreSQL)"
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          sg_id       = [dependency.database.outputs.security_group_id]
        },
      ]
    },
  ]
}
