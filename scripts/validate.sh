#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

python3 -m py_compile "$ROOT_DIR/patches/bot.py"
python3 -m json.tool "$ROOT_DIR/data/radio_aliases.example.json" >/dev/null
python3 -m json.tool "$ROOT_DIR/data/podcast_aliases.example.json" >/dev/null

if [ -f "$ROOT_DIR/data/radio_aliases.json" ]; then
  python3 -m json.tool "$ROOT_DIR/data/radio_aliases.json" >/dev/null
fi

if [ -f "$ROOT_DIR/data/podcast_aliases.json" ]; then
  python3 -m json.tool "$ROOT_DIR/data/podcast_aliases.json" >/dev/null
fi

docker compose -f "$ROOT_DIR/docker-compose.yaml" config >/dev/null
echo "Validation passed."
