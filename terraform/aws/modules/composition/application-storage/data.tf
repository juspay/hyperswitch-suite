# Data sources for Aurora composition module

# Current AWS region
data "aws_region" "current" {}

# Current AWS caller identity (account ID)
data "aws_caller_identity" "current" {}

# VPC information for validation and reference
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Subnet information for validation
data "aws_subnets" "database" {
  filter {
    name   = "subnet-id"
    values = var.database_subnet_ids
  }
}

# Get subnet details for each database subnet
data "aws_subnet" "database" {
  for_each = toset(var.database_subnet_ids)
  id       = each.value
}

# Application security group information for validation
data "aws_security_group" "application" {
  id = var.application_security_group_id
}

# Get available Aurora PostgreSQL engine versions (for validation)
data "aws_rds_engine_versions" "postgresql" {
  engine         = "aurora-postgresql"
  preferred_versions = [var.engine_version]
}

# Default KMS key for RDS (if no custom key provided)
data "aws_kms_key" "rds_default" {
  count  = var.kms_key_id == null ? 1 : 0
  key_id = "alias/aws/rds"
}