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

cd "$PROJECT_DIR"
cat "$PROMPT" | claude --print
