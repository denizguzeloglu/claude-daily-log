#!/usr/bin/env bash
set -euo pipefail

TIME="${1:-18:03}"
LABEL="com.claude.dailylog"

if [[ ! "$TIME" =~ ^[0-9]{2}:[0-9]{2}$ ]]; then
  echo "Time must be HH:mm (got '$TIME')." >&2
  exit 1
fi

HOUR="${TIME%%:*}"
MIN="${TIME##*:}"
HOUR=$((10#$HOUR))
MIN=$((10#$MIN))

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RUN_SCRIPT="$PROJECT_DIR/scripts/run.sh"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST="$PLIST_DIR/$LABEL.plist"

if [ ! -f "$RUN_SCRIPT" ]; then
  echo "run.sh not found at $RUN_SCRIPT" >&2
  exit 1
fi

chmod +x "$RUN_SCRIPT"
mkdir -p "$PLIST_DIR"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>$RUN_SCRIPT</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key><integer>$HOUR</integer>
    <key>Minute</key><integer>$MIN</integer>
  </dict>
  <key>RunAtLoad</key><false/>
  <key>StandardOutPath</key><string>$PROJECT_DIR/log.out</string>
  <key>StandardErrorPath</key><string>$PROJECT_DIR/log.err</string>
</dict>
</plist>
EOF

launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

printf "LaunchAgent loaded: %s (daily at %02d:%02d local)\n" "$LABEL" "$HOUR" "$MIN"
echo "To test now:  launchctl start $LABEL"
echo "To remove:    launchctl unload '$PLIST' && rm '$PLIST'"
