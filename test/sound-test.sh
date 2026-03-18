#!/bin/bash
# HushFlow sound system test suite
# Usage: bash test/sound-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSED=0
FAILED=0
TOTAL=0

pass() { PASSED=$((PASSED + 1)); TOTAL=$((TOTAL + 1)); echo "  PASS: $1"; }
fail() { FAILED=$((FAILED + 1)); TOTAL=$((TOTAL + 1)); echo "  FAIL: $1"; }

section() { echo ""; echo "=== $1 ==="; }

# --- Syntax ---
section "Sound system basics"

bash -n "$SCRIPT_DIR/lib/sound.sh" 2>/dev/null && pass "sound.sh syntax ok" || fail "sound.sh syntax error"

# --- Sound config default (sound disabled by default, opt-in) ---
section "Config default behavior"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# Test: missing config = sound disabled
CFG_MISSING="$TMPDIR_TEST/no-config"
mkdir -p "$CFG_MISSING"
result=$( source "$SCRIPT_DIR/lib/sound.sh"; _HF_SOUND_ENABLED=""; HUSHFLOW_CONFIG_DIR="$CFG_MISSING" _hf_check_sound_enabled; echo "$_HF_SOUND_ENABLED" )
[ "$result" = "false" ] && pass "missing config defaults to sound=false" || fail "missing config defaults to sound=false (got '$result')"

# Test: config without sound= line = sound disabled
CFG_NO_SOUND="$TMPDIR_TEST/no-sound-line"
mkdir -p "$CFG_NO_SOUND"
printf 'enabled=true\nexercise=0\n' > "$CFG_NO_SOUND/config"
result=$( source "$SCRIPT_DIR/lib/sound.sh"; _HF_SOUND_ENABLED=""; HUSHFLOW_CONFIG_DIR="$CFG_NO_SOUND" _hf_check_sound_enabled; echo "$_HF_SOUND_ENABLED" )
[ "$result" = "false" ] && pass "config without sound= defaults to false" || fail "config without sound= (got '$result')"

# Test: sound=true = sound enabled (opt-in)
CFG_TRUE="$TMPDIR_TEST/sound-true"
mkdir -p "$CFG_TRUE"
printf 'sound=true\n' > "$CFG_TRUE/config"
result=$( source "$SCRIPT_DIR/lib/sound.sh"; _HF_SOUND_ENABLED=""; HUSHFLOW_CONFIG_DIR="$CFG_TRUE" _hf_check_sound_enabled; echo "$_HF_SOUND_ENABLED" )
[ "$result" = "true" ] && pass "sound=true is enabled" || fail "sound=true (got '$result')"

# Test: sound=false = sound disabled
CFG_FALSE="$TMPDIR_TEST/sound-false"
mkdir -p "$CFG_FALSE"
printf 'sound=false\n' > "$CFG_FALSE/config"
result=$( source "$SCRIPT_DIR/lib/sound.sh"; _HF_SOUND_ENABLED=""; HUSHFLOW_CONFIG_DIR="$CFG_FALSE" _hf_check_sound_enabled; echo "$_HF_SOUND_ENABLED" )
[ "$result" = "false" ] && pass "sound=false is disabled" || fail "sound=false (got '$result')"

# --- Duration-matched files ---
section "Duration-matched sound files"

# Breathing patterns and their required sound files
# Coherent: 5.5-0-5.5-0, Sigh: 4-1-10-0, Box: 4-4-4-4, 4-7-8: 4-7-8-0
REQUIRED_SOUNDS="inhale-5.5s exhale-5.5s inhale-4s hold-1s exhale-10s exhale-4s hold-4s exhale-8s hold-7s inhale-1s"

for name in $REQUIRED_SOUNDS; do
    found=0
    for ext in ogg wav mp3; do
        [ -f "$SCRIPT_DIR/sounds/${name}.${ext}" ] && found=1 && break
    done
    [ "$found" -eq 1 ] && pass "sound file exists: $name" || fail "sound file missing: $name"
done

# Base sound files
for base in inhale exhale hold complete; do
    found=0
    for ext in ogg wav mp3; do
        [ -f "$SCRIPT_DIR/sounds/${base}.${ext}" ] && found=1 && break
    done
    [ "$found" -eq 1 ] && pass "base sound file exists: $base" || fail "base sound file missing: $base"
done

# --- Crossfade logic ---
section "Crossfade implementation"

# Test: sound.sh contains crossfade overlap logic
if grep -q 'old_pid' "$SCRIPT_DIR/lib/sound.sh"; then
    pass "crossfade uses old_pid tracking"
else
    fail "crossfade missing old_pid tracking"
fi

if grep -q 'sleep 0.15' "$SCRIPT_DIR/lib/sound.sh"; then
    pass "crossfade has 150ms overlap delay"
else
    fail "crossfade missing overlap delay"
fi

# Test: new sound starts before old is killed
if grep -B5 'old_pid.*kill' "$SCRIPT_DIR/lib/sound.sh" | grep -q '_HF_SOUND_PID=\$!'; then
    pass "new sound PID set before old kill"
else
    # Check alternative: _HF_SOUND_PID is set, then old_pid kill happens after
    if grep -n '_HF_SOUND_PID=\$!' "$SCRIPT_DIR/lib/sound.sh" | head -1 | cut -d: -f1 | while read new_line; do
        grep -n 'kill.*old_pid' "$SCRIPT_DIR/lib/sound.sh" | head -1 | cut -d: -f1 | while read kill_line; do
            [ "$new_line" -lt "$kill_line" ] && echo "ok"
        done
    done | grep -q "ok"; then
        pass "new sound starts before old is killed (line order)"
    else
        fail "crossfade order unclear"
    fi
fi

# --- Player detection ---
section "Player detection"

# Test: sound.sh checks for all 4 players
for player in ffplay mpv afplay paplay; do
    if grep -q "$player" "$SCRIPT_DIR/lib/sound.sh"; then
        pass "sound.sh detects $player"
    else
        fail "sound.sh missing $player detection"
    fi
done

# Test: player priority order (ffplay > mpv > afplay > paplay)
ffplay_line=$(grep -n 'command -v ffplay' "$SCRIPT_DIR/lib/sound.sh" | head -1 | cut -d: -f1)
mpv_line=$(grep -n 'command -v mpv' "$SCRIPT_DIR/lib/sound.sh" | head -1 | cut -d: -f1)
afplay_line=$(grep -n 'command -v afplay' "$SCRIPT_DIR/lib/sound.sh" | head -1 | cut -d: -f1)
paplay_line=$(grep -n 'command -v paplay' "$SCRIPT_DIR/lib/sound.sh" | head -1 | cut -d: -f1)

if [ "$ffplay_line" -lt "$mpv_line" ] && [ "$mpv_line" -lt "$afplay_line" ] && [ "$afplay_line" -lt "$paplay_line" ]; then
    pass "player detection priority: ffplay > mpv > afplay > paplay"
else
    fail "player detection priority wrong"
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
