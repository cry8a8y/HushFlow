#!/bin/bash
# HushFlow terminal detection test suite
# Usage: bash test/terminal-detect-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASSED=0
FAILED=0
TOTAL=0

pass() { PASSED=$((PASSED + 1)); TOTAL=$((TOTAL + 1)); echo "  PASS: $1"; }
fail() { FAILED=$((FAILED + 1)); TOTAL=$((TOTAL + 1)); echo "  FAIL: $1"; }

section() { echo ""; echo "=== $1 ==="; }

# --- detect-terminal.sh syntax ---
section "Terminal detection basics"

bash -n "$SCRIPT_DIR/lib/detect-terminal.sh" 2>/dev/null && pass "detect-terminal.sh syntax ok" || fail "detect-terminal.sh syntax error"

# Test: detect_terminal function exists when sourced
source "$SCRIPT_DIR/lib/detect-terminal.sh"
type detect_terminal &>/dev/null && pass "detect_terminal function available" || fail "detect_terminal function missing"

# --- User override ---
section "HUSHFLOW_TERMINAL override"

result=$(HUSHFLOW_TERMINAL="ghostty" detect_terminal)
[ "$result" = "ghostty" ] && pass "override to ghostty" || fail "override to ghostty (got '$result')"

result=$(HUSHFLOW_TERMINAL="inline" detect_terminal)
[ "$result" = "inline" ] && pass "override to inline" || fail "override to inline (got '$result')"

result=$(HUSHFLOW_TERMINAL="iterm" detect_terminal)
[ "$result" = "iterm" ] && pass "override to iterm" || fail "override to iterm (got '$result')"

# --- Fallback behavior ---
section "Fallback to inline"

# With a bogus uname and no HUSHFLOW_TERMINAL, detect_terminal should
# return something (we test that it doesn't crash)
result=$(unset HUSHFLOW_TERMINAL; detect_terminal)
[ -n "$result" ] && pass "detect_terminal returns non-empty" || fail "detect_terminal returned empty"

# Test: result is one of the known terminals
case "$result" in
    ghostty|ghostty-linux|iterm|terminal-app|gnome-terminal|konsole|xfce4-terminal|xterm|windows-terminal|powershell|inline)
        pass "detect_terminal returned known terminal: $result"
        ;;
    *)
        fail "detect_terminal returned unknown: $result"
        ;;
esac

# --- Direct execution ---
section "Direct execution mode"

result=$(bash "$SCRIPT_DIR/lib/detect-terminal.sh")
[ -n "$result" ] && pass "direct execution returns result" || fail "direct execution returned empty"

# --- open-window.sh terminal dispatch ---
section "Terminal dispatch coverage"

# Verify open-window.sh handles all expected terminal types
for term in ghostty terminal-app iterm gnome-terminal konsole xfce4-terminal xterm ghostty-linux windows-terminal powershell inline; do
    if grep -q "$term" "$SCRIPT_DIR/hooks/open-window.sh"; then
        pass "open-window.sh handles $term"
    else
        fail "open-window.sh missing handler for $term"
    fi
done

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
