#!/bin/bash
# Hook: Called when Claude stops working

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [on-stop] $*" >> /tmp/hushflow-debug.log; }

CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"

# Find session directory
SESSION_DIR=""
if [ -f "$CONFIG_DIR/.session" ]; then
    SESSION_DIR=$(cat "$CONFIG_DIR/.session" 2>/dev/null || true)
fi
if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
    hf_log "no session dir found, nothing to stop"
    exit 0
fi

# Remove marker file (triggers popup auto-close)
rm -f "$SESSION_DIR/working"
hf_log "marker removed from $SESSION_DIR"

# Kill the breathing pane if it exists
if [ -f "$SESSION_DIR/tmux-pane-id" ]; then
    pane_id=$(cat "$SESSION_DIR/tmux-pane-id")
    tmux kill-pane -t "$pane_id" 2>/dev/null
fi

# Stop the standalone window process if it exists
if [ -f "$SESSION_DIR/window-pid" ]; then
    window_pid=$(cat "$SESSION_DIR/window-pid")
    pid_comm=$(ps -p "$window_pid" -o comm= 2>/dev/null || true)
    if [[ "$pid_comm" == *bash* ]] || [[ "$pid_comm" == *breathe* ]] || [[ "$pid_comm" == *sleep* ]]; then
        kill "$window_pid" 2>/dev/null
        hf_log "killed PID $window_pid ($pid_comm)"
    else
        hf_log "skipped kill PID $window_pid (comm=$pid_comm, not a breathe process)"
    fi
fi

# Close window by ID (Ghostty AppleScript)
if [ -f "$SESSION_DIR/window-id" ]; then
    window_id=$(cat "$SESSION_DIR/window-id")
    if [ -d "/Applications/Ghostty.app" ]; then
        osascript >/dev/null 2>&1 <<EOF
tell application "Ghostty"
    try
        close window id "$window_id"
    end try
end tell
EOF
    fi
fi

# Clean up session directory
rm -rf "$SESSION_DIR"
rm -f "$CONFIG_DIR/.session"
