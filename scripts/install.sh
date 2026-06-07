#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

"$ROOT_DIR/scripts/render-config.sh"

# musicbot 镜像固定用 UID 10001 运行；日志、队列和音频缓存目录必须给该用户写入。
if command -v chown >/dev/null 2>&1; then
  chown -R 10001:10001 "$ROOT_DIR/logs" "$ROOT_DIR/data" "$ROOT_DIR/cache" 2>/dev/null || true
fi

docker compose -f "$ROOT_DIR/docker-compose.yaml" up -d
docker compose -f "$ROOT_DIR/docker-compose.yaml" ps
