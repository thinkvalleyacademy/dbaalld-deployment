#!/bin/bash
set -e

# === CONFIGURATION ===
PROJECT_DIR="/opt/dbaalld01_project/deploy-dba_alld_project"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.app.yml"
COMPOSE_PROJECT_NAME="dbaalld-app"

FRONTEND_DIR="$PROJECT_DIR/frontend"
BACKUP_DIR="$FRONTEND_DIR/backup"

BUILD_SOURCE="/home/dbaalld01/build"
BUILD_TARGET="$FRONTEND_DIR/build"

SERVICE_NAME="frontend"
REVERSE_PROXY_SERVICE="reverse-proxy"

BACKUP_RETENTION_DAYS=30
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/deploy_frontend_$(date +"%Y%m%d_%H%M%S").log"
MAX_LOG_FILES=10

# === PREPARE DIRECTORIES ===
mkdir -p "$BACKUP_DIR" "$LOG_DIR"

# === FUNCTIONS ===
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

rotate_logs() {
  cd "$LOG_DIR" || return
  local count
  count=$(ls -1t deploy_frontend_*.log 2>/dev/null | wc -l)
  if [ "$count" -gt "$MAX_LOG_FILES" ]; then
    ls -1t deploy_frontend_*.log | tail -n +$((MAX_LOG_FILES+1)) | xargs -r gzip -f
    find "$LOG_DIR" -name "deploy_frontend_*.log.gz" -mtime +90 -delete
  fi
}

dc() {
  docker compose -p "$COMPOSE_PROJECT_NAME" -f "$COMPOSE_FILE" "$@"
}

# === START DEPLOYMENT ===
log "------------------------------------------------------"
log "🚀 Starting frontend deployment"

BACKUP_TS=$(date +"%Y%m%d_%H%M%S")
CURRENT_BACKUP="$BACKUP_DIR/$BACKUP_TS"
mkdir -p "$CURRENT_BACKUP"

# Step 1: Backup existing build
if [ -d "$BUILD_TARGET" ]; then
  log "📦 Backing up current build"
  cp -r "$BUILD_TARGET" "$CURRENT_BACKUP/"
else
  log "⚠️ No existing build found"
fi

# Step 2: Copy new build
if [ ! -d "$BUILD_SOURCE" ]; then
  log "❌ Build directory not found: $BUILD_SOURCE"
  exit 1
fi

log "📤 Deploying new frontend build"
rm -rf "$BUILD_TARGET"
cp -r "$BUILD_SOURCE" "$FRONTEND_DIR/"

# Step 3: Build frontend image
log "🧱 Building frontend image"
dc build --no-cache frontend >>"$LOG_FILE" 2>&1

# Step 4: Restart frontend
log "🔄 Restarting frontend service"
dc up -d frontend >>"$LOG_FILE" 2>&1

# Step 5: Restart reverse proxy
log "🌐 Restarting reverse proxy"
dc restart "$REVERSE_PROXY_SERVICE" >>"$LOG_FILE" 2>&1 || \
  log "⚠️ Reverse proxy restart failed"

# Step 6: Cleanup old backups
log "🧹 Cleaning backups older than $BACKUP_RETENTION_DAYS days"
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true

rotate_logs

log "✅ Frontend deployment completed"
log "------------------------------------------------------"

