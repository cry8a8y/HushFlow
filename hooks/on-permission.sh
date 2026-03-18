#!/bin/bash
# Hook: Called when PermissionRequest is triggered
# Lightweight close: remove marker + record timestamp (don't clean session dir)

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [on-permission] $*" >> /tmp/hushflow-debug.log; }

CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"
SESSION_DIR=""
[ -f "$CONFIG_DIR/.session" ] && SESSION_DIR=$(cat "$CONFIG_DIR/.session" 2>/dev/null)
[ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ] && exit 0

hf_log "permission request detected, pausing breathing window"

# Record timestamp for expiry logic in on-resume.sh
date +%s > "$SESSION_DIR/permission-ts"

# Remove marker to trigger breathe-compact graceful_exit
rm -f "$SESSION_DIR/working"
