#!/bin/bash
# test/multi-tool-test.sh
# Validates that multiple tool sessions (Claude/Gemini) can coexist without interference.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; exit 1; }
section() { echo ""; echo "=== $1 ==="; }

# Setup mock environments
MOCK_CLAUDE="$TMPDIR_TEST/claude"
MOCK_GEMINI="$TMPDIR_TEST/gemini"
mkdir -p "$MOCK_CLAUDE/hushflow" "$MOCK_GEMINI/hushflow"

# 1. Start Claude session
section "Scenario: Parallel Sessions (Claude + Gemini)"
HUSHFLOW_CONFIG_DIR="$MOCK_CLAUDE/hushflow" HUSHFLOW_UI_MODE="off" HUSHFLOW_DEBUG=1 \
    bash "$SCRIPT_DIR/hooks/on-start.sh"
[ -f "$MOCK_CLAUDE/hushflow/.session" ] && pass "Claude session pointer created" || fail "Claude session pointer missing"
CLAUDE_SESSION_DIR=$(cat "$MOCK_CLAUDE/hushflow/.session")

# 2. Start Gemini session concurrently
HUSHFLOW_CONFIG_DIR="$MOCK_GEMINI/hushflow" HUSHFLOW_UI_MODE="off" HUSHFLOW_DEBUG=1 \
    bash "$SCRIPT_DIR/hooks/on-start.sh"
[ -f "$MOCK_GEMINI/hushflow/.session" ] && pass "Gemini session pointer created" || fail "Gemini session pointer missing"
GEMINI_SESSION_DIR=$(cat "$MOCK_GEMINI/hushflow/.session")

[ "$CLAUDE_SESSION_DIR" != "$GEMINI_SESSION_DIR" ] && pass "Sessions have unique directories" || fail "Session directory collision!"

# 3. Stop Gemini, ensure Claude is untouched
HUSHFLOW_CONFIG_DIR="$MOCK_GEMINI/hushflow" HUSHFLOW_DEBUG=1 \
    bash "$SCRIPT_DIR/hooks/on-stop.sh"
[ ! -d "$GEMINI_SESSION_DIR" ] && pass "Gemini session cleaned up" || fail "Gemini session still exists"
[ -d "$CLAUDE_SESSION_DIR" ] && pass "Claude session remains untouched" || fail "Claude session was accidentally killed!"

# 4. Cleanup Claude
HUSHFLOW_CONFIG_DIR="$MOCK_CLAUDE/hushflow" HUSHFLOW_DEBUG=1 \
    bash "$SCRIPT_DIR/hooks/on-stop.sh"
[ ! -d "$CLAUDE_SESSION_DIR" ] && pass "Claude session cleaned up" || fail "Claude session cleanup failed"

echo ""
echo "Multi-tool parallelism test: ALL PASSED"
