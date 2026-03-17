#!/bin/bash
# Hook: Called when Claude starts working

MARKER_FILE="/tmp/mindful-claude-working"
PANE_ID_FILE="/tmp/mindful-tmux-pane-id"
WINDOW_PID_FILE="/tmp/mindful-window-pid"
WINDOW_ID_FILE="/tmp/mindful-window-id"
LOCKFILE="/tmp/mindful-ui.lock"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.claude/mindful/config"
UI_MODE="${MINDFUL_UI_MODE:-window}"

# Exit early if disabled
if [ -f "$CONFIG_FILE" ] && grep -q "^enabled=false" "$CONFIG_FILE"; then
    exit 0
fi

# Clean up any leftover pane from a previous run (e.g. if Stop hook didn't fire)
if [ -f "$PANE_ID_FILE" ]; then
    old_pane=$(cat "$PANE_ID_FILE")
    tmux kill-pane -t "$old_pane" 2>/dev/null
    rm -f "$PANE_ID_FILE"
fi

# Clean up any leftover standalone window process.
if [ -f "$WINDOW_PID_FILE" ]; then
    old_pid=$(cat "$WINDOW_PID_FILE")
    kill "$old_pid" 2>/dev/null
    rm -f "$WINDOW_PID_FILE"
fi

rm -f "$WINDOW_ID_FILE"

rmdir "$LOCKFILE" 2>/dev/null

# Create marker file with timestamp
echo "$(date +%s)" > "$MARKER_FILE"

# Launch UI in background.
case "$UI_MODE" in
    off)
        ;;
    tmux-pane|tmux-popup)
        if [ -n "$TMUX" ]; then
            MINDFUL_TMUX_UI="${UI_MODE#tmux-}" "$SCRIPT_DIR/open-tmux-popup.sh" &
        fi
        ;;
    *)
        "$SCRIPT_DIR/open-standalone-window.sh" &
        ;;
esac
