#!/bin/bash
# Shared bootstrap for HushFlow hooks.
# Source this file at the top of each hook script.
# Provides: hf_log(), CONFIG_DIR, SESSION_DIR (loaded from .session file)
# Requires: caller sets _HF_HOOK_NAME before sourcing.

_HF_HOOK_NAME="${_HF_HOOK_NAME:-hook}"

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [$_HF_HOOK_NAME] $*" >> /tmp/hushflow-debug.log; }

CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"

# Load session directory from .session pointer file
_hf_load_session() {
    SESSION_DIR=""
    [ -f "$CONFIG_DIR/.session" ] && SESSION_DIR=$(cat "$CONFIG_DIR/.session" 2>/dev/null)
    if [ -z "$SESSION_DIR" ] || [ ! -d "$SESSION_DIR" ]; then
        hf_log "no session dir found"
        return 1
    fi
    return 0
}
