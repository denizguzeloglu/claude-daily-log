#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="$PROJECT_DIR/config.json"
PROMPT="$PROJECT_DIR/prompt.md"

if [ ! -f "$CONFIG" ]; then
  echo "config.json not found at $CONFIG — copy config.example.json and edit it." >&2
  exit 1
fi

if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found on PATH." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found on PATH (used to parse config.json)." >&2
  exit 1
fi

# Parse config, expand ~, and emit each existing path on its own line
mapfile -t ADD_DIRS < <(CONFIG="$CONFIG" python3 - <<'PY'
import json, os, sys
cfg = json.load(open(os.environ["CONFIG"]))
paths = [cfg.get("vault_path"), cfg.get("transcript_root")] + list(cfg.get("project_dirs", []))
for p in paths:
    if not p:
        continue
    p = os.path.expanduser(p)
    if os.path.exists(p):
        print(p)
PY
)

ADD_ARGS=()
for d in "${ADD_DIRS[@]}"; do
  ADD_ARGS+=(--add-dir "$d")
done

cd "$PROJECT_DIR"
cat "$PROMPT" | claude --print --permission-mode acceptEdits "${ADD_ARGS[@]}"
