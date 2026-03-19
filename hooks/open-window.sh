#!/bin/bash
# Delayed standalone window launcher for breathing exercises.
# Detects available terminal emulator and opens a small companion window.

set -euo pipefail

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [open-window] $*" >> /tmp/hushflow-debug.log || true; }

run_inline_fallback() {
    hf_log "falling back to inline mode"
    echo "inline" > "$SESSION_DIR/ui-fallback"
    "$BREATHE_SCRIPT" > /dev/null 2>&1 &
    echo $! > "$WINDOW_PID_FILE"
}

write_launch_script() {
    LAUNCH_SCRIPT="$SESSION_DIR/launch-breathe.sh"
    cat > "$LAUNCH_SCRIPT" <<EOF
#!/bin/bash
export HUSHFLOW_SESSION_DIR=$(printf '%q' "$SESSION_DIR")
export HUSHFLOW_CONFIG_DIR=$(printf '%q' "${HUSHFLOW_CONFIG_DIR:-}")
export HUSHFLOW_WINDOW_TITLE=$(printf '%q' "$WINDOW_MATCH_TITLE")
export HUSHFLOW_FADE_TICKS=$(printf '%q' "${HUSHFLOW_FADE_TICKS:-}")
exec $(printf '%q' "$BREATHE_SCRIPT")
EOF
    chmod +x "$LAUNCH_SCRIPT"
}

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
LAUNCH_SCRIPT=""

# Source terminal detection
source "$SCRIPT_DIR/lib/detect-terminal.sh"

config_delay=""
if [ -f "$CONFIG_FILE" ]; then
    config_delay=$(grep "^delay=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2 || true)
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

write_launch_script

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
        if ! window_id=$(
        osascript 2>/dev/null <<EOF
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
    set launchPath to quoted form of POSIX path of "$LAUNCH_SCRIPT"
    set command of surfaceConfig to "/bin/bash -lc " & quoted form of ("exec " & launchPath)
    set font size of surfaceConfig to fontSize
    set wait after command of surfaceConfig to false
    set environment variables of surfaceConfig to {"HUSHFLOW_COLS=" & termCols, "HUSHFLOW_ROWS=" & termRows}
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
        ); then
            hf_log "ghostty osascript failed; falling back to inline mode"
            run_inline_fallback
            exit 0
        fi
        if [ -n "$window_id" ]; then
            echo "$window_id" > "$WINDOW_ID_FILE"
            # Background monitor: auto-dismiss Ghostty's "Process exited" prompt.
            # Single long-running osascript to eliminate startup latency (~300ms).
            # Polls from within AppleScript so keystroke fires within ~70ms of exit.
            osascript <<DISMISSEOF &>/dev/null &
set markerFile to "$MARKER_FILE"
set sessionName to "$SESSION_NAME"

-- Phase 1: wait for marker file removal (graceful_exit started)
repeat
    try
        do shell script "test -f " & quoted form of markerFile
    on error
        exit repeat
    end try
    delay 0.5
end repeat

-- Phase 2: tight-poll until breathe-compact actually exits
repeat 200 times
    try
        do shell script "pgrep -qf 'breathe-compact.*" & sessionName & "'"
    on error
        exit repeat
    end try
    delay 0.05
end repeat

-- Phase 3: dismiss "Process exited" prompt immediately via Ctrl+D (EOT)
delay 0.05
repeat 5 times
    try
        tell application "System Events"
            tell process "Ghostty"
                if not (exists (first window whose name contains "HushFlow")) then exit repeat
                set w to first window whose name contains "HushFlow"
                perform action "AXRaise" of w
                delay 0.02
                -- Ctrl+D is often more effective than Return for closing terminated shells
                keystroke "d" using control down
                delay 0.05
                -- If it still exists, click the close button (Button 1)
                if exists w then click button 1 of w
            end tell
        end tell
        exit repeat
    end try
    delay 0.2
end repeat
DISMISSEOF
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
    set launchPath to quoted form of POSIX path of "$LAUNCH_SCRIPT"
    set {wx, wy, wx2, wy2} to bounds of front window
    set posX to wx + ((wx2 - wx) - winW) / 2
    set posY to wy + ((wy2 - wy) - winH) / 2
    if posX < 0 then set posX to 0
    if posY < 25 then set posY to 25
    do script "/bin/bash -lc " & launchPath
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
    set launchPath to quoted form of POSIX path of "$LAUNCH_SCRIPT"
    set {wx, wy, wx2, wy2} to bounds of current window
    set posX to wx + ((wx2 - wx) - winW) / 2
    set posY to wy + ((wy2 - wy) - winH) / 2
    if posX < 0 then set posX to 0
    if posY < 25 then set posY to 25
    create window with default profile
    tell current session of current window
        write text "/bin/bash -lc " & launchPath
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
                gnome-terminal --title="$WINDOW_TITLE" --geometry="$_linux_geom" -- bash -c "exec \"$LAUNCH_SCRIPT\"" &
                ;;
            konsole)
                konsole --geometry "$_linux_geom" -e bash -c "exec \"$LAUNCH_SCRIPT\"" &
                ;;
            xfce4-terminal)
                xfce4-terminal --title="$WINDOW_TITLE" --geometry="$_linux_geom" -e "bash -c 'exec \"$LAUNCH_SCRIPT\"'" &
                ;;
            xterm)
                xterm -title "$WINDOW_TITLE" -geometry "$_linux_geom" -e bash -c "exec \"$LAUNCH_SCRIPT\"" &
                ;;
        esac
        echo $! > "$WINDOW_PID_FILE"
        ;;

    ghostty-linux)
        ghostty --window-width=40 --window-height=20 -e bash -c "exec \"$LAUNCH_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    windows-terminal)
        wt.exe new-tab --title "$WINDOW_TITLE" --size 40,20 bash -c "exec \"$LAUNCH_SCRIPT\"" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    powershell)
        powershell.exe -Command "Start-Process bash -ArgumentList '-c','exec \"$LAUNCH_SCRIPT\"'" &
        echo $! > "$WINDOW_PID_FILE"
        ;;

    inline|*)
        # Fallback: no window, just run in background (output to /dev/null)
        hf_log "WARNING: no supported terminal detected (terminal=$terminal), running inline fallback"
        run_inline_fallback
        ;;
esac
