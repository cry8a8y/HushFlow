#!/bin/bash
# Hook: Called when PermissionRequest is triggered
# Lightweight close: remove marker + record timestamp (don't clean session dir)

_HF_HOOK_NAME="on-permission"
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/hook-common.sh"

_hf_load_session || exit 0

hf_log "permission request detected, pausing breathing window"

# Create fast-path flag so on-resume.sh can skip work when not needed
touch "$CONFIG_DIR/.permission-pending"

# Record timestamp for expiry logic in on-resume.sh
date +%s > "$SESSION_DIR/permission-ts"

# Remove marker to trigger breathe-compact graceful_exit
rm -f "$SESSION_DIR/working"
