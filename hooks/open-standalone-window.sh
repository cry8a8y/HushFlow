#!/bin/bash
# Delayed standalone window launcher for breathing exercises.
# Opens a small Ghostty window and lets the animation process close it by exit.

set -euo pipefail

MARKER_FILE="/tmp/mindful-claude-working"
LOCKFILE="/tmp/mindful-ui.lock"
WINDOW_PID_FILE="/tmp/mindful-window-pid"
WINDOW_ID_FILE="/tmp/mindful-window-id"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREATHE_SCRIPT="$SCRIPT_DIR/breathe-compact.sh"
CONFIG_FILE="$HOME/.claude/mindful/config"
GHOSTTY_APP="/Applications/Ghostty.app"
WINDOW_TITLE="HushFlow"

config_delay=""
if [ -f "$CONFIG_FILE" ]; then
    config_delay=$(grep "^delay=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
fi

MINDFUL_DELAY_SECONDS="${MINDFUL_DELAY_SECONDS:-${config_delay:-5}}"

if [ ! -d "$GHOSTTY_APP" ]; then
    exit 0
fi

sleep "$MINDFUL_DELAY_SECONDS"

if [ ! -f "$MARKER_FILE" ]; then
    exit 0
fi

if ! mkdir "$LOCKFILE" 2>/dev/null; then
    exit 0
fi

cleanup() {
    rmdir "$LOCKFILE" 2>/dev/null || true
}
trap cleanup EXIT

# Launch a new window in the existing Ghostty app instance.
window_id=$(
osascript <<EOF
tell application "Ghostty"
    set surfaceConfig to new surface configuration
    set command of surfaceConfig to "/bin/bash -lc 'exec \"$BREATHE_SCRIPT\"'"
    set font size of surfaceConfig to 11
    set wait after command of surfaceConfig to false
    set newWindow to new window with configuration surfaceConfig
    delay 0.1
    try
        set bounds of newWindow to {1260, 80, 1560, 290}
    end try
    return id of newWindow
end tell
EOF
)

if [ -n "$window_id" ]; then
    echo "$window_id" > "$WINDOW_ID_FILE"
fi
