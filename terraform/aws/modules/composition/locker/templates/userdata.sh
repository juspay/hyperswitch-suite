#!/bin/bash
set -euo pipefail

# Log function for consistent logging
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Directory structure - created by AMI
export LOCKER_ENV_DIR="/home/ubuntu/locker_env"
export NGINX_CONFIG_DIR="/home/ubuntu/local-proxy-main"

# Validate environment
log "Validating environment setup..."
if [ ! -d "$LOCKER_ENV_DIR" ]; then
  log "Error: locker_env directory not found. The AMI must include the correct directory structure."
  exit 1
fi

if [ ! -d "$NGINX_CONFIG_DIR" ]; then
  log "Error: local-proxy-main directory not found. The AMI must include the correct directory structure."
  exit 1
fi

# Verify Docker is pre-installed
log "Verifying Docker installation..."
if ! command -v docker &> /dev/null; then
  log "Error: docker is not installed. The AMI must include all required dependencies."
  exit 1
fi

# Identify environment files
primary_env=""
fallback_env=""

for f in $(ls -t $LOCKER_ENV_DIR/envfile-* | head -2); do
  if [[ "$(basename $f)" == "envfile-FALLBACK" ]]; then
    fallback_env="$f"
  elif [[ "$(basename $f)" == "envfile-"* && -z "$primary_env" ]]; then
    primary_env="$f"
  fi
done

if [ -z "$primary_env" ]; then
  log "Error: No primary envfile found in $LOCKER_ENV_DIR (must be named envfile-<version>)"
  exit 1
fi

if [ -z "$fallback_env" ]; then
  log "Warning: No fallback envfile found in $LOCKER_ENV_DIR (should be named envfile-FALLBACK)"
  # Continue without fallback
fi

# Verify environment files exist
log "Validating environment files..."

if [ ! -f "$primary_env" ]; then
  log "Error: Primary environment file missing: $primary_env"
  exit 1
fi

log "Using primary environment file: $(basename $primary_env)"

if [ -n "$fallback_env" ]; then
  if [ ! -f "$fallback_env" ]; then
    log "Warning: Fallback environment file missing: $fallback_env"
    fallback_env=""
  else
    log "Using fallback environment file: $(basename $fallback_env)"
  fi
fi

# Start the primary card vault container
log "Starting primary card vault container..."
primary_version="$(basename $primary_env | cut -d'-' -f2)"
container_name="locker-$primary_version"

docker run -d \
  --name "$container_name" \
  --env-file "$primary_env" \
  --net=host \
  "$DOCKER_IMAGE"

log "Primary container started: $container_name"

# Start fallback container if available
if [ -n "$fallback_env" ]; then
  fallback_version="$(basename $fallback_env | cut -d'-' -f2)"
  fallback_container="locker-$fallback_version"

  docker run -d \
    --name "$fallback_container" \
    --env-file "$fallback_env" \
    --net=host \
    "$DOCKER_IMAGE"

  log "Fallback container started: $fallback_container"
fi

# Verify containers are running
log "Verifying container status..."
primary_status=$(docker inspect -f '{{.State.Running}}' "$container_name")
if [ "$primary_status" != "true" ]; then
  log "Error: Primary container is not running"
  exit 1
fi

if [ -n "$fallback_container" ] && [ $(docker inspect -f '{{.State.Running}}' "$fallback_container") != "true" ]; then
  log "Warning: Fallback container is not running"
  # Continue with primary container only
fi

# Start Nginx container
log "Starting Nginx proxy..."
nginx_container="nginx-proxy"

docker run -d \
  --name "$nginx_container" \
  --net=host \
  -v "$NGINX_CONFIG_DIR":/etc/nginx/ \
  nginx

# Final health check
log "Performing final health check..."
if ! docker logs "$container_name" | grep -q "Starting server"; then
  log "Warning: Container may not be fully initialized"
fi

# Instructions for next steps
log ""
log "Deployment completed successfully!"
log "Next steps:"
log "1. Unlock custodians by running:"
log "   curl -X POST 'localhost:8085/custodian/key1' -H \"x-tenant-id: test\" -d '{\"key\": \"<your-key>\"}'"
log "   curl -X POST 'localhost:8085/custodian/key2' -H \"x-tenant-id: test\" -d '{\"key\": \"<your-key>\"}'"
log "   curl -X POST 'localhost:8085/custodian/decrypt' -H \"x-tenant-id: test\""
log "2. Verify setup with: docker logs $container_name"
log "3. Test health: curl localhost:8080/health"
log ""

# Keep container running
log "Waiting for container to be manually stopped..."
tail -f /dev/null