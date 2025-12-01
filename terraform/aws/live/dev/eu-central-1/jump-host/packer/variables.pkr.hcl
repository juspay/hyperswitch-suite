# Packer Variables for Jump Host User Migration
# This file defines all variables used in the ami-migration.pkr.hcl template
# Actual values should be set in environment-specific .pkrvars.hcl files

variable "source_ami_id" {
  type        = string
  description = "AMI ID to use as base for migration (the new base AMI you want to use)"
}

variable "old_instance_id" {
  type        = string
  description = "Instance ID of the existing jump host to copy users from"
}

variable "region" {
  type        = string
  description = "AWS region where resources will be created"
  default     = "eu-central-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the Packer temporary instance will be launched"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet ID for the Packer temporary instance (must have internet access)"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the Packer temporary instance"
  default     = "t3.small"
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile name with SSM and EC2 permissions (leave empty to use default)"
  default     = ""
}

variable "ssh_username" {
  type        = string
  description = "SSH username for the source AMI (ubuntu for Ubuntu, ec2-user for Amazon Linux)"
  default     = "ubuntu"
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix for the resulting AMI name"
  default     = "jump-host-migrated"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod, sandbox, etc.)"
  default     = "dev"
}

variable "ssh_allowed_cidr" {
  type        = list(string)
  description = "CIDR blocks allowed to SSH to Packer temporary instance (e.g., [\"YOUR_IP/32\"])"
}
