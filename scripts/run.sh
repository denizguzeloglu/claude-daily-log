#!/usr/bin/env bash
set -euo pipefail

# launchd starts jobs with a minimal PATH, and a bash login shell does not pick up
# zsh-only PATH additions (e.g. ~/.local/bin, where the Claude CLI is installed).
# Prepend the common tool locations so claude/python3 resolve under the scheduler.
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"

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

# Parse config, expand ~, and emit each existing path on its own line.
# while-read loop (not mapfile) so this works on macOS's default bash 3.2.
ADD_ARGS=()
while IFS= read -r d; do
  [ -n "$d" ] && ADD_ARGS+=(--add-dir "$d")
done < <(CONFIG="$CONFIG" python3 - <<'PY'
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

cd "$PROJECT_DIR"

# A single transient API/network hiccup (e.g. "socket connection closed",
# "connection closed while thinking") would otherwise lose the whole day's log.
# Retry the run on failure. The task is idempotent — it skips when today's file
# already exists — so re-running after a partial/failed attempt is safe.
attempt=1
max_attempts=3
while true; do
  set +e
  cat "$PROMPT" | claude --print --permission-mode acceptEdits "${ADD_ARGS[@]}"
  status=$?
  set -e
  [ "$status" -eq 0 ] && break
  if [ "$attempt" -ge "$max_attempts" ]; then
    echo "claude run failed after $attempt attempts (last exit $status)." >&2
    exit "$status"
  fi
  echo "claude run failed (exit $status); retry $attempt/$max_attempts in 60s..." >&2
  attempt=$((attempt + 1))
  sleep 60
done
