#!/bin/bash
# ============================================================
# Deploy Script - Chạy trên VPS bởi GitHub Actions
# Yêu cầu env:
#   DEPLOY_PATH   - đường dẫn thư mục deploy (vd: /opt/mattermost)
#   COMPOSE_FILE  - tên file docker-compose (vd: docker-compose.prod.yml)
#   MM_IMAGE      - image GHCR (vd: ghcr.io/cocojary/mattermost:latest)
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

log_info()    { echo -e "${CYAN}[$(date '+%H:%M:%S')] INFO ${NC} $1"; }
log_success() { echo -e "${GREEN}[$(date '+%H:%M:%S')] OK   ${NC} $1"; }
log_error()   { echo -e "${RED}[$(date '+%H:%M:%S')] ERR  ${NC} $1"; exit 1; }

DEPLOY_PATH="${DEPLOY_PATH:-/opt/mattermost}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
MM_IMAGE="${MM_IMAGE:-ghcr.io/cocojary/mattermost:latest}"
ENV_FILE="$DEPLOY_PATH/.env"
RELEASES_DIR="$DEPLOY_PATH/releases"

log_info "====== BẮT ĐẦU DEPLOY ======"
log_info "Image: $MM_IMAGE"

# ── Kiểm tra điều kiện ───────────────────────────────────────
[ -f "$ENV_FILE" ]   || log_error "Không tìm thấy $ENV_FILE!"
[ -f "$DEPLOY_PATH/$COMPOSE_FILE" ] || log_error "Không tìm thấy $DEPLOY_PATH/$COMPOSE_FILE!"

mkdir -p "$RELEASES_DIR"

# ── Lưu trạng thái hiện tại để rollback ──────────────────────
CURRENT_IMAGE=$(docker inspect --format='{{.Config.Image}}' mattermost-app 2>/dev/null || echo "none")
echo "$CURRENT_IMAGE" > "$RELEASES_DIR/last_image.txt"
log_info "Phiên bản hiện tại: $CURRENT_IMAGE"

# ── Pull image mới từ GHCR ────────────────────────────────────
log_info "Pull image mới: $MM_IMAGE"
docker pull "$MM_IMAGE" || log_error "Không thể pull image: $MM_IMAGE"
log_success "Pull image xong"

# ── Ghi image vào .env để docker compose dùng ────────────────
# Cập nhật hoặc thêm biến MM_IMAGE vào .env
if grep -q "^MM_IMAGE=" "$ENV_FILE"; then
  sed -i "s|^MM_IMAGE=.*|MM_IMAGE=${MM_IMAGE}|" "$ENV_FILE"
else
  echo "MM_IMAGE=${MM_IMAGE}" >> "$ENV_FILE"
fi

# ── Restart containers ────────────────────────────────────────
log_info "Khởi động lại containers..."
cd "$DEPLOY_PATH"
docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --force-recreate mattermost
sleep 5
docker compose -f "$COMPOSE_FILE" ps

# ── Ghi log ──────────────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cat >> "$RELEASES_DIR/deploy_history.log" << EOF
[$TIMESTAMP] DEPLOY OK | Image: $MM_IMAGE | Prev: $CURRENT_IMAGE
EOF

log_success "====== DEPLOY HOÀN TẤT ======"
