#!/bin/bash
# Hook: Called when Claude stops working

_HF_HOOK_NAME="on-stop"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/hook-common.sh"

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
_hf_load_session || { hf_log "nothing to stop"; exit 0; }

# Capture working marker timestamp before removing (for notification duration calc)
_hf_start_ts=""
if [ -f "$SESSION_DIR/working" ]; then
    _hf_start_ts=$(cat "$SESSION_DIR/working" 2>/dev/null)
fi

# Remove marker file (triggers popup auto-close), permission timestamp, and fast-path flag
rm -f "$SESSION_DIR/working" "$SESSION_DIR/permission-ts"
rm -f "$CONFIG_DIR/.permission-pending"
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
# then exits. Close immediately to prevent "Process exited" prompt.
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
        hf_log "sent close to Ghostty window $window_id (safety net)"
    fi
fi

# macOS notification: show session summary (calculated from marker timestamp + config)
if [[ "${OSTYPE:-}" == darwin* ]] && [[ "${_hf_start_ts:-}" =~ ^[0-9]+$ ]]; then
    _hf_now=$(date +%s)
    _hf_dur=$((_hf_now - _hf_start_ts))
    if [ "$_hf_dur" -ge 5 ]; then
        # Format duration
        if [ "$_hf_dur" -ge 60 ]; then
            _hf_dur_fmt="$((_hf_dur / 60))m $((_hf_dur % 60))s"
        else
            _hf_dur_fmt="${_hf_dur}s"
        fi

        # Read exercise from config
        _hf_ex=0
        _hf_config="${CONFIG_DIR}/config"
        [ -f "$_hf_config" ] && _hf_ex=$(grep "^exercise=" "$_hf_config" 2>/dev/null | cut -d= -f2)
        case "${_hf_ex:-0}" in
            0) _hf_ex_name="Coherent Breathing"; _hf_cycle_len=11 ;;
            1) _hf_ex_name="Physiological Sigh"; _hf_cycle_len=10 ;;
            2) _hf_ex_name="Box Breathing";      _hf_cycle_len=16 ;;
            3) _hf_ex_name="4-7-8 Breathing";    _hf_cycle_len=19 ;;
            *) _hf_ex_name="Breathing";           _hf_cycle_len=11 ;;
        esac

        # Estimate cycles (subtract delay before window appeared)
        _hf_delay=5
        [ -f "$_hf_config" ] && _hf_delay=$(grep "^delay=" "$_hf_config" 2>/dev/null | cut -d= -f2)
        _hf_breathe_dur=$((_hf_dur - ${_hf_delay:-5}))
        [ "$_hf_breathe_dur" -lt 0 ] && _hf_breathe_dur=0
        _hf_cycles=$((_hf_breathe_dur / _hf_cycle_len))

        # Build notification
        _hf_subtitle="${_hf_ex_name}"
        if [ "$_hf_cycles" -gt 0 ]; then
            _hf_body="${_hf_cycles} cycles · ${_hf_dur_fmt}"
        else
            _hf_body="${_hf_dur_fmt}"
        fi

        osascript -e "display notification \"${_hf_body}\" with title \"HushFlow\" subtitle \"${_hf_subtitle}\"" &>/dev/null &
    fi
fi

# Clean up session directory
rm -rf "$SESSION_DIR"
rm -f "$CONFIG_DIR/.session"
