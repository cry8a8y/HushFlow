#!/bin/bash
# HushFlow doctor — diagnose installation and environment
# Usage: hushflow doctor

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OK=0
WARN=0
ERR=0

ok()   { OK=$((OK+1));   echo "  ✓ $1"; }
warn() { WARN=$((WARN+1)); echo "  ⚠ $1"; }
err()  { ERR=$((ERR+1));  echo "  ✗ $1"; }

echo "HushFlow Doctor"
echo "==============="
echo ""

# --- Dependencies ---
echo "Dependencies:"
if command -v jq &>/dev/null; then
    ok "jq found ($(jq --version 2>&1))"
else
    err "jq not found — required for install/uninstall"
fi

if command -v bash &>/dev/null; then
    bash_ver=$(bash --version | head -1 | sed 's/.*version //' | cut -d'(' -f1)
    ok "bash $bash_ver"
else
    err "bash not found"
fi

echo ""

# --- Script integrity ---
echo "Script integrity:"
for script in breathe-compact.sh hooks/on-start.sh hooks/on-stop.sh hooks/open-window.sh hooks/open-tmux-popup.sh set-exercise.sh install.sh cli.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        if bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
            ok "$script"
        else
            err "$script has syntax errors"
        fi
    else
        err "$script missing"
    fi
done

echo ""

# --- AI tool hooks ---
echo "Hook installation:"

check_hooks() {
    local tool=$1
    local file=$2
    local start_event=$3
    local stop_event=$4

    if [ ! -f "$file" ]; then
        warn "$tool: settings file not found ($file)"
        return
    fi

    local has_start has_stop
    has_start=$(jq -e ".hooks.${start_event}[]?.hooks[]? | select(.command | contains(\"on-start.sh\"))" "$file" 2>/dev/null)
    has_stop=$(jq -e ".hooks.${stop_event}[]?.hooks[]? | select(.command | contains(\"on-stop.sh\"))" "$file" 2>/dev/null)

    if [ -n "$has_start" ] && [ -n "$has_stop" ]; then
        ok "$tool: start + stop hooks installed"
    elif [ -n "$has_start" ]; then
        warn "$tool: only start hook found (missing stop)"
    elif [ -n "$has_stop" ]; then
        warn "$tool: only stop hook found (missing start)"
    else
        warn "$tool: no hooks found in $file"
    fi
}

if [ -d "$HOME/.claude" ]; then
    check_hooks "Claude Code" "$HOME/.claude/settings.json" "UserPromptSubmit" "Stop"
else
    warn "Claude Code: ~/.claude not found"
fi

if [ -d "$HOME/.gemini" ]; then
    check_hooks "Gemini CLI" "$HOME/.gemini/settings.json" "BeforeAgent" "AfterAgent"
else
    warn "Gemini CLI: ~/.gemini not found (skip if not using Gemini)"
fi

if [ -d "$HOME/.codex" ]; then
    check_hooks "Codex CLI" "$HOME/.codex/hooks.json" "SessionStart" "Stop"
else
    warn "Codex CLI: ~/.codex not found (skip if not using Codex)"
fi

echo ""

# --- Configuration ---
echo "Configuration:"

for tool_dir in "$HOME/.claude/hushflow" "$HOME/.gemini/hushflow" "$HOME/.codex/hushflow"; do
    cfg="$tool_dir/config"
    if [ -f "$cfg" ]; then
        tool_name=$(basename "$(dirname "$tool_dir")")
        enabled=$(grep "^enabled=" "$cfg" 2>/dev/null | cut -d= -f2)
        exercise=$(grep "^exercise=" "$cfg" 2>/dev/null | cut -d= -f2)
        theme=$(grep "^theme=" "$cfg" 2>/dev/null | cut -d= -f2)
        animation=$(grep "^animation=" "$cfg" 2>/dev/null | cut -d= -f2)
        delay=$(grep "^delay=" "$cfg" 2>/dev/null | cut -d= -f2)

        if [ "$enabled" = "false" ]; then
            warn "$tool_name: disabled (enabled=false)"
        else
            ok "$tool_name: enabled, exercise=${exercise:-0}, theme=${theme:-teal}, animation=${animation:-constellation}, delay=${delay:-5}s"
        fi
    fi
done

echo ""

# --- Active sessions ---
echo "Active sessions:"
session_count=0
for d in /tmp/hushflow-*/; do
    if [ -d "$d" ] 2>/dev/null; then
        session_count=$((session_count+1))
        marker=""
        [ -f "$d/working" ] && marker="active" || marker="stale"
        pid_info=""
        if [ -f "$d/window-pid" ]; then
            wpid=$(cat "$d/window-pid")
            comm=$(ps -p "$wpid" -o comm= 2>/dev/null || echo "dead")
            pid_info=" pid=$wpid($comm)"
        fi
        if [ "$marker" = "active" ]; then
            ok "$(basename "$d"): $marker$pid_info"
        else
            warn "$(basename "$d"): $marker (no marker file)$pid_info"
        fi
    fi
done
[ "$session_count" -eq 0 ] && ok "No active sessions"

echo ""

# --- UI fallback detection ---
echo "Window launch:"
fallback_count=0
for d in /tmp/hushflow-*/; do
    [ -d "$d" ] 2>/dev/null || continue
    if [ -f "$d/ui-fallback" ]; then
        fallback_count=$((fallback_count+1))
    fi
done
if [ "$fallback_count" -gt 0 ]; then
    warn "Inline fallback used in $fallback_count session(s) — breathing ran hidden in background"
    echo "      This means HushFlow couldn't open a terminal window."
    echo "      Try: set HUSHFLOW_UI_MODE=tmux-pane (if using tmux)"
    echo "      Or use a supported terminal: Ghostty, iTerm2, Terminal.app, GNOME Terminal, Windows Terminal"
else
    ok "No fallback issues detected"
fi

echo ""

# --- Terminal detection ---
echo "Terminal detection:"
if [ -f "$SCRIPT_DIR/lib/detect-terminal.sh" ]; then
    source "$SCRIPT_DIR/lib/detect-terminal.sh" 2>/dev/null
    terminal=$(detect_terminal 2>/dev/null || echo "unknown")
    ok "Detected: $terminal"
else
    ok "Terminal: $TERM"
fi

# TrueColor check
if [ "$COLORTERM" = "truecolor" ] || [ "$COLORTERM" = "24bit" ]; then
    ok "TrueColor: Supported (COLORTERM=$COLORTERM)"
else
    case "$TERM" in
        iterm*|ghostty*|wezterm*|alacritty*|kitty*)
            ok "TrueColor: Supported via $TERM"
            ;;
        *)
            warn "TrueColor: Not detected — colors may look grainy (try Ghostty, iTerm2, or WezTerm)"
            ;;
    esac
fi

echo ""

# --- Summary ---
echo "==============="
total=$((OK + WARN + ERR))
echo "  $OK ok, $WARN warnings, $ERR errors"
if [ "$ERR" -gt 0 ]; then
    echo "  Some issues need fixing."
    exit 1
elif [ "$WARN" -gt 0 ]; then
    echo "  Some warnings — HushFlow should still work."
    exit 0
else
    echo "  Everything looks good!"
    exit 0
fi
