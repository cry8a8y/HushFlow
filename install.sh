#!/bin/bash
# Installer for HushFlow
# Supports: Claude Code, Gemini CLI, Codex CLI
# Usage: ./install.sh [--target claude|gemini|codex] [--uninstall]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ON_START="$SCRIPT_DIR/hooks/on-start.sh"
ON_STOP="$SCRIPT_DIR/hooks/on-stop.sh"

# Legacy paths (for migration from Mindful-Claude)
LEGACY_CONFIG_DIR="$HOME/.claude/mindful"
LEGACY_COMMAND_FILE="$HOME/.claude/commands/mindful.md"

# --- Helper functions ---

ensure_config() {
    local config_dir=$1
    mkdir -p "$config_dir"
    if [ ! -f "$config_dir/config" ]; then
        printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=constellation\n' > "$config_dir/config"
        echo "  Created config at $config_dir/config"
    fi
}

validate_and_write() {
    local json="$1"
    local dest="$2"
    if ! echo "$json" | jq empty 2>/dev/null; then
        echo "  ERROR: jq produced invalid JSON. Aborting write to $dest" >&2
        return 1
    fi
    if [ -f "$dest" ]; then
        cp "$dest" "$dest.backup"
    fi
    echo "$json" > "$dest"
}

install_claude() {
    local settings_file="$HOME/.claude/settings.json"
    local config_dir="$HOME/.claude/hushflow"
    local command_file="$HOME/.claude/commands/hushflow.md"

    echo "Installing for Claude Code..."
    mkdir -p "$HOME/.claude" "$HOME/.claude/commands"

    # Migrate legacy config
    if [ -d "$LEGACY_CONFIG_DIR" ] && [ ! -d "$config_dir" ]; then
        mv "$LEGACY_CONFIG_DIR" "$config_dir"
    fi

    ensure_config "$config_dir"

    # Install slash command
    cp "$SCRIPT_DIR/commands/hushflow.md" "$command_file"
    rm -f "$LEGACY_COMMAND_FILE"
    echo "  Installed /hushflow slash command"

    # Start from existing settings or empty object
    local settings
    if [ -f "$settings_file" ]; then
        settings=$(cat "$settings_file")
    else
        settings='{}'
    fi

    # Check if already installed
    if echo "$settings" | jq -e ".hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains(\"on-start.sh\"))" &>/dev/null; then
        echo "  Hooks already installed."
        return
    fi

    # Build and merge hooks (pass config dir so the right tool's config is used)
    local start_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_START"'", "async": true}]}]'
    local stop_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_STOP"'", "async": true}]}]'
    settings=$(echo "$settings" | jq \
        --argjson start_hook "$start_hook" \
        --argjson stop_hook "$stop_hook" \
        '.hooks //= {} |
         .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + $start_hook |
         .hooks.Stop = (.hooks.Stop // []) + $stop_hook')

    # Validate and write
    validate_and_write "$settings" "$settings_file" || return 1
    echo "  Hooks installed to $settings_file"
}

install_gemini() {
    local settings_file="$HOME/.gemini/settings.json"
    local config_dir="$HOME/.gemini/hushflow"

    echo "Installing for Gemini CLI..."
    mkdir -p "$HOME/.gemini"
    ensure_config "$config_dir"

    local settings
    if [ -f "$settings_file" ]; then
        settings=$(cat "$settings_file")
    else
        settings='{}'
    fi

    # Check if already installed
    if echo "$settings" | jq -e ".hooks.BeforeAgent[]?.hooks[]? | select(.command | contains(\"on-start.sh\"))" &>/dev/null; then
        echo "  Hooks already installed."
        return
    fi

    # Gemini uses BeforeAgent (start) and AfterAgent (stop)
    local start_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_START"'", "timeout": 60000}]}]'
    local stop_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_STOP"'", "timeout": 5000}]}]'
    settings=$(echo "$settings" | jq \
        --argjson start_hook "$start_hook" \
        --argjson stop_hook "$stop_hook" \
        '.hooks //= {} |
         .hooks.BeforeAgent = (.hooks.BeforeAgent // []) + $start_hook |
         .hooks.AfterAgent = (.hooks.AfterAgent // []) + $stop_hook')

    validate_and_write "$settings" "$settings_file" || return 1
    echo "  Hooks installed to $settings_file"
}

install_codex() {
    local hooks_file="$HOME/.codex/hooks.json"
    local config_dir="$HOME/.codex/hushflow"

    echo "Installing for Codex CLI..."
    mkdir -p "$HOME/.codex"
    ensure_config "$config_dir"

    local settings
    if [ -f "$hooks_file" ]; then
        settings=$(cat "$hooks_file")
    else
        settings='{}'
    fi

    # Check if already installed
    if echo "$settings" | jq -e ".hooks.Stop[]?.hooks[]? | select(.command | contains(\"on-stop.sh\"))" &>/dev/null; then
        echo "  Hooks already installed."
        return
    fi

    # Codex has SessionStart and Stop (no BeforeAgent yet)
    local start_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_START"'", "timeout": 60}]}]'
    local stop_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_STOP"'", "timeout": 5}]}]'
    settings=$(echo "$settings" | jq \
        --argjson start_hook "$start_hook" \
        --argjson stop_hook "$stop_hook" \
        '.hooks //= {} |
         .hooks.SessionStart = (.hooks.SessionStart // []) + $start_hook |
         .hooks.Stop = (.hooks.Stop // []) + $stop_hook')

    validate_and_write "$settings" "$hooks_file" || return 1
    echo "  Hooks installed to $hooks_file"
}

uninstall_tool() {
    local tool=$1
    case "$tool" in
        claude)
            local sf="$HOME/.claude/settings.json"
            if [ -f "$sf" ] && command -v jq &>/dev/null; then
                local s=$(cat "$sf")
                s=$(echo "$s" | jq \
                    --arg on_start "$ON_START" --arg on_stop "$ON_STOP" \
                    '(.hooks.UserPromptSubmit // []) |= [.[] | select(.hooks | all(.command | contains($on_start) | not))] |
                     (.hooks.Stop // []) |= [.[] | select(.hooks | all(.command | contains($on_stop) | not))] |
                     if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end |
                     if .hooks.Stop == [] then del(.hooks.Stop) else . end |
                     if .hooks == {} then del(.hooks) else . end')
                echo "$s" > "$sf"
                echo "  Removed Claude Code hooks"
            fi
            rm -rf "$HOME/.claude/hushflow"
            rm -f "$HOME/.claude/commands/hushflow.md"
            ;;
        gemini)
            local sf="$HOME/.gemini/settings.json"
            if [ -f "$sf" ] && command -v jq &>/dev/null; then
                local s=$(cat "$sf")
                s=$(echo "$s" | jq \
                    --arg on_start "$ON_START" --arg on_stop "$ON_STOP" \
                    '(.hooks.BeforeAgent // []) |= [.[] | select(.hooks | all(.command | contains($on_start) | not))] |
                     (.hooks.AfterAgent // []) |= [.[] | select(.hooks | all(.command | contains($on_stop) | not))] |
                     if .hooks.BeforeAgent == [] then del(.hooks.BeforeAgent) else . end |
                     if .hooks.AfterAgent == [] then del(.hooks.AfterAgent) else . end |
                     if .hooks == {} then del(.hooks) else . end')
                echo "$s" > "$sf"
                echo "  Removed Gemini CLI hooks"
            fi
            rm -rf "$HOME/.gemini/hushflow"
            ;;
        codex)
            local sf="$HOME/.codex/hooks.json"
            if [ -f "$sf" ] && command -v jq &>/dev/null; then
                local s=$(cat "$sf")
                s=$(echo "$s" | jq \
                    --arg on_start "$ON_START" --arg on_stop "$ON_STOP" \
                    '(.hooks.SessionStart // []) |= [.[] | select(.hooks | all(.command | contains($on_start) | not))] |
                     (.hooks.Stop // []) |= [.[] | select(.hooks | all(.command | contains($on_stop) | not))] |
                     if .hooks.SessionStart == [] then del(.hooks.SessionStart) else . end |
                     if .hooks.Stop == [] then del(.hooks.Stop) else . end |
                     if .hooks == {} then del(.hooks) else . end')
                echo "$s" > "$sf"
                echo "  Removed Codex CLI hooks"
            fi
            rm -rf "$HOME/.codex/hushflow"
            ;;
    esac
}

# --- Main ---

# Handle --uninstall
if [[ " $* " == *" --uninstall "* ]]; then
    echo "Uninstalling HushFlow..."
    uninstall_tool claude
    uninstall_tool gemini
    uninstall_tool codex
    # Clean up session directories
    rm -rf /tmp/hushflow-*/ 2>/dev/null || true
    # Legacy cleanup (pre-session-dir files)
    rm -f /tmp/hushflow-working /tmp/hushflow-tmux-pane-id /tmp/hushflow-window-pid /tmp/hushflow-window-id /tmp/hushflow-exercise
    rmdir /tmp/hushflow-ui.lock 2>/dev/null || true
    rmdir /tmp/hushflow-tmux-popup.lock 2>/dev/null || true
    echo "Done."
    exit 0
fi

echo ""
echo "  HushFlow"
echo "  Turn AI thinking time into mindful breathing."
echo ""

# Check prerequisites
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required."
    echo "Install: brew install jq (macOS) or apt install jq (Linux)"
    exit 1
fi

# Make scripts executable
chmod +x "$SCRIPT_DIR/breathe-compact.sh" "$SCRIPT_DIR/set-exercise.sh"
chmod +x "$SCRIPT_DIR/hooks/on-start.sh" "$SCRIPT_DIR/hooks/on-stop.sh"
chmod +x "$SCRIPT_DIR/hooks/open-tmux-popup.sh"
chmod +x "$SCRIPT_DIR/hooks/open-standalone-window.sh" 2>/dev/null || true
chmod +x "$SCRIPT_DIR/hooks/open-window.sh"
chmod +x "$SCRIPT_DIR/lib/detect-terminal.sh"

# Determine targets
target=""
if [[ " $* " == *" --target "* ]]; then
    target=$(echo "$@" | sed 's/.*--target //' | awk '{print $1}')
fi

installed=0

if [ -n "$target" ]; then
    # Install for specific target
    case "$target" in
        claude)  install_claude; installed=1 ;;
        gemini)  install_gemini; installed=1 ;;
        codex)   install_codex;  installed=1 ;;
        *)       echo "Unknown target: $target"; echo "Options: claude, gemini, codex"; exit 1 ;;
    esac
else
    # Auto-detect: install for all available AI tools
    if [ -d "$HOME/.claude" ] || command -v claude &>/dev/null; then
        install_claude
        installed=$((installed + 1))
    fi
    if [ -d "$HOME/.gemini" ] || command -v gemini &>/dev/null; then
        install_gemini
        installed=$((installed + 1))
    fi
    if [ -d "$HOME/.codex" ] || command -v codex &>/dev/null; then
        install_codex
        installed=$((installed + 1))
    fi

    if [ "$installed" -eq 0 ]; then
        echo "No AI tools detected. Installing for Claude Code by default."
        install_claude
        installed=1
    fi
fi

echo ""
echo "Installed for $installed tool(s). Restart your AI tool for hooks to take effect."
echo ""

# Quick demo: show a 3-second breathing preview
if [ -t 1 ]; then
    echo "  Preview:"
    echo ""
    dots=("·" "✧" "✦" "✧" "·" " " " " " ")
    for ((i=0; i<24; i++)); do
        idx=$((i % 8))
        line="    ${dots[$idx]}  ${dots[$(( (idx+2) % 8 ))]}  ${dots[$(( (idx+4) % 8 ))]}  ${dots[$(( (idx+6) % 8 ))]}"
        printf "\r%s" "$line"
        sleep 0.125
    done
    printf "\r                              \r"
    echo ""
fi

echo "Configuration:"
echo "  $SCRIPT_DIR/set-exercise.sh          # List exercises & themes"
echo "  $SCRIPT_DIR/set-exercise.sh theme teal  # Change theme"
echo "  $SCRIPT_DIR/set-exercise.sh box         # Change exercise"
echo ""
echo "Doctor:    $SCRIPT_DIR/doctor.sh"
echo "Uninstall: $SCRIPT_DIR/install.sh --uninstall"
