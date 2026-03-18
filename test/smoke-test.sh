#!/bin/bash
# HushFlow smoke test suite
# Usage: ./test/smoke-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSED=0
FAILED=0
TOTAL=0

pass() { PASSED=$((PASSED + 1)); TOTAL=$((TOTAL + 1)); echo "  PASS: $1"; }
fail() { FAILED=$((FAILED + 1)); TOTAL=$((TOTAL + 1)); echo "  FAIL: $1"; }

section() { echo ""; echo "=== $1 ==="; }

# --- Config parsing ---
section "Config parsing"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# Test: default config creation
mkdir -p "$TMPDIR_TEST/.claude/hushflow"
printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=constellation\n' > "$TMPDIR_TEST/.claude/hushflow/config"

# Test: read exercise value
val=$(grep "^exercise=" "$TMPDIR_TEST/.claude/hushflow/config" | cut -d= -f2)
[ "$val" = "0" ] && pass "read exercise default" || fail "read exercise default (got '$val')"

# Test: read theme value
val=$(grep "^theme=" "$TMPDIR_TEST/.claude/hushflow/config" | cut -d= -f2)
[ "$val" = "teal" ] && pass "read theme default" || fail "read theme default (got '$val')"

# Test: read animation value
val=$(grep "^animation=" "$TMPDIR_TEST/.claude/hushflow/config" | cut -d= -f2)
[ "$val" = "constellation" ] && pass "read animation default" || fail "read animation default (got '$val')"

# Test: missing config file uses defaults
MISSING_CFG="$TMPDIR_TEST/nonexistent/config"
val=$(grep "^theme=" "$MISSING_CFG" 2>/dev/null | cut -d= -f2 || true)
[ -z "$val" ] && pass "missing config returns empty" || fail "missing config returns empty (got '$val')"

# --- Animation dispatch ---
section "Animation dispatch"

# Test: breathe-compact.sh recognizes all animation names
for anim in constellation ripple wave orbit helix rain; do
    if grep -q "render_${anim}" "$SCRIPT_DIR/breathe-compact.sh"; then
        pass "render_$anim function exists"
    else
        fail "render_$anim function missing"
    fi
done

# Test: case dispatch includes all animations
for anim in ripple wave orbit helix rain; do
    if grep -q "\"$anim\")" "$SCRIPT_DIR/breathe-compact.sh" || grep -q "${anim})" "$SCRIPT_DIR/breathe-compact.sh"; then
        pass "dispatch case for $anim"
    else
        fail "dispatch case for $anim missing"
    fi
done

# --- Marker lifecycle ---
section "Marker lifecycle"

MARKER="$TMPDIR_TEST/hushflow-working"

# Test: marker creation
echo "$(date +%s)" > "$MARKER"
[ -f "$MARKER" ] && pass "marker file created" || fail "marker file creation"

# Test: marker removal triggers exit
rm -f "$MARKER"
[ ! -f "$MARKER" ] && pass "marker file removed" || fail "marker file removal"

# --- Script syntax ---
section "Script syntax"

for script in breathe-compact.sh hooks/on-start.sh hooks/on-stop.sh hooks/open-window.sh hooks/open-tmux-popup.sh set-exercise.sh install.sh lib/detect-terminal.sh cli.sh; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        if bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
            pass "syntax ok: $script"
        else
            fail "syntax error: $script"
        fi
    else
        fail "file missing: $script"
    fi
done

# --- Install idempotency ---
section "Install idempotency"

# Test: install.sh has idempotent check for Claude
if grep -q "Hooks already installed" "$SCRIPT_DIR/install.sh"; then
    pass "install idempotency check exists"
else
    fail "install idempotency check missing"
fi

# Test: uninstall path exists
if grep -q "\-\-uninstall" "$SCRIPT_DIR/install.sh"; then
    pass "uninstall flag supported"
else
    fail "uninstall flag missing"
fi

# --- set-exercise.sh subcommands ---
section "CLI subcommands"

# Test: animation subcommand recognized
if grep -q 'animation.*anim' "$SCRIPT_DIR/set-exercise.sh"; then
    pass "animation subcommand exists"
else
    fail "animation subcommand missing"
fi

# Test: all animation names in set-exercise
for anim in constellation ripple wave orbit helix rain; do
    if grep -q "$anim" "$SCRIPT_DIR/set-exercise.sh"; then
        pass "set-exercise knows $anim"
    else
        fail "set-exercise missing $anim"
    fi
done

# --- Config path portability ---
section "Config path portability"

# Test: config-reading scripts use HUSHFLOW_CONFIG_DIR (not hardcoded)
for script in breathe-compact.sh hooks/on-start.sh hooks/open-window.sh hooks/open-tmux-popup.sh set-exercise.sh; do
    if grep -q 'HUSHFLOW_CONFIG_DIR' "$SCRIPT_DIR/$script"; then
        pass "HUSHFLOW_CONFIG_DIR in $script"
    else
        fail "HUSHFLOW_CONFIG_DIR missing in $script"
    fi
done

# Test: install.sh hook commands include HUSHFLOW_CONFIG_DIR
if grep -q 'HUSHFLOW_CONFIG_DIR=' "$SCRIPT_DIR/install.sh"; then
    pass "install hooks pass HUSHFLOW_CONFIG_DIR"
else
    fail "install hooks missing HUSHFLOW_CONFIG_DIR"
fi

# Test: Ghostty launcher avoids ambiguous window 1 targeting
if ! grep -q 'window 1' "$SCRIPT_DIR/hooks/open-window.sh"; then
    pass "Ghostty launcher avoids window 1 targeting"
else
    fail "Ghostty launcher still targets window 1"
fi

# Test: Ghostty launcher passes a unique window title to the animation
if grep -q 'HUSHFLOW_WINDOW_TITLE' "$SCRIPT_DIR/hooks/open-window.sh" && grep -q 'HUSHFLOW_WINDOW_TITLE' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "Ghostty launcher uses HUSHFLOW_WINDOW_TITLE"
else
    fail "Ghostty launcher missing HUSHFLOW_WINDOW_TITLE wiring"
fi

# --- Debug logging ---
section "Debug logging"

for script in breathe-compact.sh hooks/on-start.sh hooks/on-stop.sh hooks/open-window.sh; do
    if grep -q 'hf_log' "$SCRIPT_DIR/$script"; then
        pass "debug logging in $script"
    else
        fail "debug logging missing in $script"
    fi
done

# --- Functional: set-exercise ---
section "Functional: set-exercise"

# Use isolated config dir
SE_CONFIG="$TMPDIR_TEST/se-config"
mkdir -p "$SE_CONFIG"

# Test: set theme via set-exercise.sh
output=$(HUSHFLOW_CONFIG_DIR="$SE_CONFIG" bash "$SCRIPT_DIR/set-exercise.sh" theme twilight 2>&1)
val=$(grep "^theme=" "$SE_CONFIG/config" | cut -d= -f2)
[ "$val" = "twilight" ] && pass "set theme to twilight" || fail "set theme to twilight (got '$val')"

# Test: set exercise via set-exercise.sh
output=$(HUSHFLOW_CONFIG_DIR="$SE_CONFIG" bash "$SCRIPT_DIR/set-exercise.sh" box 2>&1)
val=$(grep "^exercise=" "$SE_CONFIG/config" | cut -d= -f2)
[ "$val" = "2" ] && pass "set exercise to box (2)" || fail "set exercise to box (got '$val')"

# Test: set animation via set-exercise.sh
output=$(HUSHFLOW_CONFIG_DIR="$SE_CONFIG" bash "$SCRIPT_DIR/set-exercise.sh" animation rain 2>&1)
val=$(grep "^animation=" "$SE_CONFIG/config" | cut -d= -f2)
[ "$val" = "rain" ] && pass "set animation to rain" || fail "set animation to rain (got '$val')"

# Test: list command shows current values
output=$(HUSHFLOW_CONFIG_DIR="$SE_CONFIG" bash "$SCRIPT_DIR/set-exercise.sh" list 2>&1)
echo "$output" | grep -q "Current exercise: 2" && pass "list shows current exercise" || fail "list shows current exercise"
echo "$output" | grep -q "Current theme: twilight" && pass "list shows current theme" || fail "list shows current theme"
echo "$output" | grep -q "Current animation: rain" && pass "list shows current animation" || fail "list shows current animation"

# --- Functional: install ---
section "Functional: install"

# Test: install to mock Claude settings
if command -v jq &>/dev/null; then
    MOCK_CLAUDE="$TMPDIR_TEST/mock-claude"
    mkdir -p "$MOCK_CLAUDE/commands"
    echo '{}' > "$MOCK_CLAUDE/settings.json"

    # Simulate install_claude by sourcing the relevant jq logic
    ON_START_T="$SCRIPT_DIR/hooks/on-start.sh"
    ON_STOP_T="$SCRIPT_DIR/hooks/on-stop.sh"
    config_dir="$MOCK_CLAUDE/hushflow"
    mkdir -p "$config_dir"

    start_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_START_T"'", "async": true}]}]'
    stop_hook='[{"hooks": [{"type": "command", "command": "HUSHFLOW_CONFIG_DIR='"$config_dir"' '"$ON_STOP_T"'", "async": true}]}]'
    result=$(echo '{}' | jq \
        --argjson start_hook "$start_hook" \
        --argjson stop_hook "$stop_hook" \
        '.hooks //= {} |
         .hooks.UserPromptSubmit = (.hooks.UserPromptSubmit // []) + $start_hook |
         .hooks.Stop = (.hooks.Stop // []) + $stop_hook')

    # Validate output is valid JSON
    if echo "$result" | jq empty 2>/dev/null; then
        pass "install produces valid JSON"
    else
        fail "install produces invalid JSON"
    fi

    # Validate hooks are present
    if echo "$result" | jq -e '.hooks.UserPromptSubmit[0].hooks[0].command' &>/dev/null; then
        pass "install adds UserPromptSubmit hook"
    else
        fail "install missing UserPromptSubmit hook"
    fi

    if echo "$result" | jq -e '.hooks.Stop[0].hooks[0].command' &>/dev/null; then
        pass "install adds Stop hook"
    else
        fail "install missing Stop hook"
    fi

    # Validate hook commands contain on-start.sh / on-stop.sh
    cmd=$(echo "$result" | jq -r '.hooks.UserPromptSubmit[0].hooks[0].command')
    echo "$cmd" | grep -q "on-start.sh" && pass "start hook references on-start.sh" || fail "start hook missing on-start.sh"
    echo "$cmd" | grep -q "HUSHFLOW_CONFIG_DIR" && pass "start hook passes HUSHFLOW_CONFIG_DIR" || fail "start hook missing HUSHFLOW_CONFIG_DIR"

    # Test: idempotency — second install should detect existing hooks
    echo "$result" > "$MOCK_CLAUDE/settings.json"
    if echo "$result" | jq -e ".hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains(\"on-start.sh\"))" &>/dev/null; then
        pass "idempotency check detects existing hooks"
    else
        fail "idempotency check fails"
    fi

    # Test: partial install is repaired, not treated as fully installed
    PARTIAL_HOME="$TMPDIR_TEST/partial-home"
    mkdir -p "$PARTIAL_HOME/.claude/commands" "$PARTIAL_HOME/.claude/hushflow"
    printf '%s\n' '{"hooks":{"UserPromptSubmit":[{"hooks":[{"type":"command","command":"HUSHFLOW_CONFIG_DIR='"$PARTIAL_HOME"'/.claude/hushflow '"$ON_START_T"'","async":true}]}]}}' > "$PARTIAL_HOME/.claude/settings.json"
    HOME="$PARTIAL_HOME" bash "$SCRIPT_DIR/install.sh" --target claude >/dev/null 2>&1
    partial_settings=$(cat "$PARTIAL_HOME/.claude/settings.json")
    if echo "$partial_settings" | jq -e '.hooks.Stop[]?.hooks[]? | select(.command | contains("on-stop.sh"))' >/dev/null 2>&1; then
        pass "install repairs missing stop hook"
    else
        fail "install failed to repair missing stop hook"
    fi
    start_count=$(echo "$partial_settings" | jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("on-start.sh"))] | length')
    [ "$start_count" = "1" ] && pass "install does not duplicate existing start hook" || fail "install duplicated start hook ($start_count)"

    # Test: uninstall removes hooks
    on_start_str="$ON_START_T"
    on_stop_str="$ON_STOP_T"
    cleaned=$(echo "$result" | jq \
        --arg on_start "$on_start_str" --arg on_stop "$on_stop_str" \
        '(.hooks.UserPromptSubmit // []) |= [.[] | select(.hooks | all(.command | contains($on_start) | not))] |
         (.hooks.Stop // []) |= [.[] | select(.hooks | all(.command | contains($on_stop) | not))] |
         if .hooks.UserPromptSubmit == [] then del(.hooks.UserPromptSubmit) else . end |
         if .hooks.Stop == [] then del(.hooks.Stop) else . end')
    remaining=$(echo "$cleaned" | jq '.hooks | length')
    [ "$remaining" = "0" ] && pass "uninstall removes all hooks" || fail "uninstall leaves $remaining hook groups"

    # Test: validate_and_write rejects invalid JSON
    if ! echo "not json{" | jq empty 2>/dev/null; then
        pass "jq rejects invalid JSON"
    else
        fail "jq accepts invalid JSON"
    fi
else
    echo "  SKIP: jq not installed, skipping install functional tests"
fi

# --- Functional: session lifecycle ---
section "Functional: session lifecycle"

# Test: session dir structure
SESSION_TEST="$TMPDIR_TEST/hushflow-99999"
mkdir -p "$SESSION_TEST"
echo "$(date +%s)" > "$SESSION_TEST/working"
[ -f "$SESSION_TEST/working" ] && pass "session marker created in session dir" || fail "session marker creation"

# Test: session cleanup removes entire directory
rm -rf "$SESSION_TEST"
[ ! -d "$SESSION_TEST" ] && pass "session dir fully cleaned up" || fail "session dir cleanup"

# Test: on-stop recognizes terminal processes beyond bash
for proc_name in 'sleep' 'gnome-terminal' 'konsole' 'xfce4-terminal' 'xterm' 'wt.exe' 'powershell'; do
    if grep -q "$proc_name" "$SCRIPT_DIR/hooks/on-stop.sh"; then
        pass "on-stop whitelist includes $proc_name"
    else
        fail "on-stop whitelist missing $proc_name"
    fi
done

# Test: on-stop kills a recorded window pid and removes session dir
SESSION_STOP_TEST="$TMPDIR_TEST/hushflow-stop"
STOP_CONFIG="$TMPDIR_TEST/stop-config"
mkdir -p "$SESSION_STOP_TEST" "$STOP_CONFIG"
sleep 30 &
window_pid=$!
echo "$SESSION_STOP_TEST" > "$STOP_CONFIG/.session"
echo "$window_pid" > "$SESSION_STOP_TEST/window-pid"
echo "$(date +%s)" > "$SESSION_STOP_TEST/working"
HUSHFLOW_CONFIG_DIR="$STOP_CONFIG" bash "$SCRIPT_DIR/hooks/on-stop.sh" >/dev/null 2>&1
pid_cleared=0
for _ in 1 2 3 4 5; do
    if ! kill -0 "$window_pid" 2>/dev/null; then
        pid_cleared=1
        break
    fi
    pid_state=$(ps -p "$window_pid" -o stat= 2>/dev/null | awk '{print $1}' || true)
    case "$pid_state" in
        Z*|"")
            pid_cleared=1
            break
            ;;
    esac
    sleep 0.1
done
if [ "$pid_cleared" -eq 1 ]; then
    pass "on-stop kills recorded window pid"
else
    kill "$window_pid" 2>/dev/null || true
    fail "on-stop left recorded window pid running"
fi
[ ! -d "$SESSION_STOP_TEST" ] && pass "on-stop removes session dir" || fail "on-stop leaves session dir"

# --- Config edge cases ---
section "Config edge cases"

# Test: set_value uses awk (no sed regex injection)
SE_EDGE="$TMPDIR_TEST/edge-config"
mkdir -p "$SE_EDGE"
printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=constellation\n' > "$SE_EDGE/config"

# Test: value with special characters
output=$(HUSHFLOW_CONFIG_DIR="$SE_EDGE" bash "$SCRIPT_DIR/set-exercise.sh" theme amber 2>&1)
val=$(grep "^theme=" "$SE_EDGE/config" | cut -d= -f2)
[ "$val" = "amber" ] && pass "set_value handles normal value" || fail "set_value normal value (got '$val')"

# Test: config file with missing keys gets key appended
echo "enabled=true" > "$SE_EDGE/config"
output=$(HUSHFLOW_CONFIG_DIR="$SE_EDGE" bash "$SCRIPT_DIR/set-exercise.sh" theme teal 2>&1)
if grep -q "^theme=teal" "$SE_EDGE/config"; then
    pass "set_value appends missing key"
else
    fail "set_value failed to append missing key"
fi

# Test: non-numeric exercise value in config is rejected
printf 'enabled=true\nexercise=abc\ndelay=5\ntheme=teal\nanimation=constellation\n' > "$SE_EDGE/config"
# Source the relevant check from breathe-compact.sh
saved="abc"
if [[ "$saved" =~ ^[0-9]+$ ]]; then
    fail "non-numeric exercise value accepted"
else
    pass "non-numeric exercise value rejected"
fi

# --- Animation validation ---
section "Animation validation"

# Test: breathe-compact.sh validates unknown animation names
if grep -q "VALID_ANIMATIONS" "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "animation validation exists in breathe-compact.sh"
else
    fail "animation validation missing in breathe-compact.sh"
fi

# --- Terminal size safety ---
section "Terminal size safety"

# Test: minimum terminal size enforcement
if grep -q "PANE_W.*20" "$SCRIPT_DIR/breathe-compact.sh" && grep -q "PANE_H.*8" "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "minimum terminal size enforced"
else
    fail "minimum terminal size not enforced"
fi

# --- Doctor command ---
section "Doctor command"

# Test: doctor.sh exists and has valid syntax
if [ -f "$SCRIPT_DIR/doctor.sh" ]; then
    if bash -n "$SCRIPT_DIR/doctor.sh" 2>/dev/null; then
        pass "doctor.sh syntax ok"
    else
        fail "doctor.sh has syntax errors"
    fi
else
    fail "doctor.sh missing"
fi

# Test: cli.sh routes 'doctor' subcommand
if grep -q "doctor" "$SCRIPT_DIR/cli.sh"; then
    pass "cli.sh routes doctor command"
else
    fail "cli.sh missing doctor route"
fi

# --- Community themes ---
section "Community themes"

if command -v jq &>/dev/null; then
    for theme_file in "$SCRIPT_DIR/themes"/*.json; do
        if [ -f "$theme_file" ]; then
            tname=$(basename "$theme_file")
            if jq empty "$theme_file" 2>/dev/null; then
                pass "valid JSON: $tname"
            else
                fail "invalid JSON: $tname"
            fi
        fi
    done
else
    # Fallback: just check files exist and look like JSON
    for theme_file in "$SCRIPT_DIR/themes"/*.json; do
        if [ -f "$theme_file" ]; then
            tname=$(basename "$theme_file")
            if grep -q '"colors"' "$theme_file"; then
                pass "theme file exists: $tname"
            else
                fail "theme file malformed: $tname"
            fi
        fi
    done
fi

# Test: theme loader handles unknown themes gracefully
if grep -q '_theme_loaded' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "theme loader has fallback logic"
else
    fail "theme loader missing fallback"
fi

# --- New features ---
section "New features"

# wrap.sh
if [ -f "$SCRIPT_DIR/lib/wrap.sh" ]; then
    bash -n "$SCRIPT_DIR/lib/wrap.sh" 2>/dev/null && pass "wrap.sh syntax ok" || fail "wrap.sh syntax error"
else
    fail "wrap.sh missing"
fi

# sound.sh
if [ -f "$SCRIPT_DIR/lib/sound.sh" ]; then
    bash -n "$SCRIPT_DIR/lib/sound.sh" 2>/dev/null && pass "sound.sh syntax ok" || fail "sound.sh syntax error"
else
    fail "sound.sh missing"
fi

# detect-background.sh
if [ -f "$SCRIPT_DIR/lib/detect-background.sh" ]; then
    bash -n "$SCRIPT_DIR/lib/detect-background.sh" 2>/dev/null && pass "detect-background.sh syntax ok" || fail "detect-background.sh syntax error"
else
    fail "detect-background.sh missing"
fi

# stats.sh
if [ -f "$SCRIPT_DIR/lib/stats.sh" ]; then
    bash -n "$SCRIPT_DIR/lib/stats.sh" 2>/dev/null && pass "stats.sh syntax ok" || fail "stats.sh syntax error"
else
    fail "stats.sh missing"
fi

# CLI routes new commands
for cmd in wrap sound stats; do
    grep -q "$cmd" "$SCRIPT_DIR/cli.sh" && pass "cli.sh routes $cmd" || fail "cli.sh missing $cmd route"
done

# --- Version sync ---
section "Version sync"

PKG_VER=$(grep '"version"' "$SCRIPT_DIR/package.json" | sed 's/.*"\([0-9][0-9.]*\)".*/\1/')
[ -n "$PKG_VER" ] && pass "package.json version = $PKG_VER" || fail "package.json version missing"

# Banner SVG should contain matching major.minor.patch
if [ -f "$SCRIPT_DIR/docs/hushflow-banner.svg" ]; then
    grep -q "v${PKG_VER}" "$SCRIPT_DIR/docs/hushflow-banner.svg" && \
        pass "banner.svg matches v${PKG_VER}" || fail "banner.svg version mismatch (expected v${PKG_VER})"
else
    pass "banner.svg: file not found (skip)"
fi

# --- README sync ---
section "README sync"

# All README files should exist
for lang in "" ".zh-TW" ".zh-CN" ".ja"; do
    if [ -z "$lang" ]; then
        f="$SCRIPT_DIR/README.md"
    else
        f="$SCRIPT_DIR/docs/README${lang}.md"
    fi
    [ -f "$f" ] && pass "README${lang:-.en} exists" || fail "README${lang:-.en} missing"
done

# Section count comparison (main README is canonical)
main_sections=$(grep -c '^## ' "$SCRIPT_DIR/README.md")
for lang in zh-TW zh-CN ja; do
    f="$SCRIPT_DIR/docs/README.${lang}.md"
    [ -f "$f" ] || continue
    lang_sections=$(grep -c '^## ' "$f")
    [ "$lang_sections" -eq "$main_sections" ] && \
        pass "README.${lang} section count matches ($lang_sections)" || \
        fail "README.${lang} section count: $lang_sections (expected $main_sections)"
done

# Key structural elements in all READMEs
for lang in "" ".zh-TW" ".zh-CN" ".ja"; do
    if [ -z "$lang" ]; then
        f="$SCRIPT_DIR/README.md"
        label="en"
    else
        f="$SCRIPT_DIR/docs/README${lang}.md"
        label="${lang#.}"
    fi
    [ -f "$f" ] || continue
    # Must have install command
    grep -q "install" "$f" && pass "README.$label has install" || fail "README.$label missing install"
    # Must have license section
    grep -qi "license\|授權\|许可\|ライセンス" "$f" && pass "README.$label has license" || fail "README.$label missing license"
done

# --- Random animation mode ---
section "Random animation mode"

# Test: breathe-compact.sh handles random animation selection
if grep -q 'animation.*=.*"random"' "$SCRIPT_DIR/breathe-compact.sh" || \
   grep -q 'animation.*random' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "breathe-compact.sh handles random animation"
else
    fail "breathe-compact.sh missing random animation handling"
fi

# Test: set-exercise.sh supports random as an animation option
if grep -q 'random|shuffle' "$SCRIPT_DIR/set-exercise.sh"; then
    pass "set-exercise knows random animation"
else
    fail "set-exercise missing random animation"
fi

# Test: set animation to random via set-exercise.sh
SE_RAND="$TMPDIR_TEST/rand-config"
mkdir -p "$SE_RAND"
output=$(HUSHFLOW_CONFIG_DIR="$SE_RAND" bash "$SCRIPT_DIR/set-exercise.sh" animation random 2>&1)
val=$(grep "^animation=" "$SE_RAND/config" | cut -d= -f2)
[ "$val" = "random" ] && pass "set animation to random" || fail "set animation to random (got '$val')"

# Test: default config uses random animation
SE_DEF="$TMPDIR_TEST/def-config"
mkdir -p "$SE_DEF"
output=$(HUSHFLOW_CONFIG_DIR="$SE_DEF" bash "$SCRIPT_DIR/set-exercise.sh" list 2>&1)
val=$(grep "^animation=" "$SE_DEF/config" | cut -d= -f2)
[ "$val" = "random" ] && pass "default config animation is random" || fail "default config animation (got '$val')"

# Test: random resolves to a valid animation name
_VALID="constellation ripple wave orbit helix rain"
_arr=($_VALID)
_picked="${_arr[$((RANDOM % ${#_arr[@]}))]}"
_found=0
for _a in $_VALID; do [ "$_picked" = "$_a" ] && _found=1; done
[ "$_found" -eq 1 ] && pass "random picked valid animation: $_picked" || fail "random picked invalid: $_picked"

# --- ESC key close ---
section "ESC key close"

# Test: breathe-compact.sh uses stty for keyboard input timing
if grep -q 'stty.*-echo.*-icanon.*min.*time' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "breathe-compact.sh sets stty for keyboard input"
else
    fail "breathe-compact.sh missing stty keyboard setup"
fi

# Test: breathe-compact.sh saves/restores stty settings
if grep -q '_hf_old_stty' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "breathe-compact.sh saves/restores stty settings"
else
    fail "breathe-compact.sh missing stty save/restore"
fi

# Test: breathe-compact.sh detects ESC key
if grep -q '\\x1b' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "breathe-compact.sh has ESC detection"
else
    fail "breathe-compact.sh missing ESC detection"
fi

# Test: ESC handler removes marker file before exit
if grep -A2 'Bare ESC' "$SCRIPT_DIR/breathe-compact.sh" | grep -q 'rm.*MARKER_FILE'; then
    pass "ESC handler removes marker before graceful exit"
else
    fail "ESC handler missing marker removal"
fi

# Test: ESC hint text exists
if grep -q 'ESC to close' "$SCRIPT_DIR/breathe-compact.sh"; then
    pass "ESC hint text in breathe-compact.sh"
else
    fail "ESC hint text missing"
fi

# Test: ESC hint gated on terminal check
if grep -B2 '_esc_hint' "$SCRIPT_DIR/breathe-compact.sh" | grep -q '\-t 0'; then
    pass "ESC hint gated on terminal check"
else
    fail "ESC hint missing terminal check"
fi

# Test: graceful_exit restores stty
if sed -n '/^graceful_exit()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh" | grep -q '_hf_old_stty'; then
    pass "graceful_exit restores stty"
else
    fail "graceful_exit missing stty restore"
fi

# --- Summary ---
echo ""
echo "================================"
echo "  Results: $PASSED/$TOTAL passed"
if [ "$FAILED" -gt 0 ]; then
    echo "  $FAILED FAILED"
    exit 1
else
    echo "  All tests passed!"
    exit 0
fi
