#!/bin/bash
# test/doctor-robustness-test.sh
# Validates that 'hushflow doctor' correctly identifies missing or broken hooks for all tools.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; exit 1; }
section() { echo ""; echo "=== $1 ==="; }

# Mock HOME setup
export HOME="$TMPDIR_TEST"
mkdir -p "$HOME/.claude" "$HOME/.gemini" "$HOME/.codex"

# 1. Test missing Claude Stop hook
section "Scenario: Broken Claude Hooks"
echo '{"hooks":{"UserPromptSubmit":[{"hooks":[{"command":"on-start.sh"}]}]}}' > "$HOME/.claude/settings.json"
output=$(bash "$SCRIPT_DIR/doctor.sh" 2>&1)
echo "$output" | grep -q "Claude Code: only start hook found (missing stop)" && pass "Doctor detected missing Claude stop hook" || fail "Doctor failed to detect missing Claude stop hook"

# 2. Test missing Gemini Start hook
section "Scenario: Broken Gemini Hooks"
echo '{"hooks":{"AfterAgent":[{"hooks":[{"command":"on-stop.sh"}]}]}}' > "$HOME/.gemini/settings.json"
output=$(bash "$SCRIPT_DIR/doctor.sh" 2>&1)
echo "$output" | grep -q "Gemini CLI: only stop hook found (missing start)" && pass "Doctor detected missing Gemini start hook" || fail "Doctor failed to detect missing Gemini start hook"

# 3. Test completely missing Codex hooks
section "Scenario: Missing Codex Hooks"
echo '{}' > "$HOME/.codex/hooks.json"
output=$(bash "$SCRIPT_DIR/doctor.sh" 2>&1)
echo "$output" | grep -q "Codex CLI: no hooks found" && pass "Doctor detected missing Codex hooks" || fail "Doctor failed to detect missing Codex hooks"

# 4. Timeout Consistency Verification (Code check)
section "Verification: Timeout Units"
# Gemini (ms)
grep -q '"timeout": 60000' "$SCRIPT_DIR/install.sh" && pass "Gemini timeout uses ms (60000)" || fail "Gemini timeout unit mismatch"
# Codex (s)
grep -q '"timeout": 60' "$SCRIPT_DIR/install.sh" && pass "Codex timeout uses s (60)" || fail "Codex timeout unit mismatch"

echo ""
echo "Doctor & Timeout tests: ALL PASSED"
