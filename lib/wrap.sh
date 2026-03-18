#!/bin/bash
# HushFlow wrap — breathing exercises while any command runs
# Usage: hushflow wrap -- npm install

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse flags before --
TARGET="claude"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            TARGET="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

case "$TARGET" in
    claude)  CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}" ;;
    gemini)  CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.gemini/hushflow}" ;;
    codex)   CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.codex/hushflow}" ;;
    *)       CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}" ;;
esac

export HUSHFLOW_CONFIG_DIR="$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config"

# Exit if disabled — just run the command directly
if [ -f "$CONFIG_FILE" ] && grep -q "^enabled=false" "$CONFIG_FILE"; then
    exec "$@"
fi

if [ $# -eq 0 ]; then
    echo "Usage: hushflow wrap -- <command>" >&2
    echo "Example: hushflow wrap -- npm install" >&2
    exit 1
fi

# Session setup
SESSION_DIR="/tmp/hushflow-wrap-$$"
mkdir -p "$SESSION_DIR"
export HUSHFLOW_SESSION_DIR="$SESSION_DIR"
MARKER_FILE="$SESSION_DIR/working"
echo "$(date +%s)" > "$MARKER_FILE"

# Read delay from config
delay=3
if [ -f "$CONFIG_FILE" ]; then
    saved_delay=$(grep "^delay=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
    [[ "$saved_delay" =~ ^[0-9]+$ ]] && delay="$saved_delay"
fi

BREATHE_PID=""

cleanup() {
    rm -f "$MARKER_FILE"
    if [ -n "$BREATHE_PID" ] && kill -0 "$BREATHE_PID" 2>/dev/null; then
        sleep 0.3
        kill "$BREATHE_PID" 2>/dev/null || true
    fi
    rm -rf "$SESSION_DIR"
}

handle_signal() {
    cleanup
    exit 130
}

trap cleanup EXIT
trap handle_signal INT TERM

# Launch breathing UI after delay
(
    sleep "$delay"
    [ -f "$MARKER_FILE" ] || exit 0
    HUSHFLOW_SESSION_DIR="$SESSION_DIR" \
    HUSHFLOW_CONFIG_DIR="$CONFIG_DIR" \
    HUSHFLOW_UI_MODE="${HUSHFLOW_UI_MODE:-window}" \
    HUSHFLOW_DIR="$SCRIPT_DIR" \
    bash "$SCRIPT_DIR/hooks/open-window.sh"
) &
BREATHE_PID=$!

# Run the wrapped command in foreground, capture exit code
"$@"
CMD_EXIT=$?

# Command finished — stop breathing
rm -f "$MARKER_FILE"

exit "$CMD_EXIT"
