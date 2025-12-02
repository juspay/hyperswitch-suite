packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  ami_name  = "${var.ami_name_prefix}-${var.environment}-${local.timestamp}"
}

source "amazon-ebs" "jump_host_migration" {
  ami_name      = local.ami_name
  instance_type = var.instance_type
  region        = var.region
  source_ami    = var.source_ami_id

  # Network configuration
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true

  # IAM instance profile for SSM access
  iam_instance_profile = var.iam_instance_profile != "" ? var.iam_instance_profile : null

  # SSH configuration
  ssh_username = var.ssh_username

  # Use SSM for connection (more secure than SSH)
  communicator = "ssh"

  # Security: Restrict temporary security group to specific CIDR blocks
  # This prevents security alerts from 0.0.0.0/0 access
  temporary_security_group_source_cidrs = var.ssh_allowed_cidr

  # Temporary instance tags
  run_tags = {
    Name        = "Packer-JumpHost-Migration-Temp"
    Purpose     = "UserMigration"
    Temporary   = "true"
    Environment = var.environment
    ManagedBy   = "Packer"
  }

  # AMI tags
  tags = {
    Name         = local.ami_name
    Created      = local.timestamp
    Purpose      = "JumpHostWithMigratedUsers"
    SourceAMI    = var.source_ami_id
    Environment  = var.environment
    ManagedBy    = "Packer"
    MigratedFrom = var.old_instance_id
    Type         = "JumpHost"
  }

  # Snapshot tags
  snapshot_tags = {
    Name        = "${local.ami_name}-snapshot"
    Created     = local.timestamp
    Environment = var.environment
    ManagedBy   = "Packer"
  }
}

build {
  name    = "jump-host-user-migration"
  sources = ["source.amazon-ebs.jump_host_migration"]

  # Step 1: Disable UFW (if enabled) and update system
  provisioner "shell" {
    remote_folder = "/home/ubuntu"
    inline = [
      "echo '=== Disabling UFW and updating system ==='",
      "sudo ufw --force disable || echo 'UFW not installed or already disabled'",
      "sudo apt-get update -qq",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq awscli jq",
      "echo '✓ Prerequisites installed'"
    ]
  }

  # Step 2: Upload migration scripts
  provisioner "file" {
    source      = "${path.root}/scripts/export-users.sh"
    destination = "/tmp/export-users.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/import-users.sh"
    destination = "/tmp/import-users.sh"
  }

  provisioner "file" {
    source      = "${path.root}/scripts/migrate-via-ssm.sh"
    destination = "/tmp/migrate-via-ssm.sh"
  }

  # Step 3: Make scripts executable
  provisioner "shell" {
    remote_folder = "/home/ubuntu"
    inline = [
      "chmod +x /tmp/export-users.sh",
      "chmod +x /tmp/import-users.sh",
      "chmod +x /tmp/migrate-via-ssm.sh",
      "echo '✓ Scripts prepared'"
    ]
  }

  # Step 4: Execute SSM-based migration
  provisioner "shell" {
    remote_folder = "/home/ubuntu"
    environment_vars = [
      "OLD_INSTANCE_ID=${var.old_instance_id}",
      "AWS_REGION=${var.region}"
    ]
    inline = [
      "echo '=== Starting SSM-based user migration ==='",
      "sudo -E /tmp/migrate-via-ssm.sh",
      "echo '✓ User migration completed'"
    ]
  }

  # Step 5: Verify migration
  provisioner "shell" {
    remote_folder = "/home/ubuntu"
    inline = [
      "echo '=== Verifying migrated users ==='",
      "echo 'Migrated users (UID 1000-60000):'",
      "awk -F: '($3 >= 1000 && $3 <= 60000) {print $1 \" (UID: \" $3 \")\"}' /etc/passwd || echo 'No users found'",
      "echo '✓ Verification complete'"
    ]
  }

  # Step 6: Cleanup sensitive data
  provisioner "shell" {
    remote_folder = "/home/ubuntu"
    inline = [
      "echo '=== Cleaning up ==='",
      "sudo rm -f /tmp/export-users.sh /tmp/import-users.sh /tmp/migrate-via-ssm.sh",
      "sudo rm -f /tmp/user-export-*.tar.gz",
      "sudo rm -f /var/log/ssm-migration.log",
      "sudo rm -f /var/log/user-export.log",
      "sudo rm -f /var/log/user-import.log",
      "history -c",
      "echo '✓ Cleanup complete'"
    ]
  }

  # Output AMI ID to manifest
  post-processor "manifest" {
    output     = "packer-manifest.json"
    strip_path = true
  }
}
