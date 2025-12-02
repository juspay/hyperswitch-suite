#!/bin/bash

# SSM-based User Migration Orchestration Script
# This script runs on the Packer temporary instance and orchestrates
# the migration of users from the old jump host using SSM Session Manager

set -euo pipefail

LOG_FILE="/var/log/ssm-migration.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check for required environment variables
if [ -z "${OLD_INSTANCE_ID:-}" ]; then
    log "ERROR: OLD_INSTANCE_ID environment variable is required"
    exit 1
fi

if [ -z "${AWS_REGION:-}" ]; then
    log "ERROR: AWS_REGION environment variable is required"
    exit 1
fi

log "=== SSM-Based User Migration Started ==="
log "Old Instance ID: $OLD_INSTANCE_ID"
log "AWS Region: $AWS_REGION"

# Ensure scripts are in place
if [ ! -f "/home/ubuntu/export-users.sh" ] || [ ! -f "/home/ubuntu/import-users.sh" ]; then
    log "ERROR: Export/Import scripts not found in /home/ubuntu/"
    exit 1
fi

# Step 1: Check if old instance is accessible via SSM
log "Step 1: Checking SSM connectivity to old instance..."
if ! aws ssm describe-instance-information \
    --region "$AWS_REGION" \
    --filters "Key=InstanceIds,Values=$OLD_INSTANCE_ID" \
    --query 'InstanceInformationList[0].PingStatus' \
    --output text 2>>"$LOG_FILE" | grep -q "Online"; then
    log "ERROR: Old instance $OLD_INSTANCE_ID is not online in SSM"
    log "Please ensure the instance has SSM agent running and proper IAM role"
    exit 1
fi
log "✓ Old instance is online and accessible via SSM"

# Step 2: Disable UFW on old instance (if exists)
log "Step 2: Disabling UFW on old instance (if enabled)..."
aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$OLD_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo ufw disable 2>/dev/null || echo UFW not found or already disabled"]' \
    --output text >> "$LOG_FILE" 2>&1
sleep 2
log "✓ UFW disabled (if it was enabled)"

# Step 3: Transfer export script to old instance
log "Step 3: Transferring export script to old instance..."
EXPORT_SCRIPT_CONTENT=$(cat /home/ubuntu/export-users.sh | base64)

COMMAND_ID=$(aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$OLD_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"echo '$EXPORT_SCRIPT_CONTENT' | base64 -d > /tmp/export-users.sh\",\"chmod +x /tmp/export-users.sh\"]" \
    --query 'Command.CommandId' \
    --output text)

log "  Waiting for script transfer (Command ID: $COMMAND_ID)..."
aws ssm wait command-executed \
    --region "$AWS_REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$OLD_INSTANCE_ID" 2>>"$LOG_FILE" || {
    log "ERROR: Failed to transfer export script"
    exit 1
}
log "✓ Export script transferred successfully"

# Step 4: Execute export on old instance
log "Step 4: Executing user export on old instance..."
COMMAND_ID=$(aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$OLD_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["cd /tmp && sudo /tmp/export-users.sh"]' \
    --query 'Command.CommandId' \
    --output text)

log "  Waiting for export to complete (Command ID: $COMMAND_ID)..."
aws ssm wait command-executed \
    --region "$AWS_REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$OLD_INSTANCE_ID" 2>>"$LOG_FILE" || {
    log "ERROR: User export failed on old instance"
    exit 1
}

# Get the tarball name from command output
EXPORT_OUTPUT=$(aws ssm get-command-invocation \
    --region "$AWS_REGION" \
    --command-id "$COMMAND_ID" \
    --instance-id "$OLD_INSTANCE_ID" \
    --query 'StandardOutputContent' \
    --output text)

# Log the full output for debugging
log "Export command output:"
echo "$EXPORT_OUTPUT" | tee -a "$LOG_FILE"

# Extract tarball name - it should be on the last line and match pattern user-export-*.tar.gz
TARBALL_NAME=$(echo "$EXPORT_OUTPUT" | grep -oE 'user-export-[0-9]{8}-[0-9]{6}\.tar\.gz' | tail -1)

if [ -z "$TARBALL_NAME" ]; then
    log "ERROR: Could not determine tarball name from export output"
    log "Full output was:"
    echo "$EXPORT_OUTPUT" >> "$LOG_FILE"
    exit 1
fi

log "✓ Export completed. Tarball: $TARBALL_NAME"

# Step 5: Transfer tarball via S3 (SSM output limit is too small for large tarballs)
log "Step 5: Transferring user data tarball via S3..."

# Create a temporary S3 bucket name (using instance ID and timestamp for uniqueness)
S3_BUCKET="packer-migration-temp-$(echo $OLD_INSTANCE_ID | tr -d '-')-$(date +%s)"
S3_KEY="$TARBALL_NAME"

log "  Creating temporary S3 bucket: $S3_BUCKET"
aws s3 mb "s3://$S3_BUCKET" --region "$AWS_REGION" 2>>"$LOG_FILE" || {
    log "ERROR: Failed to create S3 bucket"
    exit 1
}

# Upload tarball from old instance to S3
log "  Uploading tarball from old instance to S3..."
UPLOAD_CMD_ID=$(aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$OLD_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"cd /tmp && aws s3 cp $TARBALL_NAME s3://$S3_BUCKET/$S3_KEY --region $AWS_REGION\"]" \
    --query 'Command.CommandId' \
    --output text)

aws ssm wait command-executed \
    --region "$AWS_REGION" \
    --command-id "$UPLOAD_CMD_ID" \
    --instance-id "$OLD_INSTANCE_ID" 2>>"$LOG_FILE" || {
    log "ERROR: Failed to upload tarball to S3"
    aws s3 rb "s3://$S3_BUCKET" --force --region "$AWS_REGION" 2>>"$LOG_FILE"
    exit 1
}

log "  Downloading tarball from S3 to current instance..."
aws s3 cp "s3://$S3_BUCKET/$S3_KEY" "/tmp/$TARBALL_NAME" --region "$AWS_REGION" 2>>"$LOG_FILE" || {
    log "ERROR: Failed to download tarball from S3"
    aws s3 rb "s3://$S3_BUCKET" --force --region "$AWS_REGION" 2>>"$LOG_FILE"
    exit 1
}

# Cleanup S3 bucket
log "  Cleaning up S3 bucket..."
aws s3 rb "s3://$S3_BUCKET" --force --region "$AWS_REGION" 2>>"$LOG_FILE"

if [ ! -f "/tmp/$TARBALL_NAME" ]; then
    log "ERROR: Failed to transfer tarball"
    exit 1
fi

TARBALL_SIZE=$(du -h "/tmp/$TARBALL_NAME" | cut -f1)
log "✓ Tarball transferred successfully (Size: $TARBALL_SIZE)"

# Step 6: Import users on current instance
log "Step 6: Importing users on current instance..."
if sudo /home/ubuntu/import-users.sh "/tmp/$TARBALL_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    log "✓ User import completed successfully"
else
    log "ERROR: User import failed"
    exit 1
fi

# Step 7: Cleanup on old instance
log "Step 7: Cleaning up old instance..."
aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$OLD_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters "commands=[\"cd /tmp && rm -f $TARBALL_NAME export-users.sh user-export-* && echo Cleanup complete\"]" \
    --output text >> "$LOG_FILE" 2>&1
log "✓ Cleanup completed on old instance"

# Step 8: Re-enable UFW on old instance (if it was disabled)
log "Step 8: Re-enabling UFW on old instance..."
aws ssm send-command \
    --region "$AWS_REGION" \
    --instance-ids "$OLD_INSTANCE_ID" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["sudo ufw --force enable 2>/dev/null || echo UFW not available"]' \
    --output text >> "$LOG_FILE" 2>&1
sleep 2
log "✓ UFW re-enabled (if applicable)"

# Cleanup on current instance
log "Cleaning up current instance..."
rm -f "/tmp/$TARBALL_NAME" /home/ubuntu/export-users.sh /home/ubuntu/import-users.sh
log "✓ Cleanup completed on current instance"

log ""
log "=== SSM-Based User Migration Completed Successfully ==="
log "Check /var/log/user-import.log for detailed import information"
