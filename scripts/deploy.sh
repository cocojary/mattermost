#!/usr/bin/env bash
# ============================================================
# deploy.sh — Deploy Mattermost tu source (Git-based)
#
# Flow CI:
#   1. CI build webapp → SCP webapp-dist.tar.gz len /tmp/
#   2. VPS: git pull → giai nen webapp → docker compose build (Go only)
#
# Su dung:
#   bash scripts/deploy.sh
# ============================================================
set -euo pipefail

DEPLOY_PATH="${DEPLOY_PATH:-/opt/mattermost}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-master}"
COMPOSE_FILE="docker-compose.prod.yml"
WEBAPP_ARTIFACT="/tmp/webapp-dist.tar.gz"

log() { echo "[$(date +%H:%M:%S)] $1  $2"; }

cd "$DEPLOY_PATH" || exit 1

# -- 1. Luu trang thai hien tai
log "INFO" "Luu trang thai hien tai..."
PREV_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "none")
log "INFO" "Commit hien tai: $PREV_COMMIT"

# -- 2. Pull code moi nhat
log "INFO" "Pull code tu origin/$DEPLOY_BRANCH..."
git fetch origin "$DEPLOY_BRANCH"
git reset --hard "origin/$DEPLOY_BRANCH"

NEW_COMMIT=$(git rev-parse --short HEAD)
log "INFO" "Commit moi: $NEW_COMMIT"

# -- 3. Giai nen webapp pre-built tu CI
WEBAPP_DIST="$DEPLOY_PATH/webapp/channels/dist"
if [ -f "$WEBAPP_ARTIFACT" ]; then
    log "INFO" "Giai nen webapp pre-built tu CI..."
    rm -rf "$WEBAPP_DIST"
    mkdir -p "$WEBAPP_DIST"
    tar xzf "$WEBAPP_ARTIFACT" -C "$WEBAPP_DIST"
    rm -f "$WEBAPP_ARTIFACT"
    log "INFO" "Webapp giai nen thanh cong"
else
    log "WARN" "Khong tim thay $WEBAPP_ARTIFACT — dung webapp co san"
    if [ ! -d "$WEBAPP_DIST" ]; then
        log "ERROR" "Khong co webapp dist! Can chay CI build truoc."
        exit 1
    fi
fi

# -- Debug: kiem tra webapp dist
log "INFO" "Kiem tra webapp dist..."
if [ -d "$WEBAPP_DIST" ]; then
    FILE_COUNT=$(find "$WEBAPP_DIST" -type f 2>/dev/null | wc -l)
    log "INFO" "Webapp dist: $FILE_COUNT files"
else
    log "ERROR" "Webapp dist directory khong ton tai!"
    exit 1
fi

# -- 4. Build va deploy voi Docker Compose
log "INFO" "Build va deploy voi docker compose..."
docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans 2>&1

# -- 5. Health check: cho container khoi dong (max 5 phut)
MAX_WAIT=300
INTERVAL=10
ELAPSED=0

log "INFO" "Cho Mattermost khoi dong (max ${MAX_WAIT}s)..."
while [ $ELAPSED -lt $MAX_WAIT ]; do
    # Kiem tra container co dang chay khong
    CONTAINER_STATUS=$(docker compose -f "$COMPOSE_FILE" ps --format '{{.State}}' mattermost 2>/dev/null || echo "not_found")
    if [ "$CONTAINER_STATUS" = "not_found" ] || [ "$CONTAINER_STATUS" = "exited" ]; then
        log "WARN" "Container dang $CONTAINER_STATUS, cho them..."
    fi

    # Smoke test: curl health endpoint
    if curl -sf --max-time 5 http://localhost:8065/api/v4/system/ping 2>/dev/null | grep -q "OK"; then
        log "INFO" "=== Health check PASS! ==="
        break
    fi

    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
    log "INFO" "Doi... ${ELAPSED}s/${MAX_WAIT}s"
done

# -- 6. Kiem tra ket qua
if [ $ELAPSED -ge $MAX_WAIT ]; then
    log "ERROR" "=== Health check THAT BAI sau ${MAX_WAIT}s! ==="
    log "ERROR" "Container logs (last 50 lines):"
    docker compose -f "$COMPOSE_FILE" logs --tail=50 mattermost 2>&1 || true
    log "ERROR" "Tu dong rollback ve $PREV_COMMIT..."

    # Auto-rollback
    git fetch origin "$DEPLOY_BRANCH"
    git reset --hard "$PREV_COMMIT"
    docker compose -f "$COMPOSE_FILE" up -d --build --remove-orphans 2>&1 || true
    log "ERROR" "Rollback hoan tat. Can kiem tra thu cong!"
    exit 1
fi

docker compose -f "$COMPOSE_FILE" ps

# -- 7. Luu thong tin deploy
mkdir -p "$DEPLOY_PATH/releases"
echo "$PREV_COMMIT" > "$DEPLOY_PATH/releases/last_commit.txt"

# Ghi deploy history
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "[$TIMESTAMP] DEPLOY | $PREV_COMMIT -> $NEW_COMMIT | Branch: $DEPLOY_BRANCH" >> "$DEPLOY_PATH/releases/deploy_history.log"

log "INFO" "=== Deploy hoan tat ==="
log "INFO" "  Tu: $PREV_COMMIT -> $NEW_COMMIT"
log "INFO" "  Branch: $DEPLOY_BRANCH"
log "INFO" "  Rollback: bash scripts/rollback.sh"
