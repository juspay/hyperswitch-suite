# Jump Host AMI Migration with Packer

This directory contains Packer configuration to create AMIs with migrated users from existing jump host instances.

## Overview

The Packer setup automates the process of:
1. Launching a temporary EC2 instance from a new base AMI
2. Extracting users from an existing jump host via AWS SSM
3. Importing users, groups, and home directories to the new instance
4. Creating a new AMI with all migrated users

## Prerequisites

- **Packer** installed (v1.8.0+)
- **AWS CLI** configured with appropriate credentials
- **SSM Agent** running on the old jump host instance
- **IAM Permissions**: The instance profile needs SSM and S3 permissions (already configured)
- **Network Access**: Your public IP for SSH access to temporary Packer instance

## Files

```
packer/
├── ami-migration.pkr.hcl       # Main Packer template
├── variables.pkr.hcl            # Variable definitions
├── dev.auto.pkrvars.hcl        # Dev environment values (auto-loaded)
├── scripts/
│   ├── export-users.sh         # Export users from old instance
│   ├── import-users.sh         # Import users to new instance
│   └── migrate-via-ssm.sh      # SSM orchestration script
└── README.md                   # This file
```

**Note**: Files with `.auto.pkrvars.hcl` suffix are automatically loaded by Packer (similar to Terraform's `terraform.tfvars`), so you don't need to specify `-var-file` when running `packer build`.

## Quick Start

### 1. Get Your Public IP

```bash
curl -s ifconfig.me
```

### 2. Update Configuration

Edit `dev.auto.pkrvars.hcl` and configure:

```hcl
# Your new base AMI (e.g., latest Ubuntu 22.04)
source_ami_id = "ami-XXXXXXXXX"

# Instance ID of old jump host with users to migrate
old_instance_id = "i-XXXXXXXXX"

# Your public IP (from step 1)
ssh_allowed_cidr = ["YOUR_IP/32"]
```

### 3. Initialize Packer

```bash
packer init .
```

### 4. Validate Configuration

```bash
packer validate .
```

### 5. Build AMI (Debug Mode)

For first run, use debug mode to troubleshoot:

```bash
packer build -debug .
```

Debug mode pauses after each step - press Enter to continue.

### 6. Build AMI (Production)

Once validated, run without debug:

```bash
packer build .
```

## What Gets Migrated

### ✅ Included
- **Users**: All users with UID 1000-60000 (except `ubuntu`, `ssm-user`)
- **Groups**: All groups with GID 1000-60000
- **Passwords**: User password hashes
- **Home Directories**: `.ssh`, `.bashrc`, `.bash_history`, config files
- **Group Memberships**: Including `shared-ssh-users` group

### ❌ Excluded
- `ubuntu` user (already exists on new AMI)
- `ssm-user` user (AWS managed)
- Mail spools (not used)
- Cache directories (`.cache`, `*.tmp`)
- Large temporary files (`.tar`, `.deb`, `.sql` dumps)

## Output

After successful build:

```
Build 'jump-host-user-migration.amazon-ebs.jump_host_migration' finished.

==> Builds finished. The artifacts of successful builds are:
--> jump-host-user-migration.amazon-ebs.jump_host_migration: AMIs were created:
eu-central-1: ami-XXXXXXXXX
```

The AMI ID is also saved in `packer-manifest.json`.


## Migration Details

### User Export Process

1. Connects to old instance via SSM
2. Exports users matching UID 1000-60000 (excludes `ubuntu`, `ssm-user`)
3. Exports groups, passwords, home directories
4. Creates compressed tarball (~50MB after optimization)
5. Uploads to temporary S3 bucket

### User Import Process

1. Downloads tarball from S3
2. Creates users with same UIDs (or new UIDs if conflict)
3. Restores password hashes
4. Creates groups and memberships
5. Extracts home directories with correct ownership
6. Cleans up temporary files

### Estimated Time

- Export users: ~30 seconds
- Transfer via S3: ~10 seconds
- Import users: ~20 seconds
- AMI creation: ~5 minutes
- **Total**: ~6-7 minutes

## IAM Permissions Required

The instance profile needs:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:DescribeInstanceInformation",
        "ssm:SendCommand",
        "ssm:GetCommandInvocation",
        "ssm:ListCommandInvocations"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket",
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::packer-migration-temp-*",
        "arn:aws:s3:::packer-migration-temp-*/*"
      ]
    }
  ]
}
```

These permissions are already configured in the `external_jump_iam_role`.

## Security Considerations

- Temporary Packer instance is restricted to your IP only
- S3 bucket is created and deleted automatically during migration
- SSH private keys are never exposed
- Password hashes are transferred securely via SSM
- Temporary instance is terminated automatically after AMI creation

## Replicating for Other Environments

To use in staging/prod:

1. Copy `dev.auto.pkrvars.hcl` to `staging.auto.pkrvars.hcl` or `prod.auto.pkrvars.hcl`
2. Update values for target environment
3. Run: `packer build .` (auto-loads the `.auto.pkrvars.hcl` file)

**Alternative**: If you want to keep multiple environment files and explicitly choose which one to use, name them without `.auto` (e.g., `staging.pkrvars.hcl`) and run: `packer build -var-file="staging.pkrvars.hcl" .`

## Support

For issues or questions:
- Check Packer logs: `packer build -debug` shows detailed execution
- Review SSM command history in AWS Console
- Check `/var/log/user-export.log` and `/var/log/user-import.log` on instances
- Consult [Packer documentation](https://developer.hashicorp.com/packer/docs)
