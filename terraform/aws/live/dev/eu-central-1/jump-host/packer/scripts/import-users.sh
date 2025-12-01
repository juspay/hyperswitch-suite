#!/bin/bash

# Script to import user accounts to destination VM
# Run this script on the DESTINATION VM as root
# Enhanced version for Packer AMI migration

set -euo pipefail

LOG_FILE="/var/log/user-import.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# Check if tarball is provided
if [ $# -ne 1 ]; then
    echo "Usage: $0 <user-export-tarball.tar.gz>"
    exit 1
fi

TARBALL="$1"

# Check if tarball exists
if [ ! -f "$TARBALL" ]; then
    log "ERROR: Tarball not found: $TARBALL"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log "ERROR: This script must be run as root"
    exit 1
fi

log "=== User Import Script Started ==="
log "Importing from: $TARBALL"

# Extract tarball
TEMP_DIR=$(mktemp -d)
log "Extracting tarball to temporary directory: $TEMP_DIR"
tar -xzf "$TARBALL" -C "$TEMP_DIR" || { log "ERROR: Failed to extract tarball"; exit 1; }

# Find the export directory
EXPORT_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "user-export-*" | head -n 1)

if [ -z "$EXPORT_DIR" ] || [ ! -d "$EXPORT_DIR" ]; then
    log "ERROR: Could not find export directory in tarball"
    rm -rf "$TEMP_DIR"
    exit 1
fi

log "Found export directory: $EXPORT_DIR"

# Show export info
if [ -f "$EXPORT_DIR/export-info.txt" ]; then
    log "=== Export Information ==="
    cat "$EXPORT_DIR/export-info.txt" | tee -a "$LOG_FILE"
fi

# Backup existing files
BACKUP_DIR="/root/user-import-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
log "Creating backup of existing files in: $BACKUP_DIR"
cp /etc/passwd "$BACKUP_DIR/"
cp /etc/shadow "$BACKUP_DIR/"
cp /etc/group "$BACKUP_DIR/"
[ -f /etc/gshadow ] && cp /etc/gshadow "$BACKUP_DIR/"

# Import users
log "Importing user accounts..."
USERS_IMPORTED=0
USERS_SKIPPED=0

if [ -f "$EXPORT_DIR/passwd.export" ]; then
    while IFS=: read -r username password uid gid comment home shell; do
        # Check if user already exists
        if id "$username" &>/dev/null; then
            log "  WARNING: User $username already exists, skipping..."
            USERS_SKIPPED=$((USERS_SKIPPED + 1))
            continue
        fi

        # Check if UID is already in use
        if getent passwd "$uid" &>/dev/null; then
            log "  WARNING: UID $uid already in use, will assign new UID for $username"
            # Create user without specifying UID
            if useradd -M -d "$home" -s "$shell" -c "$comment" "$username" 2>>"$LOG_FILE"; then
                log "  Created user: $username (new UID assigned)"
                USERS_IMPORTED=$((USERS_IMPORTED + 1))
            else
                log "  ERROR: Failed to create user $username"
            fi
        else
            # Create user with specific UID
            if useradd -M -u "$uid" -d "$home" -s "$shell" -c "$comment" "$username" 2>>"$LOG_FILE"; then
                log "  Created user: $username (UID: $uid)"
                USERS_IMPORTED=$((USERS_IMPORTED + 1))
            else
                log "  ERROR: Failed to create user $username"
            fi
        fi
    done < "$EXPORT_DIR/passwd.export"
fi

log "Users imported: $USERS_IMPORTED, Skipped: $USERS_SKIPPED"

# Import passwords
log "Importing passwords..."
if [ -f "$EXPORT_DIR/shadow.export" ]; then
    while IFS=: read -r username password rest; do
        if id "$username" &>/dev/null; then
            # Use usermod to set the password hash
            if usermod -p "$password" "$username" 2>>"$LOG_FILE"; then
                log "  Set password for $username"
            else
                log "  WARNING: Could not set password for $username"
            fi
        fi
    done < "$EXPORT_DIR/shadow.export"
fi

# Import groups
log "Importing groups..."
GROUPS_IMPORTED=0
GROUPS_SKIPPED=0

if [ -f "$EXPORT_DIR/group.export" ]; then
    while IFS=: read -r groupname password gid members; do
        # Check if group already exists
        if getent group "$groupname" &>/dev/null; then
            log "  WARNING: Group $groupname already exists, skipping..."
            GROUPS_SKIPPED=$((GROUPS_SKIPPED + 1))
            continue
        fi

        # Check if GID is already in use
        if getent group "$gid" &>/dev/null; then
            log "  WARNING: GID $gid already in use, will assign new GID for $groupname"
            if groupadd "$groupname" 2>>"$LOG_FILE"; then
                log "  Created group: $groupname (new GID assigned)"
                GROUPS_IMPORTED=$((GROUPS_IMPORTED + 1))
            else
                log "  ERROR: Failed to create group $groupname"
            fi
        else
            if groupadd -g "$gid" "$groupname" 2>>"$LOG_FILE"; then
                log "  Created group: $groupname (GID: $gid)"
                GROUPS_IMPORTED=$((GROUPS_IMPORTED + 1))
            else
                log "  ERROR: Failed to create group $groupname"
            fi
        fi

        # Add members to group
        if [ -n "$members" ]; then
            IFS=',' read -ra MEMBER_ARRAY <<< "$members"
            for member in "${MEMBER_ARRAY[@]}"; do
                if id "$member" &>/dev/null; then
                    usermod -a -G "$groupname" "$member" 2>>"$LOG_FILE" && \
                        log "    Added $member to group $groupname"
                fi
            done
        fi
    done < "$EXPORT_DIR/group.export"
fi

log "Groups imported: $GROUPS_IMPORTED, Skipped: $GROUPS_SKIPPED"

# Restore home directories
log "Restoring home directories..."
HOMES_RESTORED=0

if [ -d "$EXPORT_DIR/home" ]; then
    for tarfile in "$EXPORT_DIR/home"/*.tar.gz; do
        if [ -f "$tarfile" ]; then
            username=$(basename "$tarfile" .tar.gz)
            if id "$username" &>/dev/null; then
                homedir=$(getent passwd "$username" | cut -d: -f6)
                log "  Restoring home directory for: $username -> $homedir"

                # Extract home directory
                if tar -xzf "$tarfile" -C / 2>>"$LOG_FILE"; then
                    # Fix ownership
                    uid=$(id -u "$username")
                    gid=$(id -g "$username")
                    if chown -R "$uid:$gid" "$homedir" 2>>"$LOG_FILE"; then
                        log "    Successfully restored home directory for $username"
                        HOMES_RESTORED=$((HOMES_RESTORED + 1))
                    else
                        log "    WARNING: Could not fix all ownerships for $username"
                    fi
                else
                    log "    WARNING: Could not restore home directory for $username"
                fi
            else
                log "  WARNING: User $username not found, skipping home directory restore"
            fi
        fi
    done
fi

log "Home directories restored: $HOMES_RESTORED"

# Cleanup
log "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

log ""
log "=== Import Complete ==="
log "Backup of original files saved to: $BACKUP_DIR"
log "Summary:"
log "  Users imported: $USERS_IMPORTED (Skipped: $USERS_SKIPPED)"
log "  Groups imported: $GROUPS_IMPORTED (Skipped: $GROUPS_SKIPPED)"
log "  Home directories restored: $HOMES_RESTORED"
log ""
log "IMPORTANT: Verify the imported users and test login functionality"

# Exit successfully if we processed users (imported or skipped)
TOTAL_USERS=$((USERS_IMPORTED + USERS_SKIPPED))
if [ "$TOTAL_USERS" -eq 0 ]; then
    log "WARNING: No users were found to import"
    exit 1
fi

exit 0
