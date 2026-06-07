#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
ENV_FILE="$ROOT_DIR/.env"
TEMPLATE_FILE="$ROOT_DIR/config/config.toml.example"
OUTPUT_FILE="$ROOT_DIR/config/config.toml"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing .env. Copy .env.example to .env and fill Matrix values." >&2
  exit 1
fi

set -a
. "$ENV_FILE"
set +a

: "${MATRIX_HOMESERVER:?MATRIX_HOMESERVER is required}"
: "${MATRIX_USER_ID:?MATRIX_USER_ID is required}"
: "${MATRIX_ACCESS_TOKEN:?MATRIX_ACCESS_TOKEN is required}"
: "${MATRIX_ALLOWED_ROOM_ID:=}"

mkdir -p "$ROOT_DIR/config" "$ROOT_DIR/data" "$ROOT_DIR/logs" "$ROOT_DIR/cache"

# 配置模板只允许替换公开占位符；不要把真实 token 写进 Git 跟踪文件。
python3 - "$TEMPLATE_FILE" "$OUTPUT_FILE" <<'PY'
import os
import sys
from pathlib import Path

template_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])
text = template_path.read_text(encoding="utf-8")
for key in (
    "MATRIX_HOMESERVER",
    "MATRIX_USER_ID",
    "MATRIX_ACCESS_TOKEN",
    "MATRIX_ALLOWED_ROOM_ID",
):
    text = text.replace("${" + key + "}", os.environ.get(key, ""))
output_path.write_text(text, encoding="utf-8")
PY

if [ ! -f "$ROOT_DIR/data/radio_aliases.json" ]; then
  cp "$ROOT_DIR/data/radio_aliases.example.json" "$ROOT_DIR/data/radio_aliases.json"
fi

if [ ! -f "$ROOT_DIR/data/podcast_aliases.json" ]; then
  cp "$ROOT_DIR/data/podcast_aliases.example.json" "$ROOT_DIR/data/podcast_aliases.json"
fi

python3 -m json.tool "$ROOT_DIR/data/radio_aliases.json" >/dev/null
python3 -m json.tool "$ROOT_DIR/data/podcast_aliases.json" >/dev/null

echo "Rendered config/config.toml and prepared data/log/cache directories."
