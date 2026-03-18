#!/bin/bash
# test/wrap-target-test.sh
# Validates that 'hushflow wrap --target <tool>' respects tool-specific configuration.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; exit 1; }
section() { echo ""; echo "=== $1 ==="; }

# Mock HOME
export HOME="$TMPDIR_TEST"
MOCK_GEMINI_CFG="$HOME/.gemini/hushflow"
mkdir -p "$MOCK_GEMINI_CFG"

# Set a custom theme for Gemini
echo "theme=twilight" > "$MOCK_GEMINI_CFG/config"
echo "delay=0" >> "$MOCK_GEMINI_CFG/config"

# Test: Wrap with --target gemini and check environment
# We wrap a simple command that prints the HUSHFLOW_CONFIG_DIR we expect
section "Scenario: Wrap with target tool"
output=$(bash "$SCRIPT_DIR/lib/wrap.sh" --target gemini -- env | grep "HUSHFLOW_CONFIG_DIR" || true)

if echo "$output" | grep -q ".gemini/hushflow"; then
    pass "wrap --target gemini points to correct config dir"
else
    fail "wrap --target gemini failed to switch config dir (got '$output')"
fi

# Test: Wrap without target defaults to claude
output=$(bash "$SCRIPT_DIR/lib/wrap.sh" -- env | grep "HUSHFLOW_CONFIG_DIR" || true)
if echo "$output" | grep -q ".claude/hushflow"; then
    pass "wrap default points to claude config dir"
else
    fail "wrap default failed (got '$output')"
fi

echo ""
echo "Wrap target test: ALL PASSED"
