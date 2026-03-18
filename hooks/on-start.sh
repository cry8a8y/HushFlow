#!/bin/bash
# Hook: Called when Claude starts working

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [on-start] $*" >> /tmp/hushflow-debug.log; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"
export HUSHFLOW_CONFIG_DIR="$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config"
UI_MODE="${HUSHFLOW_UI_MODE:-window}"

# Session-scoped temp directory (prevents multi-session / multi-user clashes)
SESSION_DIR="/tmp/hushflow-$$"
mkdir -p "$SESSION_DIR"
export HUSHFLOW_SESSION_DIR="$SESSION_DIR"

MARKER_FILE="$SESSION_DIR/working"
PANE_ID_FILE="$SESSION_DIR/tmux-pane-id"
WINDOW_PID_FILE="$SESSION_DIR/window-pid"
WINDOW_ID_FILE="$SESSION_DIR/window-id"
LOCKFILE="$SESSION_DIR/ui.lock"

# Exit early if disabled
if [ -f "$CONFIG_FILE" ] && grep -q "^enabled=false" "$CONFIG_FILE"; then
    exit 0
fi

# === Atomic session initialization (flock on Linux, mkdir lock fallback) ===
_hf_session_init() {
    # Clean up previous session (if Stop hook didn't fire)
    OLD_SESSION_DIR=""
    if [ -f "$CONFIG_DIR/.session" ]; then
        OLD_SESSION_DIR=$(cat "$CONFIG_DIR/.session" 2>/dev/null || true)
    fi
    if [ -n "$OLD_SESSION_DIR" ] && [ -d "$OLD_SESSION_DIR" ]; then
        old_pid=$(cat "$OLD_SESSION_DIR/window-pid" 2>/dev/null || true)
        if [ -n "$old_pid" ]; then
            pid_comm=$(ps -p "$old_pid" -o comm= 2>/dev/null || true)
            if [[ "$pid_comm" == *bash* ]] || [[ "$pid_comm" == *breathe* ]] || [[ "$pid_comm" == *sleep* ]]; then
                kill "$old_pid" 2>/dev/null
                hf_log "cleaned up stale PID $old_pid ($pid_comm)"
            fi
        fi
        old_pane=$(cat "$OLD_SESSION_DIR/tmux-pane-id" 2>/dev/null || true)
        if [ -n "$old_pane" ]; then
            tmux kill-pane -t "$old_pane" 2>/dev/null
        fi
        rm -rf "$OLD_SESSION_DIR"
    fi

    # Write session dir for on-stop.sh to find
    echo "$SESSION_DIR" > "$CONFIG_DIR/.session"

    # Create marker file with timestamp
    echo "$(date +%s)" > "$MARKER_FILE"
    hf_log "marker created at $SESSION_DIR, UI_MODE=$UI_MODE"

    # Launch UI synchronously — the hook itself is async, so this won't block
    # the AI tool. Running in foreground keeps the process alive until the
    # window is fully opened (osascript needs 1-2s on macOS).
    case "$UI_MODE" in
        off)
            ;;
        *)
            HUSHFLOW_UI_MODE="$UI_MODE" "$SCRIPT_DIR/open-window.sh"
            ;;
    esac
}

# Use flock if available (Linux), otherwise run directly (macOS mkdir lock in open-window.sh)
_HF_LOCKFILE="/tmp/hushflow-init.lock"
if command -v flock &>/dev/null; then
    (
        flock -n 200 || { hf_log "another session init in progress, skipping"; exit 0; }
        _hf_session_init
    ) 200>"$_HF_LOCKFILE"
else
    _hf_session_init
fi
