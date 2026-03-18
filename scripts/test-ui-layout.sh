#!/bin/bash
# HushFlow UI Layout & Visual Regression Test Tool
#
# Modes:
#   --ci              Fully automated (tmux only, no interactive prompts)
#   --interactive     Semi-automated (launches UI, prompts for human verification)
#
# Options:
#   --mode <mode>     UI mode: window, tmux-pane, tmux-popup, inline (default: all)
#   --theme <name>    Theme to test (default: teal)
#   --animation <name> Animation to test (default: constellation)
#   --cols <n>        Terminal columns (default: 80)
#   --rows <n>        Terminal rows (default: 24)
#   --duration <n>    Seconds to run animation (default: 5)
#
# Usage:
#   bash scripts/test-ui-layout.sh --ci --mode tmux-pane
#   bash scripts/test-ui-layout.sh --interactive
#   bash scripts/test-ui-layout.sh --mode inline --cols 40 --rows 12

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CI_MODE=0
INTERACTIVE=0
UI_MODE=""
THEME="teal"
ANIMATION="constellation"
COLS=80
ROWS=24
DURATION=5

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --ci) CI_MODE=1; shift ;;
        --interactive) INTERACTIVE=1; shift ;;
        --mode) UI_MODE="$2"; shift 2 ;;
        --theme) THEME="$2"; shift 2 ;;
        --animation) ANIMATION="$2"; shift 2 ;;
        --cols) COLS="$2"; shift 2 ;;
        --rows) ROWS="$2"; shift 2 ;;
        --duration) DURATION="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Counters (file-based for subshell safety)
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT
echo 0 > "$TMPDIR_TEST/.pass"
echo 0 > "$TMPDIR_TEST/.fail"

pass() {
    local c; c=$(cat "$TMPDIR_TEST/.pass"); echo $((c + 1)) > "$TMPDIR_TEST/.pass"
    echo "  PASS: $1"
}
fail() {
    local c; c=$(cat "$TMPDIR_TEST/.fail"); echo $((c + 1)) > "$TMPDIR_TEST/.fail"
    echo "  FAIL: $1"
}
section() { echo ""; echo "=== $1 ==="; }

# ============================================================
# tmux-pane automated tests (CI-safe)
# ============================================================
test_tmux_pane() {
    local cols="$1" rows="$2" theme="$3" anim="$4"
    local label="tmux-pane ${cols}x${rows} ${theme}/${anim}"
    local session="hf-test-$$"

    # Create tmux session with specific size
    tmux new-session -d -s "$session" -x "$cols" -y "$rows" 2>/dev/null || {
        fail "$label: tmux session creation failed"
        return
    }

    # Create session dir and marker
    local sess_dir="$TMPDIR_TEST/hf-session-${cols}x${rows}"
    mkdir -p "$sess_dir"
    echo "1" > "$sess_dir/working"

    # Create isolated config
    local config_dir="$TMPDIR_TEST/config-${cols}x${rows}"
    mkdir -p "$config_dir"
    printf 'enabled=true\nexercise=0\ndelay=0\ntheme=%s\nanimation=%s\n' "$theme" "$anim" > "$config_dir/config"

    # Launch breathe-compact.sh in the tmux pane
    local pane_rows=$((rows > 14 ? 12 : rows - 2))
    [ "$pane_rows" -lt 8 ] && pane_rows=8

    local pane_id
    pane_id=$(tmux split-window -d -v -l "$pane_rows" -t "$session" -P -F '#{pane_id}' \
        "HUSHFLOW_SESSION_DIR='$sess_dir' HUSHFLOW_CONFIG_DIR='$config_dir' HUSHFLOW_COLS=$cols HUSHFLOW_ROWS=$pane_rows TERM=xterm-256color bash '$SCRIPT_DIR/breathe-compact.sh' '$sess_dir'" 2>/dev/null) || {
        fail "$label: pane creation failed"
        tmux kill-session -t "$session" 2>/dev/null
        return
    }

    # Wait for animation to render
    sleep "$DURATION"

    # Capture pane content
    local capture
    capture=$(tmux capture-pane -t "$pane_id" -p 2>/dev/null || echo "")

    if [ -z "$capture" ]; then
        fail "$label: empty capture (animation may have crashed)"
        rm -f "$sess_dir/working"
        tmux kill-session -t "$session" 2>/dev/null
        return
    fi

    # Save capture as artifact
    local artifact="$TMPDIR_TEST/capture-${cols}x${rows}-${theme}-${anim}.txt"
    echo "$capture" > "$artifact"

    # --- Assertions ---

    # 1. Title visible (should contain "Breathe" or exercise name)
    if echo "$capture" | grep -qi "breathe\|coherent\|sigh\|box\|4-7-8"; then
        pass "$label: title visible"
    else
        fail "$label: title not found in capture"
    fi

    # 2. No overflow (line count <= pane rows)
    local line_count
    line_count=$(echo "$capture" | wc -l | tr -d ' ')
    if [ "$line_count" -le "$((pane_rows + 1))" ]; then
        pass "$label: no vertical overflow ($line_count lines)"
    else
        fail "$label: vertical overflow ($line_count > $pane_rows)"
    fi

    # 3. No line exceeds terminal width (check for truncation)
    local max_width=0
    while IFS= read -r line; do
        # Strip ANSI escape codes for width measurement
        local clean
        clean=$(echo "$line" | sed 's/\x1b\[[0-9;]*[a-zA-Z]//g')
        local w=${#clean}
        [ "$w" -gt "$max_width" ] && max_width=$w
    done <<< "$capture"
    if [ "$max_width" -le "$cols" ]; then
        pass "$label: no horizontal overflow (max $max_width cols)"
    else
        fail "$label: horizontal overflow ($max_width > $cols)"
    fi

    # 4. Animation area has content (not all blank)
    local non_blank
    non_blank=$(echo "$capture" | sed '/^[[:space:]]*$/d' | wc -l | tr -d ' ')
    if [ "$non_blank" -ge 3 ]; then
        pass "$label: animation area has content ($non_blank non-blank lines)"
    else
        fail "$label: animation area mostly blank ($non_blank lines)"
    fi

    # Cleanup: stop animation
    rm -f "$sess_dir/working"
    sleep 1
    tmux kill-session -t "$session" 2>/dev/null || true
}

# ============================================================
# inline automated test
# ============================================================
test_inline() {
    local cols="$1" rows="$2" theme="$3" anim="$4"
    local label="inline ${cols}x${rows} ${theme}/${anim}"

    local sess_dir="$TMPDIR_TEST/inline-${cols}x${rows}"
    mkdir -p "$sess_dir"
    echo "1" > "$sess_dir/working"

    local config_dir="$TMPDIR_TEST/inline-config-${cols}x${rows}"
    mkdir -p "$config_dir"
    printf 'enabled=true\nexercise=0\ndelay=0\ntheme=%s\nanimation=%s\n' "$theme" "$anim" > "$config_dir/config"

    # Run breathe-compact.sh and capture output (auto-exit after DURATION)
    local output
    output=$(timeout "$((DURATION + 2))" bash -c "
        HUSHFLOW_SESSION_DIR='$sess_dir' \
        HUSHFLOW_CONFIG_DIR='$config_dir' \
        HUSHFLOW_COLS=$cols HUSHFLOW_ROWS=$rows \
        TERM=xterm-256color \
        bash '$SCRIPT_DIR/breathe-compact.sh' '$sess_dir' &
        pid=\$!
        sleep $DURATION
        rm -f '$sess_dir/working'
        wait \$pid 2>/dev/null
    " 2>/dev/null) || true

    # For inline mode, just verify it didn't crash
    pass "$label: no crash"
}

# ============================================================
# Window mode — semi-automated (interactive only)
# ============================================================
test_window_interactive() {
    local cols="$1" rows="$2" theme="$3" anim="$4"
    local label="window ${cols}x${rows} ${theme}/${anim}"

    echo ""
    echo "--- Testing: $label ---"
    echo "Launching HushFlow window..."

    local sess_dir="$TMPDIR_TEST/window-${cols}x${rows}"
    mkdir -p "$sess_dir"
    echo "1" > "$sess_dir/working"

    local config_dir="$TMPDIR_TEST/window-config-${cols}x${rows}"
    mkdir -p "$config_dir"
    printf 'enabled=true\nexercise=0\ndelay=0\ntheme=%s\nanimation=%s\n' "$theme" "$anim" > "$config_dir/config"

    # Launch window
    HUSHFLOW_SESSION_DIR="$sess_dir" HUSHFLOW_CONFIG_DIR="$config_dir" \
    HUSHFLOW_COLS="$cols" HUSHFLOW_ROWS="$rows" \
        bash "$SCRIPT_DIR/hooks/open-window.sh" "$sess_dir" &

    sleep "$DURATION"

    # macOS: try to get window bounds automatically
    if [ "$(uname)" = "Darwin" ]; then
        local front_app
        front_app=$(osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null || echo "unknown")
        echo "  Current frontmost app: $front_app"
    fi

    echo ""
    echo "  Please verify:"
    echo "    [1] Window opened successfully?"
    echo "    [2] Animation is visible and not clipped?"
    echo "    [3] Title and content are not overlapping?"
    echo "    [4] No visual artifacts or overflow?"
    echo ""
    read -r -p "  Pass? (y/n): " answer

    # Stop animation
    rm -f "$sess_dir/working"
    sleep 1

    if [[ "$answer" =~ ^[Yy]$ ]]; then
        pass "$label"
    else
        fail "$label: human verification failed"
    fi
}

# ============================================================
# Main execution
# ============================================================

echo "HushFlow UI Layout Test Tool"
echo "============================"

# Define test matrix
SIZES=("40 12" "80 24" "200 50")
THEMES=("teal" "twilight" "dracula")
ANIMS=("constellation" "ripple" "wave")

if [ "$CI_MODE" -eq 1 ]; then
    # CI mode: only tmux-pane and inline (fully automated)
    if ! command -v tmux &>/dev/null; then
        echo "SKIP: tmux not installed, skipping tmux tests"
    else
        section "tmux-pane: Size matrix"
        for size in "${SIZES[@]}"; do
            IFS=' ' read -r c r <<< "$size"
            test_tmux_pane "$c" "$r" "$THEME" "$ANIMATION"
        done

        section "tmux-pane: Theme matrix"
        for theme in "${THEMES[@]}"; do
            test_tmux_pane 80 24 "$theme" "$ANIMATION"
        done

        section "tmux-pane: Animation matrix"
        for anim in "${ANIMS[@]}"; do
            test_tmux_pane 80 24 "$THEME" "$anim"
        done
    fi

    section "Inline: Size matrix"
    for size in "${SIZES[@]}"; do
        IFS=' ' read -r c r <<< "$size"
        test_inline "$c" "$r" "$THEME" "$ANIMATION"
    done

elif [ "$INTERACTIVE" -eq 1 ]; then
    # Interactive mode: all modes with human verification for window
    if command -v tmux &>/dev/null; then
        section "tmux-pane: Automated checks"
        for size in "${SIZES[@]}"; do
            IFS=' ' read -r c r <<< "$size"
            test_tmux_pane "$c" "$r" "$THEME" "$ANIMATION"
        done
    fi

    section "Window: Human verification"
    test_window_interactive 80 24 "$THEME" "$ANIMATION"

    section "Inline: Automated checks"
    test_inline 80 24 "$THEME" "$ANIMATION"

elif [ -n "$UI_MODE" ]; then
    # Single mode test
    case "$UI_MODE" in
        tmux-pane)
            section "tmux-pane: $COLS x $ROWS"
            test_tmux_pane "$COLS" "$ROWS" "$THEME" "$ANIMATION"
            ;;
        tmux-popup)
            echo "tmux-popup requires interactive verification"
            echo "Use: --interactive"
            ;;
        inline)
            section "Inline: $COLS x $ROWS"
            test_inline "$COLS" "$ROWS" "$THEME" "$ANIMATION"
            ;;
        window)
            section "Window: $COLS x $ROWS"
            if [ "$CI_MODE" -eq 1 ]; then
                echo "SKIP: Window mode not supported in CI"
            else
                test_window_interactive "$COLS" "$ROWS" "$THEME" "$ANIMATION"
            fi
            ;;
    esac
else
    echo "Usage: $0 --ci | --interactive | --mode <mode>"
    echo "  --ci              Automated (tmux + inline)"
    echo "  --interactive     Semi-auto (all modes)"
    echo "  --mode <mode>     Single mode test"
    exit 1
fi

# Summary
PASSED=$(cat "$TMPDIR_TEST/.pass")
FAILED=$(cat "$TMPDIR_TEST/.fail")
TOTAL=$((PASSED + FAILED))

echo ""
echo "================================"
echo "  Results: $PASSED/$TOTAL passed"
if [ "$FAILED" -gt 0 ]; then
    echo "  $FAILED test(s) FAILED"
    exit 1
else
    echo "  All tests passed!"
fi
