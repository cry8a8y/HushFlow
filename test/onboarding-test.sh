#!/bin/bash
# HushFlow Onboarding Tests
# Tests: onboarding flag, config writes, edge cases, on-start.sh integration
#
# Usage: bash test/onboarding-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

PASSED=0
FAILED=0
TOTAL=0

pass() { PASSED=$((PASSED + 1)); TOTAL=$((TOTAL + 1)); echo "  PASS: $1"; }
fail() { FAILED=$((FAILED + 1)); TOTAL=$((TOTAL + 1)); echo "  FAIL: $1"; }
section() { echo ""; echo "=== $1 ==="; }

# ############################################################
# A. ONBOARDING FLAG TESTS
# ############################################################

section "Onboarding flag detection"

# Test: without .onboarded, onboarding.sh should run (non-interactive → auto-complete)
cfg="$TMPDIR_TEST/flag-test-1"
mkdir -p "$cfg"
HUSHFLOW_CONFIG_DIR="$cfg" bash "$SCRIPT_DIR/onboarding.sh" </dev/null 2>/dev/null
[ -f "$cfg/.onboarded" ] && pass "non-interactive creates .onboarded" || fail "non-interactive creates .onboarded"

# Test: non-interactive creates default config
[ -f "$cfg/config" ] && pass "non-interactive creates config" || fail "non-interactive creates config"

# Test: with .onboarded, onboarding.sh can still be run manually (non-interactive)
cfg2="$TMPDIR_TEST/flag-test-2"
mkdir -p "$cfg2"
touch "$cfg2/.onboarded"
printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=random\nsound=false\n' > "$cfg2/config"
HUSHFLOW_CONFIG_DIR="$cfg2" bash "$SCRIPT_DIR/onboarding.sh" </dev/null 2>/dev/null
[ -f "$cfg2/.onboarded" ] && pass "manual re-run with existing .onboarded" || fail "manual re-run with existing .onboarded"

# Test: CLI routes to onboarding
out=$(bash "$SCRIPT_DIR/cli.sh" onboarding </dev/null 2>/dev/null; echo "EXIT:$?")
[[ "$out" == *"EXIT:0"* ]] && pass "cli.sh onboarding routes correctly" || fail "cli.sh onboarding routes correctly"

# ############################################################
# B. CONFIG WRITE TESTS
# ############################################################

section "Config writes (non-interactive defaults)"

# Test: non-interactive onboarding creates valid config
cfg3="$TMPDIR_TEST/config-test-1"
mkdir -p "$cfg3"
HUSHFLOW_CONFIG_DIR="$cfg3" bash "$SCRIPT_DIR/onboarding.sh" </dev/null 2>/dev/null

val=$(grep "^exercise=" "$cfg3/config" 2>/dev/null | cut -d= -f2)
[ -n "$val" ] && pass "exercise value set in config" || fail "exercise value set in config"

val=$(grep "^theme=" "$cfg3/config" 2>/dev/null | cut -d= -f2)
[ -n "$val" ] && pass "theme value set in config" || fail "theme value set in config"

val=$(grep "^enabled=" "$cfg3/config" 2>/dev/null | cut -d= -f2)
[ "$val" = "true" ] && pass "enabled=true in default config" || fail "enabled=true in default config"

# Test: simulated exercise choice via stdin (exercise 2 = box)
# HUSHFLOW_FORCE_INTERACTIVE=1 bypasses the [ -t 0 ] check for piped input testing
cfg4="$TMPDIR_TEST/config-test-2"
mkdir -p "$cfg4"
# Pipe: Enter (welcome) → 3 (box) → Enter (theme default) → empty
printf '\n3\n\n' | HUSHFLOW_CONFIG_DIR="$cfg4" HUSHFLOW_FORCE_INTERACTIVE=1 bash "$SCRIPT_DIR/onboarding.sh" 2>/dev/null || true
if [ -f "$cfg4/config" ]; then
    val=$(grep "^exercise=" "$cfg4/config" 2>/dev/null | cut -d= -f2)
    [ "$val" = "2" ] && pass "exercise=2 when choosing box (3)" || fail "exercise=2 when choosing box (3), got '$val'"
else
    fail "config file not created with piped input"
fi

# Test: simulated theme choice via stdin (theme twilight)
cfg5="$TMPDIR_TEST/config-test-3"
mkdir -p "$cfg5"
printf '\n1\n2\n' | HUSHFLOW_CONFIG_DIR="$cfg5" HUSHFLOW_FORCE_INTERACTIVE=1 bash "$SCRIPT_DIR/onboarding.sh" 2>/dev/null || true
if [ -f "$cfg5/config" ]; then
    val=$(grep "^theme=" "$cfg5/config" 2>/dev/null | cut -d= -f2)
    [ "$val" = "twilight" ] && pass "theme=twilight when choosing 2" || fail "theme=twilight when choosing 2, got '$val'"
else
    fail "config file not created with piped theme input"
fi

# Test: default values (all Enter)
cfg6="$TMPDIR_TEST/config-test-4"
mkdir -p "$cfg6"
printf '\n\n\n' | HUSHFLOW_CONFIG_DIR="$cfg6" HUSHFLOW_FORCE_INTERACTIVE=1 bash "$SCRIPT_DIR/onboarding.sh" 2>/dev/null || true
if [ -f "$cfg6/config" ]; then
    ex_val=$(grep "^exercise=" "$cfg6/config" 2>/dev/null | cut -d= -f2)
    th_val=$(grep "^theme=" "$cfg6/config" 2>/dev/null | cut -d= -f2)
    [ "$ex_val" = "0" ] && pass "default exercise=0" || fail "default exercise=0, got '$ex_val'"
    [ "$th_val" = "teal" ] && pass "default theme=teal" || fail "default theme=teal, got '$th_val'"
else
    fail "config file not created with default input"
fi

# ############################################################
# C. EDGE CASES
# ############################################################

section "Edge cases"

# Test: non-interactive terminal ([ -t 0 ] = false) → skip wizard, touch .onboarded
cfg_edge1="$TMPDIR_TEST/edge-1"
mkdir -p "$cfg_edge1"
HUSHFLOW_CONFIG_DIR="$cfg_edge1" bash "$SCRIPT_DIR/onboarding.sh" </dev/null 2>/dev/null
[ -f "$cfg_edge1/.onboarded" ] && pass "non-interactive → .onboarded created" || fail "non-interactive → .onboarded created"

# Test: config dir doesn't exist → auto-create
cfg_edge2="$TMPDIR_TEST/edge-2/deep/nested"
HUSHFLOW_CONFIG_DIR="$cfg_edge2" bash "$SCRIPT_DIR/onboarding.sh" </dev/null 2>/dev/null
[ -d "$cfg_edge2" ] && pass "auto-create nested config dir" || fail "auto-create nested config dir"

# Test: existing config is not overwritten on non-interactive run
cfg_edge3="$TMPDIR_TEST/edge-3"
mkdir -p "$cfg_edge3"
printf 'enabled=true\nexercise=3\ndelay=5\ntheme=amber\nanimation=ripple\nsound=true\n' > "$cfg_edge3/config"
HUSHFLOW_CONFIG_DIR="$cfg_edge3" bash "$SCRIPT_DIR/onboarding.sh" </dev/null 2>/dev/null
val=$(grep "^exercise=" "$cfg_edge3/config" 2>/dev/null | cut -d= -f2)
[ "$val" = "3" ] && pass "existing config preserved on non-interactive" || fail "existing config preserved, got '$val'"

# Test: script syntax check
bash -n "$SCRIPT_DIR/onboarding.sh" && pass "onboarding.sh syntax valid" || fail "onboarding.sh syntax invalid"

# ############################################################
# D. ON-START.SH INTEGRATION
# ############################################################

section "on-start.sh integration"

# Test: on-start.sh syntax check
bash -n "$SCRIPT_DIR/hooks/on-start.sh" && pass "on-start.sh syntax valid" || fail "on-start.sh syntax invalid"

# Test: on-start.sh contains onboarding check
grep -q '\.onboarded' "$SCRIPT_DIR/hooks/on-start.sh" && pass "on-start.sh has .onboarded check" || fail "on-start.sh missing .onboarded check"

# Test: with .onboarded present, on-start.sh proceeds past onboarding check
# (we can't fully run on-start.sh without a real session, but we can verify the logic structure)
grep -q 'onboarding.sh' "$SCRIPT_DIR/hooks/on-start.sh" && pass "on-start.sh references onboarding.sh" || fail "on-start.sh missing onboarding.sh reference"

# ############################################################
# E. CLI INTEGRATION
# ############################################################

section "CLI integration"

# Test: version command
out=$(bash "$SCRIPT_DIR/cli.sh" --version 2>/dev/null)
[ "$out" = "hushflow 2.0.0" ] && pass "cli --version" || fail "cli --version, got '$out'"

out=$(bash "$SCRIPT_DIR/cli.sh" version 2>/dev/null)
[ "$out" = "hushflow 2.0.0" ] && pass "cli version" || fail "cli version, got '$out'"

out=$(bash "$SCRIPT_DIR/cli.sh" -V 2>/dev/null)
[ "$out" = "hushflow 2.0.0" ] && pass "cli -V" || fail "cli -V, got '$out'"

# Test: help includes onboarding
out=$(bash "$SCRIPT_DIR/cli.sh" help 2>/dev/null)
echo "$out" | grep -q "onboarding" && pass "help shows onboarding" || fail "help missing onboarding"

# Test: help includes version
echo "$out" | grep -q "version" && pass "help shows version" || fail "help missing version"

# ############################################################
# SUMMARY
# ############################################################

echo ""
echo "================================"
echo "Onboarding tests: $PASSED passed, $FAILED failed (total: $TOTAL)"
echo "================================"

[ "$FAILED" -eq 0 ] && exit 0 || exit 1
