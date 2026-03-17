#!/bin/bash
# Delayed standalone window launcher for breathing exercises.
# Detects available terminal emulator and opens a small companion window.

set -euo pipefail

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [open-window] $*" >> /tmp/hushflow-debug.log; }

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
set termCols to 36
set termRows to 14
set fontSize to 14
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
    set wait after command of surfaceConfig to false
    set environment variables of surfaceConfig to {"HUSHFLOW_SESSION_DIR=$SESSION_DIR", "HUSHFLOW_CONFIG_DIR=${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}", "HUSHFLOW_WINDOW_TITLE=$WINDOW_MATCH_TITLE", "HUSHFLOW_COLS=" & termCols, "HUSHFLOW_ROWS=" & termRows}
    set newWindow to new window with configuration surfaceConfig
    set winId to id of newWindow
end tell
set targetTitle to "$WINDOW_MATCH_TITLE"

tell application "System Events"
    tell process "Ghostty"
        repeat with attempt from 1 to 20
            repeat with targetWindow in windows
                try
                    if name of targetWindow is targetTitle then
                        set position of targetWindow to {posX, posY}
                        set size of targetWindow to {winW, winH}
                        return winId
                    end if
                end try
            end repeat
            delay 0.15
        end repeat
    end tell
end tell

return winId
EOF
        )
        if [ -n "$window_id" ]; then
            echo "$window_id" > "$WINDOW_ID_FILE"
        fi
        ;;

    terminal-app)
        # macOS Terminal.app — centered on same screen, respects other-app focus
        osascript <<EOF
set winW to 560
set winH to 420
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
set winH to 420
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

    gnome-terminal)
        gnome-terminal --title="$WINDOW_TITLE" --geometry=26x7+1260+80 -- bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    konsole)
        konsole --geometry 26x7+1260+80 -e bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    xfce4-terminal)
        xfce4-terminal --title="$WINDOW_TITLE" --geometry=26x7+1260+80 -e "bash -c '$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"'" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    xterm)
        xterm -title "$WINDOW_TITLE" -geometry 40x12+1260+80 -e bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    ghostty-linux)
        ghostty --window-width=26 --window-height=7 -e bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    windows-terminal)
        wt.exe new-tab --title "$WINDOW_TITLE" --size 26,7 bash -c "$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    powershell)
        powershell.exe -Command "Start-Process bash -ArgumentList '-c','$BREATHE_ENV; exec \"$BREATHE_SCRIPT\"'" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    inline|*)
        # Fallback: no window, just run in background (output to /dev/null)
        "$BREATHE_SCRIPT" > /dev/null 2>&1 &
        echo $! > "$WINDOW_PID_FILE"
        ;;
esac
