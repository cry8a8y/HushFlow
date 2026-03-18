#!/bin/bash
# Hook: Called on PostToolUse to check if breathing window should resume
# after a PermissionRequest was handled.

_HF_HOOK_NAME="on-resume"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/hook-common.sh"

# Fast-path: skip all work unless a permission pause is pending
[ ! -f "$CONFIG_DIR/.permission-pending" ] && exit 0
rm -f "$CONFIG_DIR/.permission-pending"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_hf_load_session || exit 0
[ ! -f "$SESSION_DIR/permission-ts" ] && exit 0

ts=$(cat "$SESSION_DIR/permission-ts")
now=$(date +%s)
rm -f "$SESSION_DIR/permission-ts"

# Validate timestamp is numeric
[[ "$ts" =~ ^[0-9]+$ ]] || exit 0

elapsed=$((now - ts))

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
        osascript -e 'display notification "HushFlow is ready — breathe anytime" with title "HushFlow"' &
    elif command -v notify-send &>/dev/null; then
        notify-send "HushFlow" "HushFlow is ready — breathe anytime" &
    fi
fi
