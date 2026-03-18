#!/bin/bash
# Hook: Called on PostToolUse to check if breathing window should resume
# after a PermissionRequest was handled.

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [on-resume] $*" >> /tmp/hushflow-debug.log; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"
SESSION_DIR=""
[ -f "$CONFIG_DIR/.session" ] && SESSION_DIR=$(cat "$CONFIG_DIR/.session" 2>/dev/null)
[ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ] && exit 0
[ ! -f "$SESSION_DIR/permission-ts" ] && exit 0

ts=$(cat "$SESSION_DIR/permission-ts")
now=$(date +%s)
elapsed=$((now - ts))
rm -f "$SESSION_DIR/permission-ts"

hf_log "permission resolved after ${elapsed}s"

if [ "$elapsed" -le 30 ]; then
    # 30s or less: auto-resume with short delay + long fade-in
    hf_log "auto-resuming (<=30s): delay=2s fade=15 ticks"
    echo "$now" > "$SESSION_DIR/working"
    HUSHFLOW_DELAY_SECONDS=2 HUSHFLOW_FADE_TICKS=15 \
        "$SCRIPT_DIR/open-window.sh" &
elif [ "$elapsed" -le 60 ]; then
    # 30-60s: resume with longer delay
    hf_log "auto-resuming (30-60s): delay=3s fade=20 ticks"
    echo "$now" > "$SESSION_DIR/working"
    HUSHFLOW_DELAY_SECONDS=3 HUSHFLOW_FADE_TICKS=20 \
        "$SCRIPT_DIR/open-window.sh" &
else
    # >60s: send system notification instead of auto-opening
    hf_log "expired (>60s): sending notification"
    if [[ "$OSTYPE" == darwin* ]]; then
        osascript -e 'display notification "AI 已恢復運作，隨時可以呼吸" with title "HushFlow"' &
    elif command -v notify-send &>/dev/null; then
        notify-send "HushFlow" "AI 已恢復運作，隨時可以呼吸" &
    fi
fi
