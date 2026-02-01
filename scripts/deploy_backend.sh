#!/bin/bash
set -e

# === CONFIGURATION ===
PROJECT_DIR="/opt/dbaalld01_project/deploy-dba_alld_project"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.app.yml"
COMPOSE_PROJECT_NAME="dbaalld-app"

BACKEND_DIR="$PROJECT_DIR/backend"
BACKUP_DIR="$BACKEND_DIR/backup"

JAR_SOURCE="/home/dbaalld01/alld-0.0.1-SNAPSHOT.jar"
JAR_TARGET="$BACKEND_DIR/alld-0.0.1-SNAPSHOT.jar"

SERVICE_NAME="backend"
REVERSE_PROXY_SERVICE="reverse-proxy"

BACKUP_RETENTION_DAYS=30
LOG_DIR="$PROJECT_DIR/logs"
LOG_FILE="$LOG_DIR/deploy_backend_$(date +"%Y%m%d_%H%M%S").log"
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
  count=$(ls -1t deploy_backend_*.log 2>/dev/null | wc -l)
  if [ "$count" -gt "$MAX_LOG_FILES" ]; then
    ls -1t deploy_backend_*.log | tail -n +$((MAX_LOG_FILES+1)) | xargs -r gzip -f
    find "$LOG_DIR" -name "deploy_backend_*.log.gz" -mtime +90 -delete
  fi
}

dc() {
  docker compose -p "$COMPOSE_PROJECT_NAME" -f "$COMPOSE_FILE" "$@"
}

# === START DEPLOYMENT ===
log "------------------------------------------------------"
log "🚀 Starting backend deployment"

BACKUP_TS=$(date +"%Y%m%d_%H%M%S")
CURRENT_BACKUP="$BACKUP_DIR/$BACKUP_TS"
mkdir -p "$CURRENT_BACKUP"

# Step 1: Backup JAR
if [ -f "$JAR_TARGET" ]; then
  log "📦 Backing up existing JAR"
  cp "$JAR_TARGET" "$CURRENT_BACKUP/"
else
  log "⚠️ No existing JAR found"
fi

# Step 2: Copy new JAR
if [ ! -f "$JAR_SOURCE" ]; then
  log "❌ JAR not found: $JAR_SOURCE"
  exit 1
fi

log "📤 Deploying new JAR"
cp "$JAR_SOURCE" "$JAR_TARGET"

# Step 3: Build backend image
log "🧱 Building backend image"
dc build --no-cache backend >>"$LOG_FILE" 2>&1

# Step 4: Restart backend only
log "🔄 Restarting backend service"
dc up -d --no-deps backend >>"$LOG_FILE" 2>&1

# Step 5: Health / readiness check
log "⏳ Waiting for backend to be reachable"
sleep 10
if dc ps backend | grep -q "Up"; then
  log "✅ Backend container is running"
else
  log "⚠️ Backend status uncertain, check logs"
fi

# Step 6: Restart reverse proxy
log "🌐 Restarting reverse proxy"
dc restart "$REVERSE_PROXY_SERVICE" >>"$LOG_FILE" 2>&1 || \
  log "⚠️ Reverse proxy restart failed"

# Step 7: Cleanup old backups
log "🧹 Cleaning backups older than $BACKUP_RETENTION_DAYS days"
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \; 2>/dev/null || true

rotate_logs

log "✅ Backend deployment completed"
log "------------------------------------------------------"

