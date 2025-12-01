# ==============================================================================
# Packer Variables for Dev Environment - Jump Host User Migration
# ==============================================================================
# Fill in these values before running Packer
# ==============================================================================

# REQUIRED: Specify the new base AMI you want to use
# This should be a newer Ubuntu/Amazon Linux AMI
source_ami_id = "ami-xxxxxxxxxxxxxxxxx" # TODO: Replace with your new base AMI ID

# REQUIRED: Specify the instance ID of the existing jump host
# Users will be migrated FROM this instance
old_instance_id = "i-xxxxxxxxxxxxxxxxx" # TODO: Replace with your old jump host instance ID

# AWS Region
region = "eu-central-1"

# VPC Configuration (from terraform.tfvars)
vpc_id    = "vpc-xxxxxxxxxxxxxxxxx"
subnet_id = "subnet-xxxxxxxxxxxxxxxxx" # Public subnet (must have internet access)

# Instance Configuration
instance_type = "t3.small" # Sufficient for migration task
ssh_username  = "ubuntu"   # or "ec2-user" for Amazon Linux

# IAM Instance Profile
# This instance profile needs permissions for SSM (AmazonSSMManagedInstanceCore)
# and basic EC2 operations. If you have a specific profile, set it here.
# Use the instance profile name (NOT the role name)
iam_instance_profile = "INSTANCE_PROFILE_NAME" # TODO: Replace with your instance profile name

# AMI Naming
ami_name_prefix = "jump-host-migrated"
environment     = "dev"

# Security Configuration
# REQUIRED: Specify your IP address to restrict SSH access to Packer temporary instance
# Get your IP: curl -s ifconfig.me
ssh_allowed_cidr = ["YOUR_IP/32"] # TODO: Replace with your public IP (e.g., ["203.0.113.50/32"])

# ==============================================================================
# Instructions:
# ==============================================================================
# 1. Get your public IP: curl -s ifconfig.me
# 2. Replace ssh_allowed_cidr with your IP address (e.g., ["203.0.113.50/32"])
# 3. Replace source_ami_id with your new base AMI
# 4. Replace old_instance_id with the instance ID containing users to migrate
# 5. Verify vpc_id and subnet_id are correct
# 6. Ensure old_instance_id has SSM agent running and is online
# 7. Run: packer build -debug -var-file="dev.pkrvars.hcl" ami-migration.pkr.hcl
# ==============================================================================
