#!/bin/bash

# Script to export user accounts from source VM
# Run this script on the SOURCE VM as root
# Enhanced version for Packer AMI migration

set -euo pipefail  # Enhanced error handling

EXPORT_DIR="./user-export-$(date +%Y%m%d-%H%M%S)"
MIN_UID=1000  # Minimum UID to export (excludes system users)
MAX_UID=60000 # Maximum UID to export
LOG_FILE="/var/log/user-export.log"

# Users to exclude from export (already exist on new AMI)
EXCLUDE_USERS="ubuntu ssm-user"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== User Export Script Started ==="
log "Export directory: $EXPORT_DIR"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

# Create export directory
mkdir -p "$EXPORT_DIR" || { log "ERROR: Failed to create export directory"; exit 1; }

log "Exporting user account information..."
log "Excluding users: $EXCLUDE_USERS"

# Export user accounts (excluding system users and specified exclude list)
awk -F: -v min=$MIN_UID -v max=$MAX_UID -v exclude="$EXCLUDE_USERS" '
BEGIN {
    # Build exclude list
    split(exclude, exclude_array, " ")
    for (i in exclude_array) {
        exclude_map[exclude_array[i]] = 1
    }
}
($3 >= min && $3 <= max && !($1 in exclude_map)) {print}
' /etc/passwd > "$EXPORT_DIR/passwd.export"

if [ ! -s "$EXPORT_DIR/passwd.export" ]; then
    log "WARNING: No users found in UID range $MIN_UID-$MAX_UID after exclusions"
fi

# Export shadow passwords
awk -F: -v min=$MIN_UID -v max=$MAX_UID \
    'BEGIN {OFS=":"} NR==FNR {users[$1]; next} $1 in users {print}' \
    "$EXPORT_DIR/passwd.export" /etc/shadow > "$EXPORT_DIR/shadow.export" 2>/dev/null || \
    log "WARNING: Could not export shadow passwords (may need sudo)"

# Export group information
awk -F: -v min=$MIN_UID -v max=$MAX_UID \
    '($3 >= min && $3 <= max) {print}' /etc/group > "$EXPORT_DIR/group.export"

# Export gshadow (if exists)
if [ -f /etc/gshadow ]; then
    awk -F: -v min=$MIN_UID -v max=$MAX_UID \
        'BEGIN {OFS=":"} NR==FNR {groups[$1]; next} $1 in groups {print}' \
        "$EXPORT_DIR/group.export" /etc/gshadow > "$EXPORT_DIR/gshadow.export" 2>/dev/null || \
        log "WARNING: Could not export gshadow"
fi

# Get list of usernames
USERS=$(awk -F: '{print $1}' "$EXPORT_DIR/passwd.export")
USER_COUNT=$(echo "$USERS" | wc -w)

log "Found $USER_COUNT users to export"

# Export home directories
if [ "$USER_COUNT" -gt 0 ]; then
    log "Exporting home directories..."
    mkdir -p "$EXPORT_DIR/home"

    for user in $USERS; do
        homedir=$(grep "^$user:" /etc/passwd | cut -d: -f6)
        if [ -d "$homedir" ]; then
            log "  Backing up home directory for: $user ($homedir)"
            # Use tar to preserve permissions and ownership
            if tar -czf "$EXPORT_DIR/home/$user.tar.gz" -C / \
                --exclude='*.cache*' --exclude='*.tmp' --exclude='*/.cache/*' \
                "${homedir#/}" 2>>"$LOG_FILE"; then
                log "    Successfully backed up $user"
            else
                log "    WARNING: Some files could not be backed up for $user"
            fi
        else
            log "  WARNING: Home directory not found for $user: $homedir"
        fi
    done
fi

# Create metadata file
cat > "$EXPORT_DIR/export-info.txt" <<EOF
Export Date: $(date)
Source Hostname: $(hostname)
Source IP: $(hostname -I | awk '{print $1}')
Number of Users Exported: $USER_COUNT
UID Range: $MIN_UID - $MAX_UID

Exported Users:
$(awk -F: '{print $1 " (UID: " $3 ", GID: " $4 ")"}' "$EXPORT_DIR/passwd.export")
EOF

# Create tarball of everything
TARBALL="user-export-$(date +%Y%m%d-%H%M%S).tar.gz"
log "Creating final tarball: $TARBALL"

if tar -czf "$TARBALL" "$EXPORT_DIR" 2>>"$LOG_FILE"; then
    # Set permissions
    chmod 600 "$TARBALL"

    # Get tarball size
    TARBALL_SIZE=$(du -h "$TARBALL" | cut -f1)

    log ""
    log "=== Export Complete ==="
    log "Tarball created: $TARBALL (Size: $TARBALL_SIZE)"
    log "Tarball location: $(pwd)/$TARBALL"
    log "Users exported: $USER_COUNT"

    # Output tarball name for automation
    echo "$TARBALL"
else
    log "ERROR: Failed to create tarball"
    exit 1
fi
