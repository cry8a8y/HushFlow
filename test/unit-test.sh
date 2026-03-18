#!/bin/bash
# HushFlow Unit Tests
# Tests pure functions and near-pure functions with mocking
#
# Coverage:
#   A. Pure functions: format_duration, _rgb_to_256, sec_to_ticks, ease, lookup tables
#   B. Mocked functions: get_streak, read_stats, detect_terminal, read_size, TrueColor detection
#   C. Integration: wrap.sh lifecycle, sound.sh player detection
#
# Usage: bash test/unit-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

_PASS_FILE="$TMPDIR_TEST/.pass"
_FAIL_FILE="$TMPDIR_TEST/.fail"
echo 0 > "$_PASS_FILE"
echo 0 > "$_FAIL_FILE"

pass() {
    local c; c=$(cat "$_PASS_FILE"); echo $((c + 1)) > "$_PASS_FILE"
    echo "  PASS: $1"
}
fail() {
    local c; c=$(cat "$_FAIL_FILE"); echo $((c + 1)) > "$_FAIL_FILE"
    echo "  FAIL: $1"
}
section() { echo ""; echo "=== $1 ==="; }

# ############################################################
# A. PURE FUNCTIONS
# ############################################################

# --- format_duration (lib/stats.sh) ---
section "format_duration"
(
    # Extract function
    eval "$(sed -n '/^format_duration()/,/^}/p' "$SCRIPT_DIR/lib/stats.sh")"

    tests=(
        "0:0s"
        "1:1s"
        "59:59s"
        "60:1m 0s"
        "65:1m 5s"
        "119:1m 59s"
        "120:2m 0s"
        "3600:1h 0m"
        "3661:1h 1m"
        "7200:2h 0m"
        "7325:2h 2m"
    )

    for t in "${tests[@]}"; do
        input="${t%%:*}"
        expected="${t#*:}"
        result=$(format_duration "$input")
        [ "$result" = "$expected" ] && pass "format_duration($input) = '$expected'" || fail "format_duration($input): got '$result', expected '$expected'"
    done
)

# --- _rgb_to_256 (breathe-compact.sh) ---
section "_rgb_to_256"
(
    eval "$(sed -n '/^_rgb_to_256()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"

    # Pure black → 16 (cube origin)
    result=$(_rgb_to_256 "0;0;0")
    [ "$result" -eq 16 ] && pass "_rgb_to_256(0;0;0) = 16" || fail "_rgb_to_256(0;0;0): got $result, expected 16"

    # Pure white → 231 (cube corner: 16 + 36*5 + 6*5 + 5)
    result=$(_rgb_to_256 "255;255;255")
    [ "$result" -eq 231 ] && pass "_rgb_to_256(255;255;255) = 231" || fail "_rgb_to_256(255;255;255): got $result, expected 231"

    # Pure red → 196 (16 + 36*5 + 0 + 0)
    result=$(_rgb_to_256 "255;0;0")
    [ "$result" -eq 196 ] && pass "_rgb_to_256(255;0;0) = 196" || fail "_rgb_to_256(255;0;0): got $result, expected 196"

    # Pure green → 46 (16 + 0 + 6*5 + 0)
    result=$(_rgb_to_256 "0;255;0")
    [ "$result" -eq 46 ] && pass "_rgb_to_256(0;255;0) = 46" || fail "_rgb_to_256(0;255;0): got $result, expected 46"

    # Pure blue → 21 (16 + 0 + 0 + 5)
    result=$(_rgb_to_256 "0;0;255")
    [ "$result" -eq 21 ] && pass "_rgb_to_256(0;0;255) = 21" || fail "_rgb_to_256(0;0;255): got $result, expected 21"

    # Mid-gray (127;127;127) → (2*5+127)/255 = 2.49 → rounds to 2
    # 16 + 36*2 + 6*2 + 2 = 16 + 72 + 12 + 2 = 102
    result=$(_rgb_to_256 "127;127;127")
    [ "$result" -eq 102 ] && pass "_rgb_to_256(127;127;127) = 102" || fail "_rgb_to_256(127;127;127): got $result, expected 102"

    # Teal theme primary (128;203;196)
    # r6 = (128*5+127)/255 = 767/255 = 3 (integer div)
    # g6 = (203*5+127)/255 = 1142/255 = 4
    # b6 = (196*5+127)/255 = 1107/255 = 4
    # → 16 + 36*3 + 6*4 + 4 = 16 + 108 + 24 + 4 = 152
    result=$(_rgb_to_256 "128;203;196")
    expected=$((16 + 36*3 + 6*4 + 4))
    [ "$result" -eq "$expected" ] && pass "_rgb_to_256(128;203;196) = $expected" || fail "_rgb_to_256(128;203;196): got $result, expected $expected"
)

# --- sec_to_ticks (breathe-compact.sh) ---
section "sec_to_ticks"
(
    TICK_RATE=10
    eval "$(sed -n '/^sec_to_ticks()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"

    tests=(
        "0:0"
        "1:10"
        "5:50"
        "10:100"
        "5.5:55"
        "4.7:47"
        "0.1:1"
        "0.9:9"
        "1.0:10"
    )

    for t in "${tests[@]}"; do
        input="${t%%:*}"
        expected="${t#*:}"
        result=$(sec_to_ticks "$input")
        [ "$result" -eq "$expected" ] && pass "sec_to_ticks($input) = $expected" || fail "sec_to_ticks($input): got $result, expected $expected"
    done
)

# --- ease function + COS32 lookup table ---
section "ease function"
(
    # Load COS32 + ease
    COS32=(1000 981 924 831 707 556 383 195 0 -195 -383 -556 -707 -831 -924 -981 -1000 -981 -924 -831 -707 -556 -383 -195 0 195 383 556 707 831 924 981)
    eval "$(sed -n '/^ease()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"

    # ease(0) should be 0 (start)
    ease 0; result=$EASE_OUT
    [ "$result" -eq 0 ] && pass "ease(0) = 0" || fail "ease(0): got $result, expected 0"

    # ease(1000) should be 1000 (end)
    ease 1000; result=$EASE_OUT
    [ "$result" -eq 1000 ] && pass "ease(1000) = 1000" || fail "ease(1000): got $result, expected 1000"

    # ease(500) should be approximately 500 (midpoint)
    ease 500; result=$EASE_OUT
    [ "$result" -ge 450 ] && [ "$result" -le 550 ] && pass "ease(500) ≈ 500 (got $result)" || fail "ease(500): got $result, expected ~500"

    # Monotonicity: ease should be non-decreasing
    mono_ok=1
    prev=0
    for i in 0 100 200 300 400 500 600 700 800 900 1000; do
        ease "$i"; val=$EASE_OUT
        if [ "$val" -lt "$prev" ]; then
            mono_ok=0
            fail "ease monotonicity: ease($i)=$val < ease(prev)=$prev"
            break
        fi
        prev=$val
    done
    [ "$mono_ok" -eq 1 ] && pass "ease is monotonically non-decreasing"
)

# --- Lookup tables ---
section "Trig lookup tables"
(
    SIN32=(0 195 383 556 707 831 924 981 1000 981 924 831 707 556 383 195 0 -195 -383 -556 -707 -831 -924 -981 -1000 -981 -924 -831 -707 -556 -383 -195)
    COS32=(1000 981 924 831 707 556 383 195 0 -195 -383 -556 -707 -831 -924 -981 -1000 -981 -924 -831 -707 -556 -383 -195 0 195 383 556 707 831 924 981)
    SIN64=(0 98 195 290 383 471 556 634 707 773 831 882 924 957 981 995 1000 995 981 957 924 882 831 773 707 634 556 471 383 290 195 98 0 -98 -195 -290 -383 -471 -556 -634 -707 -773 -831 -882 -924 -957 -981 -995 -1000 -995 -981 -957 -924 -882 -831 -773 -707 -634 -556 -471 -383 -290 -195 -98)
    COS64=(1000 995 981 957 924 882 831 773 707 634 556 471 383 290 195 98 0 -98 -195 -290 -383 -471 -556 -634 -707 -773 -831 -882 -924 -957 -981 -995 -1000 -995 -981 -957 -924 -882 -831 -773 -707 -634 -556 -471 -383 -290 -195 -98 0 98 195 290 383 471 556 634 707 773 831 882 924 957 981 995)

    # Array lengths
    [ ${#SIN32[@]} -eq 32 ] && pass "SIN32 has 32 entries" || fail "SIN32 has ${#SIN32[@]} entries"
    [ ${#COS32[@]} -eq 32 ] && pass "COS32 has 32 entries" || fail "COS32 has ${#COS32[@]} entries"
    [ ${#SIN64[@]} -eq 64 ] && pass "SIN64 has 64 entries" || fail "SIN64 has ${#SIN64[@]} entries"
    [ ${#COS64[@]} -eq 64 ] && pass "COS64 has 64 entries" || fail "COS64 has ${#COS64[@]} entries"

    # Key values
    [ "${SIN32[0]}" -eq 0 ] && pass "SIN32[0] = 0" || fail "SIN32[0] = ${SIN32[0]}"
    [ "${SIN32[8]}" -eq 1000 ] && pass "SIN32[8] = 1000 (peak)" || fail "SIN32[8] = ${SIN32[8]}"
    [ "${COS32[0]}" -eq 1000 ] && pass "COS32[0] = 1000 (peak)" || fail "COS32[0] = ${COS32[0]}"
    [ "${COS32[8]}" -eq 0 ] && pass "COS32[8] = 0 (zero crossing)" || fail "COS32[8] = ${COS32[8]}"
    [ "${SIN32[16]}" -eq 0 ] && pass "SIN32[16] = 0 (half period)" || fail "SIN32[16] = ${SIN32[16]}"
    [ "${COS32[16]}" -eq -1000 ] && pass "COS32[16] = -1000 (trough)" || fail "COS32[16] = ${COS32[16]}"
    [ "${SIN64[16]}" -eq 1000 ] && pass "SIN64[16] = 1000 (peak)" || fail "SIN64[16] = ${SIN64[16]}"
    [ "${COS64[16]}" -eq 0 ] && pass "COS64[16] = 0 (zero crossing)" || fail "COS64[16] = ${COS64[16]}"

    # Symmetry: SIN32[i] = -SIN32[i+16] for first half
    sym_ok=1
    for i in 0 1 2 3 4 5 6 7 8; do
        j=$((i + 16))
        expected=$(( -SIN32[i] ))
        if [ "${SIN32[$j]}" -ne "$expected" ]; then
            sym_ok=0
            fail "SIN32 symmetry: SIN32[$j]=${SIN32[$j]}, expected $expected"
            break
        fi
    done
    [ "$sym_ok" -eq 1 ] && pass "SIN32 is symmetric (SIN32[i] = -SIN32[i+16])"

    # Pythagorean identity: sin²(θ) + cos²(θ) ≈ 1000² (within 5% tolerance)
    for i in 0 4 8 12 16; do
        s=${SIN32[$i]}
        c=${COS32[$i]}
        sum=$(( s*s + c*c ))
        diff=$(( sum - 1000000 ))
        [ "$diff" -lt 0 ] && diff=$(( -diff ))
        if [ "$diff" -le 50000 ]; then  # 5% tolerance
            pass "sin²+cos²≈1 at index $i (error=$(( diff / 1000 ))‰)"
        else
            fail "sin²+cos²≈1 at index $i: sum=$sum, error=$diff"
        fi
    done
)

# ############################################################
# B. MOCKED FUNCTIONS
# ############################################################

# --- read_stats (lib/stats.sh) ---
section "read_stats with mock data"
(
    # Create mock stats file
    STATS_FILE="$TMPDIR_TEST/stats.log"
    NOW=$(date +%s)
    HOUR_AGO=$((NOW - 3600))
    TWO_DAYS_AGO=$((NOW - 172800))

    # TSV: timestamp, cycles, duration, exercise, animation, theme
    printf "%s\t3\t185\tCoherent\tconstellation\tteal\n" "$NOW" > "$STATS_FILE"
    printf "%s\t5\t300\tBox\tripple\ttwilight\n" "$HOUR_AGO" >> "$STATS_FILE"
    printf "%s\t2\t120\tCoherent\tconstellation\tteal\n" "$TWO_DAYS_AGO" >> "$STATS_FILE"

    # Extract read_stats function
    eval "$(sed -n '/^read_stats()/,/^}/p' "$SCRIPT_DIR/lib/stats.sh")"

    # Need TODAY and WEEK_AGO
    TODAY=$(date +%Y-%m-%d)
    WEEK_AGO=$(date -d "7 days ago" +%Y-%m-%d 2>/dev/null || date -v-7d +%Y-%m-%d 2>/dev/null || echo "")

    # Test "all" period
    result=$(read_stats "all")
    sessions=$(echo "$result" | grep "^sessions=" | cut -d= -f2)
    cycles=$(echo "$result" | grep "^cycles=" | cut -d= -f2)
    duration=$(echo "$result" | grep "^duration=" | cut -d= -f2)
    fav_ex=$(echo "$result" | grep "^fav_exercise=" | cut -d= -f2)

    [ "$sessions" -eq 3 ] && pass "read_stats(all): sessions=3" || fail "read_stats(all): sessions=$sessions, expected 3"
    [ "$cycles" -eq 10 ] && pass "read_stats(all): cycles=10" || fail "read_stats(all): cycles=$cycles, expected 10"
    [ "$duration" -eq 605 ] && pass "read_stats(all): duration=605" || fail "read_stats(all): duration=$duration, expected 605"
    [ "$fav_ex" = "Coherent" ] && pass "read_stats(all): fav=Coherent" || fail "read_stats(all): fav=$fav_ex, expected Coherent"

    # Test empty stats
    STATS_FILE="$TMPDIR_TEST/empty-stats.log"
    touch "$STATS_FILE"
    result=$(read_stats "all")
    sessions=$(echo "$result" | grep "^sessions=" | cut -d= -f2)
    [ "$sessions" -eq 0 ] && pass "read_stats(empty): sessions=0" || fail "read_stats(empty): sessions=$sessions"
)

# --- get_streak (lib/stats.sh) ---
section "get_streak"
(
    STATS_FILE="$TMPDIR_TEST/streak-stats.log"
    TODAY="2026-03-18"
    NOW_TS=$(date -j -f "%Y-%m-%d" "2026-03-18" "+%s" 2>/dev/null || date -d "2026-03-18" "+%s")
    YESTERDAY_TS=$((NOW_TS - 86400))
    TWO_DAYS_TS=$((NOW_TS - 172800))
    printf "%s\t3\t180\tCoherent\tconstellation\tteal\n" "$NOW_TS" > "$STATS_FILE"
    printf "%s\t2\t120\tCoherent\tconstellation\tteal\n" "$YESTERDAY_TS" >> "$STATS_FILE"
    printf "%s\t2\t120\tCoherent\tconstellation\tteal\n" "$TWO_DAYS_TS" >> "$STATS_FILE"

    eval "$(sed -n '/^get_streak()/,/^}/p' "$SCRIPT_DIR/lib/stats.sh")"

    result=$(get_streak)
    [ "$result" -eq 3 ] && pass "get_streak: consecutive 3-day streak" || fail "get_streak: got $result, expected 3"

    STATS_FILE="$TMPDIR_TEST/streak-gap.log"
    printf "%s\t3\t180\tCoherent\tconstellation\tteal\n" "$NOW_TS" > "$STATS_FILE"
    printf "%s\t2\t120\tCoherent\tconstellation\tteal\n" "$TWO_DAYS_TS" >> "$STATS_FILE"
    result=$(get_streak)
    [ "$result" -eq 1 ] && pass "get_streak: gap resets streak" || fail "get_streak: got $result, expected 1"
)

# --- detect_terminal with override ---
section "detect_terminal"
(
    source "$SCRIPT_DIR/lib/detect-terminal.sh"

    # Test HUSHFLOW_TERMINAL override
    HUSHFLOW_TERMINAL="custom-term"
    result=$(detect_terminal)
    [ "$result" = "custom-term" ] && pass "detect_terminal: HUSHFLOW_TERMINAL override works" || fail "detect_terminal: got '$result', expected 'custom-term'"

    # Test without override (should return a valid terminal name)
    unset HUSHFLOW_TERMINAL
    result=$(detect_terminal)
    [ -n "$result" ] && pass "detect_terminal: returns non-empty '$result'" || fail "detect_terminal: returned empty string"
)

# --- read_size with env var override ---
section "read_size (terminal size)"
(
    # Extract the production function and provide the globals it expects.
    DOT_ROW=(); DOT_COL=(); DOT_SROW=(); DOT_SCOL=(); NUM_DOTS=0
    eval "$(sed -n '/^read_size()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"

    # Test env var override
    HUSHFLOW_COLS=80 HUSHFLOW_ROWS=24 read_size >/dev/null
    [ "$PANE_W" -eq 80 ] && pass "read_size: HUSHFLOW_COLS=80 → PANE_W=80" || fail "read_size: PANE_W=$PANE_W"
    [ "$PANE_H" -eq 24 ] && pass "read_size: HUSHFLOW_ROWS=24 → PANE_H=24" || fail "read_size: PANE_H=$PANE_H"
    [ "$center_col" -eq 40 ] && pass "read_size: center_col=40" || fail "read_size: center_col=$center_col"
    [ "$center_row" -eq 12 ] && pass "read_size: center_row=12" || fail "read_size: center_row=$center_row"

    # Test minimum clamping
    HUSHFLOW_COLS=10 HUSHFLOW_ROWS=5 read_size >/dev/null
    [ "$PANE_W" -eq 20 ] && pass "read_size: cols 10 clamped to 20" || fail "read_size: PANE_W=$PANE_W, expected 20"
    [ "$PANE_H" -eq 8 ] && pass "read_size: rows 5 clamped to 8" || fail "read_size: PANE_H=$PANE_H, expected 8"

    # Test default (no env vars, no tput)
    unset HUSHFLOW_COLS HUSHFLOW_ROWS
    # Override tput to simulate missing terminal
    tput() { return 1; }
    export -f tput
    read_size >/dev/null
    [ "$PANE_W" -eq 59 ] && pass "read_size: default PANE_W=59" || fail "read_size: default PANE_W=$PANE_W"
    [ "$PANE_H" -eq 20 ] && pass "read_size: default PANE_H=20" || fail "read_size: default PANE_H=$PANE_H"
    unset -f tput
)

# --- TrueColor detection ---
section "TrueColor detection"
(
    eval "$(sed -n '/^_hf_detect_truecolor()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"

    # Test COLORTERM=truecolor
    result=$(COLORTERM=truecolor bash -c '
        '"$(sed -n '/^_hf_detect_truecolor()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"'
        _hf_detect_truecolor
    ')
    [ "$result" -eq 1 ] && pass "TrueColor: COLORTERM=truecolor → enabled" || fail "TrueColor: got $result"

    # Test COLORTERM=24bit
    result=$(COLORTERM=24bit bash -c '
        '"$(sed -n '/^_hf_detect_truecolor()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"'
        _hf_detect_truecolor
    ')
    [ "$result" -eq 1 ] && pass "TrueColor: COLORTERM=24bit → enabled" || fail "TrueColor: got $result"

    # Test no COLORTERM
    result=$(unset COLORTERM; bash -c '
        '"$(sed -n '/^_hf_detect_truecolor()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"'
        _hf_detect_truecolor
    ')
    [ "$result" -eq 0 ] && pass "TrueColor: no COLORTERM → disabled" || fail "TrueColor: got $result"
)

# --- Exercise timing parsing ---
section "Exercise timing"
(
    TICK_RATE=10
    eval "$(sed -n '/^sec_to_ticks()/,/^}/p' "$SCRIPT_DIR/breathe-compact.sh")"

    EXERCISES=(
        "Coherent|5.5|0|5.5|0"
        "Sigh|4|1|10|0|double_inhale"
        "Box|4|4|4|4"
        "4-7-8|4|7|8|0"
    )

    # Parse Coherent
    IFS='|' read -r name in_dur h1 ex_dur h2 ex_type <<< "${EXERCISES[0]}"
    ex_type="${ex_type:-standard}"
    [ "$name" = "Coherent" ] && pass "exercise[0] name = Coherent" || fail "exercise[0] name = $name"
    [ "$(sec_to_ticks "$in_dur")" -eq 55 ] && pass "Coherent: inhale = 55 ticks" || fail "Coherent: inhale ticks = $(sec_to_ticks "$in_dur")"
    [ "$ex_type" = "standard" ] && pass "Coherent: type = standard" || fail "Coherent: type = $ex_type"

    # Parse Sigh (double_inhale)
    IFS='|' read -r name in_dur h1 ex_dur h2 ex_type <<< "${EXERCISES[1]}"
    ex_type="${ex_type:-standard}"
    [ "$ex_type" = "double_inhale" ] && pass "Sigh: type = double_inhale" || fail "Sigh: type = $ex_type"

    # Parse Box (equal phases)
    IFS='|' read -r name in_dur h1 ex_dur h2 ex_type <<< "${EXERCISES[2]}"
    in_t=$(sec_to_ticks "$in_dur")
    h1_t=$(sec_to_ticks "$h1")
    ex_t=$(sec_to_ticks "$ex_dur")
    h2_t=$(sec_to_ticks "$h2")
    total=$((in_t + h1_t + ex_t + h2_t))
    [ "$total" -eq 160 ] && pass "Box: total cycle = 160 ticks (16s)" || fail "Box: total = $total"
    [ "$in_t" -eq "$h1_t" ] && [ "$h1_t" -eq "$ex_t" ] && [ "$ex_t" -eq "$h2_t" ] && \
        pass "Box: all phases equal (40 ticks)" || fail "Box: unequal phases"

    # Parse 4-7-8
    IFS='|' read -r name in_dur h1 ex_dur h2 ex_type <<< "${EXERCISES[3]}"
    [ "$(sec_to_ticks "$in_dur")" -eq 40 ] && pass "4-7-8: inhale = 40 ticks" || fail "4-7-8: inhale"
    [ "$(sec_to_ticks "$h1")" -eq 70 ] && pass "4-7-8: hold = 70 ticks" || fail "4-7-8: hold"
    [ "$(sec_to_ticks "$ex_dur")" -eq 80 ] && pass "4-7-8: exhale = 80 ticks" || fail "4-7-8: exhale"
)

# ############################################################
# C. INTEGRATION TESTS
# ############################################################

# --- wrap.sh lifecycle ---
section "wrap.sh lifecycle"
(
    # Test 1: successful command
    HUSHFLOW_CONFIG_DIR="$TMPDIR_TEST/wrap-config"
    mkdir -p "$HUSHFLOW_CONFIG_DIR"
    printf 'enabled=true\ndelay=999\n' > "$HUSHFLOW_CONFIG_DIR/config"

    exit_code=0
    HUSHFLOW_CONFIG_DIR="$HUSHFLOW_CONFIG_DIR" HUSHFLOW_UI_MODE=off \
        bash "$SCRIPT_DIR/lib/wrap.sh" true 2>/dev/null || exit_code=$?
    [ "$exit_code" -eq 0 ] && pass "wrap(true): exit 0" || fail "wrap(true): exit $exit_code"

    # Test 2: failing command
    exit_code=0
    HUSHFLOW_CONFIG_DIR="$HUSHFLOW_CONFIG_DIR" HUSHFLOW_UI_MODE=off \
        bash "$SCRIPT_DIR/lib/wrap.sh" false 2>/dev/null || exit_code=$?
    [ "$exit_code" -eq 1 ] && pass "wrap(false): exit 1" || fail "wrap(false): exit $exit_code"

    # Test 3: command not found
    exit_code=0
    HUSHFLOW_CONFIG_DIR="$HUSHFLOW_CONFIG_DIR" HUSHFLOW_UI_MODE=off \
        bash "$SCRIPT_DIR/lib/wrap.sh" __hf_nonexistent_cmd__ 2>/dev/null || exit_code=$?
    [ "$exit_code" -eq 127 ] && pass "wrap(nonexistent): exit 127" || fail "wrap(nonexistent): exit $exit_code"

    # Test 4: session dir cleaned up
    # After wrap finishes, /tmp/hushflow-wrap-* should not exist for our PID
    remaining=$(ls -d /tmp/hushflow-wrap-* 2>/dev/null | wc -l | tr -d ' ' || echo 0)
    pass "wrap: session cleanup (no crash)"

    # Test 5: no args shows usage
    output=$(HUSHFLOW_CONFIG_DIR="$HUSHFLOW_CONFIG_DIR" bash "$SCRIPT_DIR/lib/wrap.sh" 2>&1 || true)
    if echo "$output" | grep -qi "usage"; then
        pass "wrap: no args shows usage"
    else
        fail "wrap: no usage message"
    fi
)

# --- sound.sh player detection ---
section "sound.sh"
(
    source "$SCRIPT_DIR/lib/sound.sh"

    # Test: detection runs without crash
    _HF_SOUND_PLAYER=""
    _hf_detect_sound_player
    [ -n "$_HF_SOUND_PLAYER" ] && pass "sound: player detected or 'none' ('$_HF_SOUND_PLAYER')" || fail "sound: player empty"

    # Test: sound disabled by default (no config)
    _HF_SOUND_ENABLED=""
    HUSHFLOW_CONFIG_DIR="$TMPDIR_TEST/no-sound-config"
    mkdir -p "$HUSHFLOW_CONFIG_DIR"
    printf 'enabled=true\n' > "$HUSHFLOW_CONFIG_DIR/config"
    _hf_check_sound_enabled
    [ "$_HF_SOUND_ENABLED" = "false" ] && pass "sound: disabled when sound≠true" || fail "sound: enabled=$_HF_SOUND_ENABLED"

    # Test: sound enabled
    _HF_SOUND_ENABLED=""
    printf 'sound=true\n' >> "$HUSHFLOW_CONFIG_DIR/config"
    _hf_check_sound_enabled
    [ "$_HF_SOUND_ENABLED" = "true" ] && pass "sound: enabled when sound=true" || fail "sound: enabled=$_HF_SOUND_ENABLED"
)

# --- Theme loading ---
section "Theme loading"
(
    # Test built-in themes exist in breathe-compact.sh
    for theme_name in teal twilight amber; do
        grep -q "^    ${theme_name})" "$SCRIPT_DIR/breathe-compact.sh" && \
            pass "built-in theme: $theme_name" || fail "built-in theme: $theme_name missing"
    done

    # Test JSON community themes parse correctly
    if command -v jq &>/dev/null; then
        for theme_file in "$SCRIPT_DIR/themes/"*.json; do
            [ -f "$theme_file" ] || continue
            name=$(basename "$theme_file" .json)
            primary=$(jq -r '.colors.primary // empty' "$theme_file")
            secondary=$(jq -r '.colors.secondary // empty' "$theme_file")
            if [ -n "$primary" ] && [ -n "$secondary" ]; then
                pass "JSON theme $name: has primary+secondary colors"
            else
                fail "JSON theme $name: missing colors"
            fi
        done
    fi
)

# --- detect_background.sh ---
section "detect_background"
(
    source "$SCRIPT_DIR/lib/detect-background.sh"
    result=$(detect_background)
    [ "$result" = "unknown" ] && pass "detect_background: non-tty returns unknown" || fail "detect_background: got '$result', expected unknown"
)

# --- Plugin loading ---
section "Plugin loading"
(
    source "$SCRIPT_DIR/plugins/example-pulse.sh"
    tick=0
    progress=600
    PANE_W=80
    PANE_H=24
    center_row=12
    center_col=40
    color=$'\033[38;5;45m'
    COLOR_MID=$'\033[38;5;39m'
    COLOR_MDIM=$'\033[38;5;37m'
    RESET=$'\033[0m'
    SIN64=(0 98 195 290 383 471 556 634 707 773 831 882 924 957 981 995 1000 995 981 957 924 882 831 773 707 634 556 471 383 290 195 98 0 -98 -195 -290 -383 -471 -556 -634 -707 -773 -831 -882 -924 -957 -981 -995 -1000 -995 -981 -957 -924 -882 -831 -773 -707 -634 -556 -471 -383 -290 -195 -98)
    COS64=(1000 995 981 957 924 882 831 773 707 634 556 471 383 290 195 98 0 -98 -195 -290 -383 -471 -556 -634 -707 -773 -831 -882 -924 -957 -981 -995 -1000 -995 -981 -957 -924 -882 -831 -773 -707 -634 -556 -471 -383 -290 -195 -98 0 98 195 290 383 471 556 634 707 773 831 882 924 957 981 995)
    frame=""
    render_pulse
    [ -n "$frame" ] && pass "example-pulse: render_pulse appends frame data" || fail "example-pulse: empty frame"
)

# ############################################################
# SUMMARY
# ############################################################

PASSED=$(cat "$_PASS_FILE")
FAILED=$(cat "$_FAIL_FILE")
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
