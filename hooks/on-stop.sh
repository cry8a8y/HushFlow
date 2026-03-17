#!/bin/bash
# Hook: Called when Claude stops working

MARKER_FILE="/tmp/mindful-claude-working"
PANE_ID_FILE="/tmp/mindful-tmux-pane-id"
WINDOW_PID_FILE="/tmp/mindful-window-pid"
WINDOW_ID_FILE="/tmp/mindful-window-id"

# Remove marker file (triggers popup auto-close)
rm -f "$MARKER_FILE"

# Kill the breathing pane if it exists
if [ -f "$PANE_ID_FILE" ]; then
    pane_id=$(cat "$PANE_ID_FILE")
    tmux kill-pane -t "$pane_id" 2>/dev/null
    rm -f "$PANE_ID_FILE"
fi

# Stop the standalone window process if it exists.
if [ -f "$WINDOW_PID_FILE" ]; then
    window_pid=$(cat "$WINDOW_PID_FILE")
    kill "$window_pid" 2>/dev/null
    rm -f "$WINDOW_PID_FILE"
fi

if [ -f "$WINDOW_ID_FILE" ]; then
    window_id=$(cat "$WINDOW_ID_FILE")
    osascript >/dev/null 2>&1 <<EOF
tell application "Ghostty"
    try
        close window id "$window_id"
    end try
end tell
EOF
    rm -f "$WINDOW_ID_FILE"
fi
