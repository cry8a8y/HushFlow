#!/bin/bash
# Hook: Called when Claude stops working

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [on-stop] $*" >> /tmp/hushflow-debug.log; }

CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"
CURRENT_USER="$(id -un 2>/dev/null || echo "${USER:-}")"

is_hushflow_window_process() {
    local comm="$1"
    case "$comm" in
        *bash*|*sh*|*zsh*|*sleep*|*ghostty*|*gnome-terminal*|*konsole*|*xfce4-terminal*|*xterm*|*wt.exe*|*WindowsTerminal*|*powershell*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

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
    pid_user=$(ps -p "$window_pid" -o user= 2>/dev/null | tr -d ' ' || true)
    pid_comm=$(ps -p "$window_pid" -o comm= 2>/dev/null | tr -d ' ' || true)
    if [ -z "$pid_comm" ]; then
        hf_log "window PID $window_pid already exited"
    elif [ -n "$CURRENT_USER" ] && [ -n "$pid_user" ] && [ "$pid_user" != "$CURRENT_USER" ]; then
        hf_log "skipped kill PID $window_pid (owner=$pid_user, current=$CURRENT_USER)"
    elif is_hushflow_window_process "$pid_comm"; then
        kill "$window_pid" 2>/dev/null || true
        for _ in 1 2 3 4 5; do
            kill -0 "$window_pid" 2>/dev/null || break
            sleep 0.1
        done
        if kill -0 "$window_pid" 2>/dev/null; then
            kill -9 "$window_pid" 2>/dev/null || true
            hf_log "force-killed PID $window_pid ($pid_comm)"
        else
            hf_log "killed PID $window_pid ($pid_comm)"
        fi
    else
        hf_log "skipped kill PID $window_pid (comm=$pid_comm, not a HushFlow window process)"
    fi
fi

# Close Ghostty window by ID
# The breathing script detects marker removal (~0.1s) and runs a 1.5s fade-out,
# then exits. Ghostty's wait_after_command=false auto-closes the window when the
# process exits. We wait 2s for that graceful path, then force-close as safety net.
if [ -f "$SESSION_DIR/window-id" ]; then
    window_id=$(cat "$SESSION_DIR/window-id")
    if [ -d "/Applications/Ghostty.app" ]; then
        sleep 2
        osascript >/dev/null 2>&1 <<EOF
tell application "Ghostty"
    try
        close window id "$window_id"
    end try
end tell
EOF
        hf_log "sent close to Ghostty window $window_id (safety net)"
    fi
fi

# Clean up session directory
rm -rf "$SESSION_DIR"
rm -f "$CONFIG_DIR/.session"
