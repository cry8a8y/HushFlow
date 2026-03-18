#!/bin/bash
# Delayed standalone window launcher for breathing exercises.
# Detects available terminal emulator and opens a small companion window.

set -euo pipefail

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [open-window] $*" >> /tmp/hushflow-debug.log || true; }

SESSION_DIR="${HUSHFLOW_SESSION_DIR:-/tmp/hushflow-$$}"
MARKER_FILE="$SESSION_DIR/working"
LOCKFILE="$SESSION_DIR/ui.lock"
WINDOW_PID_FILE="$SESSION_DIR/window-pid"
WINDOW_ID_FILE="$SESSION_DIR/window-id"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BREATHE_SCRIPT="$SCRIPT_DIR/breathe-compact.sh"
CONFIG_FILE="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}/config"
WINDOW_TITLE="HushFlow"
SESSION_NAME="$(basename "$SESSION_DIR")"
WINDOW_MATCH_TITLE="$WINDOW_TITLE · $SESSION_NAME"
# Env vars to pass to breathe-compact.sh in new terminal windows
BREATHE_ENV="export HUSHFLOW_SESSION_DIR='$SESSION_DIR' HUSHFLOW_CONFIG_DIR='${HUSHFLOW_CONFIG_DIR:-}' HUSHFLOW_WINDOW_TITLE='$WINDOW_MATCH_TITLE'"

# Source terminal detection
source "$SCRIPT_DIR/lib/detect-terminal.sh"

config_delay=""
if [ -f "$CONFIG_FILE" ]; then
    config_delay=$(grep "^delay=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
fi

HUSHFLOW_DELAY_SECONDS="${HUSHFLOW_DELAY_SECONDS:-${config_delay:-5}}"

# Validate delay is numeric
[[ "$HUSHFLOW_DELAY_SECONDS" =~ ^[0-9]+$ ]] || HUSHFLOW_DELAY_SECONDS=5

sleep "$HUSHFLOW_DELAY_SECONDS"

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

PANE_ID_FILE="$SESSION_DIR/tmux-pane-id"
HUSHFLOW_TMUX_UI="${HUSHFLOW_TMUX_UI:-pane}"

# tmux modes: handled inline before terminal detection
if [ "${HUSHFLOW_UI_MODE:-}" = "tmux-pane" ] || [ "${HUSHFLOW_UI_MODE:-}" = "tmux-popup" ]; then
    if [ -n "${TMUX:-}" ]; then
        hf_log "tmux mode=$HUSHFLOW_UI_MODE"
        if [ "${HUSHFLOW_UI_MODE:-}" = "tmux-popup" ]; then
            tmux display-popup -E -w 30 -h 15 -T "HushFlow" "$BREATHE_SCRIPT"
        else
            pane_id=$(tmux split-window -d -v -l 12 -P -F '#{pane_id}' "$BREATHE_SCRIPT")
            echo "$pane_id" > "$PANE_ID_FILE"
        fi
        exit 0
    fi
    hf_log "tmux requested but not in tmux session, falling through to window mode"
fi

terminal=$(detect_terminal)
hf_log "terminal=$terminal delay=$HUSHFLOW_DELAY_SECONDS"

case "$terminal" in
    ghostty)
        # macOS Ghostty — centered on same screen, does NOT steal focus.
        window_id=$(
        osascript <<EOF
-- Grid & font → pixel size (auto-adapt)
set termCols to 70
set termRows to 20
set fontSize to 16
-- Approximate cell metrics for monospace at given font size
set charW to fontSize * 0.6
set lineH to fontSize * 1.5
set winW to round (termCols * charW + 24)
set winH to round (termRows * lineH + 44)

tell application "System Events"
    tell process "Ghostty"
        set {wx, wy} to position of front window
        set {ww, wh} to size of front window
    end tell
end tell
set posX to wx + (ww - winW) / 2
set posY to wy + (wh - winH) / 2
if posX < 0 then set posX to 0
if posY < 25 then set posY to 25

tell application "Ghostty"
    set surfaceConfig to new surface configuration
    set breathePath to quoted form of POSIX path of "$BREATHE_SCRIPT"
    set command of surfaceConfig to "/bin/bash -lc " & quoted form of ("exec " & breathePath)
    set font size of surfaceConfig to fontSize
    set wait after command of surfaceConfig to "none"
    set environment variables of surfaceConfig to {"HUSHFLOW_SESSION_DIR=$SESSION_DIR", "HUSHFLOW_CONFIG_DIR=${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}", "HUSHFLOW_WINDOW_TITLE=$WINDOW_MATCH_TITLE", "HUSHFLOW_COLS=" & termCols, "HUSHFLOW_ROWS=" & termRows}
    set newWindow to new window with configuration surfaceConfig
    set winId to id of newWindow
end tell

-- Brief pause for window to register, then resize and raise the new window
delay 0.2
tell application "System Events"
    tell process "Ghostty"
        try
            set size of front window to {winW, winH}
            set position of front window to {posX, posY}
            -- Bring to front so it's visible above other Ghostty windows.
            -- The AI is working so the user isn't typing — no disruption.
            perform action "AXRaise" of front window
        end try
    end tell
end tell

return winId
EOF
        )
        if [ -n "$window_id" ]; then
            echo "$window_id" > "$WINDOW_ID_FILE"
            # Background monitor: auto-dismiss "Process exited" prompt.
            # Runs in Claude Code's shell (outside HushFlow terminal),
            # so it survives after the breathing process exits.
            (
                # Wait until HushFlow process exits (marker removed = close soon)
                while [ -f "$MARKER_FILE" ]; do sleep 1; done
                # Wait for fade-out + process exit + "Process exited" to render
                sleep 3
                # Send Return to dismiss prompt and close the window
                osascript <<'DISMISSEOF' &>/dev/null
tell application "System Events"
    tell process "Ghostty"
        try
            set w to first window whose name contains "HushFlow"
            perform action "AXRaise" of w
            delay 0.1
            keystroke return
        end try
    end tell
end tell
DISMISSEOF
            ) &>/dev/null &
        fi
        ;;

    terminal-app)
        # macOS Terminal.app — centered on same screen, respects other-app focus
        osascript <<EOF
set winW to 560
set winH to 480
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell
tell application "Terminal"
    set {wx, wy, wx2, wy2} to bounds of front window
    set posX to wx + ((wx2 - wx) - winW) / 2
    set posY to wy + ((wy2 - wy) - winH) / 2
    if posX < 0 then set posX to 0
    if posY < 25 then set posY to 25
    do script "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\""
    delay 0.2
    set bounds of front window to {posX, posY, posX + winW, posY + winH}
    set name of front window to "$WINDOW_TITLE"
end tell
try
    tell application frontApp to activate
end try
EOF
        ;;

    iterm)
        # macOS iTerm2 — centered on same screen, respects other-app focus
        osascript <<EOF
set winW to 560
set winH to 480
tell application "System Events"
    set frontApp to name of first application process whose frontmost is true
end tell
tell application "iTerm"
    set {wx, wy, wx2, wy2} to bounds of current window
    set posX to wx + ((wx2 - wx) - winW) / 2
    set posY to wy + ((wy2 - wy) - winH) / 2
    if posX < 0 then set posX to 0
    if posY < 25 then set posY to 25
    create window with default profile
    tell current session of current window
        write text "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\""
    end tell
    delay 0.2
    set bounds of current window to {posX, posY, posX + winW, posY + winH}
end tell
try
    tell application frontApp to activate
end try
EOF
        ;;

    gnome-terminal|konsole|xfce4-terminal|xterm)
        # Dynamic position: center relative to active window, fallback to +100+100
        _linux_geom="40x20+100+100"
        if command -v xdotool &>/dev/null; then
            _aw=$(xdotool getactivewindow 2>/dev/null) && \
            _ag=$(xdotool getwindowgeometry --shell "$_aw" 2>/dev/null) && \
            eval "$_ag" && \
            _px=$(( X + WIDTH / 2 - 200 )) && \
            _py=$(( Y + HEIGHT / 2 - 150 )) && \
            [ "$_px" -gt 0 ] 2>/dev/null && [ "$_py" -gt 0 ] 2>/dev/null && \
            _linux_geom="40x20+${_px}+${_py}"
            hf_log "linux geometry: $_linux_geom (from xdotool)"
        fi

        case "$TERMINAL" in
            gnome-terminal)
                gnome-terminal --title="$WINDOW_TITLE" --geometry="$_linux_geom" -- bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
                ;;
            konsole)
                konsole --geometry "$_linux_geom" -e bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
                ;;
            xfce4-terminal)
                xfce4-terminal --title="$WINDOW_TITLE" --geometry="$_linux_geom" -e "bash -c '$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"'" &
                ;;
            xterm)
                xterm -title "$WINDOW_TITLE" -geometry "$_linux_geom" -e bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
                ;;
        esac
        echo $! > "$WINDOW_PID_FILE"
        ;;

    ghostty-linux)
        ghostty --window-width=40 --window-height=20 -e bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    windows-terminal)
        wt.exe new-tab --title "$WINDOW_TITLE" --size 40,20 bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    powershell)
        powershell.exe -Command "Start-Process bash -ArgumentList '-c','$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"'" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    inline|*)
        # Fallback: no window, just run in background (output to /dev/null)
        hf_log "WARNING: no supported terminal detected (terminal=$terminal), running inline fallback"
        echo "inline" > "$SESSION_DIR/ui-fallback"
        "$BREATHE_SCRIPT" > /dev/null 2>&1 &
        echo $! > "$WINDOW_PID_FILE"
        ;;
esac
