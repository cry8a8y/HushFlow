#!/bin/bash
# HushFlow Installer Contract Tests
# Tests install.sh across Claude / Gemini / Codex targets
# Validates JSON structure, idempotency, repair, uninstall, and isolation
#
# Usage: bash test/install-contract-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$SCRIPT_DIR/test/fixtures"
TMPDIR_TEST=$(mktemp -d)
trap 'rm -rf "$TMPDIR_TEST"' EXIT

_PASS_FILE="$TMPDIR_TEST/.pass_count"
_FAIL_FILE="$TMPDIR_TEST/.fail_count"
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

# Check jq is available
if ! command -v jq &>/dev/null; then
    echo "SKIP: jq not installed, cannot run installer contract tests"
    exit 0
fi

# ============================================================
# Helper: run install.sh in isolated HOME
# ============================================================
run_install() {
    local test_home="$1"; shift
    # Suppress interactive output, auto-accept
    HOME="$test_home" HUSHFLOW_INSTALL_SKIP_PRECHECKS=1 \
        bash "$SCRIPT_DIR/install.sh" "$@" 2>/dev/null || true
}

run_uninstall() {
    local test_home="$1"
    HOME="$test_home" HUSHFLOW_INSTALL_SKIP_PRECHECKS=1 \
        bash "$SCRIPT_DIR/install.sh" --uninstall 2>/dev/null || true
}

# ============================================================
# Helper: validate hook structure in JSON
# ============================================================
assert_hook_event() {
    local json_file="$1"
    local event="$2"
    local needle="$3"
    local label="$4"

    local count
    count=$(jq -r --arg event "$event" --arg needle "$needle" \
        '[.hooks[$event][]?.hooks[]? | select(.command | contains($needle))] | length' \
        "$json_file" 2>/dev/null || echo "0")

    [ "$count" -ge 1 ] && pass "$label" || fail "$label (count=$count)"
}

assert_no_hook_event() {
    local json_file="$1"
    local event="$2"
    local needle="$3"
    local label="$4"

    local count
    count=$(jq -r --arg event "$event" --arg needle "$needle" \
        '[.hooks[$event][]?.hooks[]? | select(.command | contains($needle))] | length' \
        "$json_file" 2>/dev/null || echo "0")

    [ "$count" -eq 0 ] && pass "$label" || fail "$label (found $count, expected 0)"
}

assert_hook_count() {
    local json_file="$1"
    local event="$2"
    local needle="$3"
    local expected="$4"
    local label="$5"

    local count
    count=$(jq -r --arg event "$event" --arg needle "$needle" \
        '[.hooks[$event][]?.hooks[]? | select(.command | contains($needle))] | length' \
        "$json_file" 2>/dev/null || echo "0")

    [ "$count" -eq "$expected" ] && pass "$label" || fail "$label (got $count, expected $expected)"
}

assert_hook_attr() {
    local json_file="$1"
    local event="$2"
    local needle="$3"
    local attr="$4"
    local expected="$5"
    local label="$6"

    local val
    val=$(jq -r --arg event "$event" --arg needle "$needle" --arg attr "$attr" \
        '[.hooks[$event][]?.hooks[]? | select(.command | contains($needle))] | first | .[$attr]' \
        "$json_file" 2>/dev/null || echo "null")

    [ "$val" = "$expected" ] && pass "$label" || fail "$label (got '$val', expected '$expected')"
}

assert_valid_json() {
    local json_file="$1"
    local label="$2"

    if jq empty "$json_file" 2>/dev/null; then
        pass "$label"
    else
        fail "$label"
    fi
}

assert_config_key() {
    local config_file="$1"
    local key="$2"
    local expected="$3"
    local label="$4"

    local val
    val=$(grep "^${key}=" "$config_file" 2>/dev/null | cut -d= -f2)

    [ "$val" = "$expected" ] && pass "$label" || fail "$label (got '$val', expected '$expected')"
}

# ############################################################
# CLAUDE TESTS
# ############################################################

section "Claude: Fresh install from empty settings"
(
    H="$TMPDIR_TEST/claude-fresh"
    mkdir -p "$H/.claude"
    cp "$FIXTURES/claude-empty.json" "$H/.claude/settings.json"
    run_install "$H" --target claude

    SF="$H/.claude/settings.json"
    assert_valid_json "$SF" "claude-fresh: valid JSON"
    assert_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "claude-fresh: start hook registered"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "claude-fresh: stop hook registered"
    assert_hook_event "$SF" "PermissionRequest" "on-permission.sh" "claude-fresh: permission hook registered"
    assert_hook_event "$SF" "PostToolUse" "on-resume.sh" "claude-fresh: resume hook registered"
    assert_hook_attr "$SF" "UserPromptSubmit" "on-start.sh" "async" "true" "claude-fresh: start hook async=true"
    assert_hook_attr "$SF" "Stop" "on-stop.sh" "async" "true" "claude-fresh: stop hook async=true"
    assert_hook_attr "$SF" "PermissionRequest" "on-permission.sh" "async" "true" "claude-fresh: permission hook async=true"
    assert_hook_attr "$SF" "PostToolUse" "on-resume.sh" "async" "true" "claude-fresh: resume hook async=true"

    # Config file
    CF="$H/.claude/hushflow/config"
    [ -f "$CF" ] && pass "claude-fresh: config created" || fail "claude-fresh: config missing"
    assert_config_key "$CF" "enabled" "true" "claude-fresh: enabled=true"
    assert_config_key "$CF" "animation" "constellation" "claude-fresh: animation=constellation"
    assert_config_key "$CF" "theme" "teal" "claude-fresh: theme=teal"
)

section "Claude: Install with existing hooks preserves them"
(
    H="$TMPDIR_TEST/claude-existing"
    mkdir -p "$H/.claude"
    cp "$FIXTURES/claude-existing-hooks.json" "$H/.claude/settings.json"
    run_install "$H" --target claude

    SF="$H/.claude/settings.json"
    assert_valid_json "$SF" "claude-existing: valid JSON"
    assert_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "claude-existing: HushFlow start hook added"
    assert_hook_event "$SF" "UserPromptSubmit" "other tool hook" "claude-existing: other start hook preserved"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "claude-existing: HushFlow stop hook added"
    assert_hook_event "$SF" "Stop" "other stop hook" "claude-existing: other stop hook preserved"
)

section "Claude: Idempotent — double install no duplicates"
(
    H="$TMPDIR_TEST/claude-idempotent"
    mkdir -p "$H/.claude"
    cp "$FIXTURES/claude-empty.json" "$H/.claude/settings.json"
    run_install "$H" --target claude
    run_install "$H" --target claude  # second install

    SF="$H/.claude/settings.json"
    assert_valid_json "$SF" "claude-idempotent: valid JSON"
    assert_hook_count "$SF" "UserPromptSubmit" "on-start.sh" 1 "claude-idempotent: exactly 1 start hook"
    assert_hook_count "$SF" "Stop" "on-stop.sh" 1 "claude-idempotent: exactly 1 stop hook"
    assert_hook_count "$SF" "PermissionRequest" "on-permission.sh" 1 "claude-idempotent: exactly 1 permission hook"
    assert_hook_count "$SF" "PostToolUse" "on-resume.sh" 1 "claude-idempotent: exactly 1 resume hook"
)

section "Claude: Half-broken repair (has start, missing stop)"
(
    H="$TMPDIR_TEST/claude-half"
    mkdir -p "$H/.claude"
    cp "$FIXTURES/claude-half-broken.json" "$H/.claude/settings.json"
    run_install "$H" --target claude

    SF="$H/.claude/settings.json"
    assert_valid_json "$SF" "claude-half: valid JSON"
    assert_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "claude-half: start hook still present"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "claude-half: stop hook repaired"
)

section "Claude: Uninstall removes only HushFlow hooks"
(
    H="$TMPDIR_TEST/claude-uninstall"
    mkdir -p "$H/.claude"
    cp "$FIXTURES/claude-existing-hooks.json" "$H/.claude/settings.json"
    run_install "$H" --target claude
    run_uninstall "$H"

    SF="$H/.claude/settings.json"
    assert_valid_json "$SF" "claude-uninstall: valid JSON"
    assert_no_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "claude-uninstall: HushFlow start removed"
    assert_no_hook_event "$SF" "Stop" "on-stop.sh" "claude-uninstall: HushFlow stop removed"
    assert_no_hook_event "$SF" "PermissionRequest" "on-permission.sh" "claude-uninstall: HushFlow permission removed"
    assert_no_hook_event "$SF" "PostToolUse" "on-resume.sh" "claude-uninstall: HushFlow resume removed"
    assert_hook_event "$SF" "UserPromptSubmit" "other tool hook" "claude-uninstall: other start hook preserved"
    assert_hook_event "$SF" "Stop" "other stop hook" "claude-uninstall: other stop hook preserved"

    # Config dir removed
    [ ! -d "$H/.claude/hushflow" ] && pass "claude-uninstall: config dir removed" || fail "claude-uninstall: config dir still exists"
)

section "Claude: Invalid JSON fails safely"
(
    H="$TMPDIR_TEST/claude-invalid"
    mkdir -p "$H/.claude"
    cp "$FIXTURES/claude-invalid.json" "$H/.claude/settings.json"
    run_install "$H" --target claude
    pass "claude-invalid: no crash on invalid JSON"
)

section "Claude: Target install only affects Claude"
(
    H="$TMPDIR_TEST/claude-isolation"
    mkdir -p "$H/.claude" "$H/.gemini" "$H/.codex"
    cp "$FIXTURES/claude-empty.json" "$H/.claude/settings.json"
    echo '{}' > "$H/.gemini/settings.json"
    echo '{}' > "$H/.codex/hooks.json"
    run_install "$H" --target claude

    # Gemini untouched
    gemini_hooks=$(jq '.hooks // empty' "$H/.gemini/settings.json" 2>/dev/null || echo "")
    [ -z "$gemini_hooks" ] && pass "claude-isolation: gemini untouched" || fail "claude-isolation: gemini modified"

    # Codex untouched
    codex_hooks=$(jq '.hooks // empty' "$H/.codex/hooks.json" 2>/dev/null || echo "")
    [ -z "$codex_hooks" ] && pass "claude-isolation: codex untouched" || fail "claude-isolation: codex modified"
)

# ############################################################
# GEMINI TESTS
# ############################################################

section "Gemini: Fresh install from empty settings"
(
    H="$TMPDIR_TEST/gemini-fresh"
    mkdir -p "$H/.gemini"
    cp "$FIXTURES/gemini-empty.json" "$H/.gemini/settings.json"
    run_install "$H" --target gemini

    SF="$H/.gemini/settings.json"
    assert_valid_json "$SF" "gemini-fresh: valid JSON"
    assert_hook_event "$SF" "BeforeAgent" "on-start.sh" "gemini-fresh: start hook registered"
    assert_hook_event "$SF" "AfterAgent" "on-stop.sh" "gemini-fresh: stop hook registered"
    assert_hook_attr "$SF" "BeforeAgent" "on-start.sh" "timeout" "60000" "gemini-fresh: start timeout=60000"
    assert_hook_attr "$SF" "AfterAgent" "on-stop.sh" "timeout" "5000" "gemini-fresh: stop timeout=5000"

    CF="$H/.gemini/hushflow/config"
    [ -f "$CF" ] && pass "gemini-fresh: config created" || fail "gemini-fresh: config missing"
    assert_config_key "$CF" "animation" "constellation" "gemini-fresh: animation=constellation"
)

section "Gemini: Idempotent — double install no duplicates"
(
    H="$TMPDIR_TEST/gemini-idempotent"
    mkdir -p "$H/.gemini"
    cp "$FIXTURES/gemini-empty.json" "$H/.gemini/settings.json"
    run_install "$H" --target gemini
    run_install "$H" --target gemini

    SF="$H/.gemini/settings.json"
    assert_hook_count "$SF" "BeforeAgent" "on-start.sh" 1 "gemini-idempotent: exactly 1 start hook"
    assert_hook_count "$SF" "AfterAgent" "on-stop.sh" 1 "gemini-idempotent: exactly 1 stop hook"
)

section "Gemini: Uninstall removes only HushFlow hooks"
(
    H="$TMPDIR_TEST/gemini-uninstall"
    mkdir -p "$H/.gemini"
    echo '{"hooks":{"BeforeAgent":[{"hooks":[{"type":"command","command":"echo other","timeout":1000}]}]}}' > "$H/.gemini/settings.json"
    run_install "$H" --target gemini
    run_uninstall "$H"

    SF="$H/.gemini/settings.json"
    assert_valid_json "$SF" "gemini-uninstall: valid JSON"
    assert_no_hook_event "$SF" "BeforeAgent" "on-start.sh" "gemini-uninstall: HushFlow start removed"
    assert_hook_event "$SF" "BeforeAgent" "other" "gemini-uninstall: other hook preserved"
)

section "Gemini: Half-broken repair"
(
    H="$TMPDIR_TEST/gemini-half"
    mkdir -p "$H/.gemini"
    echo '{"hooks":{"BeforeAgent":[{"hooks":[{"type":"command","command":"on-start.sh","timeout":60000}]}]}}' > "$H/.gemini/settings.json"
    run_install "$H" --target gemini

    SF="$H/.gemini/settings.json"
    assert_hook_event "$SF" "AfterAgent" "on-stop.sh" "gemini-half: stop hook repaired"
)

section "Gemini: Target install only affects Gemini"
(
    H="$TMPDIR_TEST/gemini-isolation"
    mkdir -p "$H/.claude" "$H/.gemini"
    echo '{}' > "$H/.claude/settings.json"
    cp "$FIXTURES/gemini-empty.json" "$H/.gemini/settings.json"
    run_install "$H" --target gemini

    claude_hooks=$(jq '.hooks // empty' "$H/.claude/settings.json" 2>/dev/null || echo "")
    [ -z "$claude_hooks" ] && pass "gemini-isolation: claude untouched" || fail "gemini-isolation: claude modified"
)

# ############################################################
# CODEX TESTS
# ############################################################

section "Codex: Fresh install from empty settings"
(
    H="$TMPDIR_TEST/codex-fresh"
    mkdir -p "$H/.codex"
    cp "$FIXTURES/codex-empty.json" "$H/.codex/hooks.json"
    run_install "$H" --target codex

    SF="$H/.codex/hooks.json"
    assert_valid_json "$SF" "codex-fresh: valid JSON"
    assert_hook_event "$SF" "SessionStart" "on-start.sh" "codex-fresh: start hook registered"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "codex-fresh: stop hook registered"
    assert_hook_attr "$SF" "SessionStart" "on-start.sh" "timeout" "60" "codex-fresh: start timeout=60"
    assert_hook_attr "$SF" "Stop" "on-stop.sh" "timeout" "5" "codex-fresh: stop timeout=5"

    CF="$H/.codex/hushflow/config"
    [ -f "$CF" ] && pass "codex-fresh: config created" || fail "codex-fresh: config missing"
    assert_config_key "$CF" "animation" "constellation" "codex-fresh: animation=constellation"
)

section "Codex: Idempotent — double install no duplicates"
(
    H="$TMPDIR_TEST/codex-idempotent"
    mkdir -p "$H/.codex"
    cp "$FIXTURES/codex-empty.json" "$H/.codex/hooks.json"
    run_install "$H" --target codex
    run_install "$H" --target codex

    SF="$H/.codex/hooks.json"
    assert_hook_count "$SF" "SessionStart" "on-start.sh" 1 "codex-idempotent: exactly 1 start hook"
    assert_hook_count "$SF" "Stop" "on-stop.sh" 1 "codex-idempotent: exactly 1 stop hook"
)

section "Codex: Uninstall removes only HushFlow hooks"
(
    H="$TMPDIR_TEST/codex-uninstall"
    mkdir -p "$H/.codex"
    echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"echo other","timeout":5}]}]}}' > "$H/.codex/hooks.json"
    run_install "$H" --target codex
    run_uninstall "$H"

    SF="$H/.codex/hooks.json"
    assert_valid_json "$SF" "codex-uninstall: valid JSON"
    assert_no_hook_event "$SF" "SessionStart" "on-start.sh" "codex-uninstall: HushFlow start removed"
    assert_no_hook_event "$SF" "Stop" "on-stop.sh" "codex-uninstall: HushFlow stop removed"
    assert_hook_event "$SF" "Stop" "other" "codex-uninstall: other hook preserved"
)

section "Codex: Half-broken repair"
(
    H="$TMPDIR_TEST/codex-half"
    mkdir -p "$H/.codex"
    echo '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"on-start.sh","timeout":60}]}]}}' > "$H/.codex/hooks.json"
    run_install "$H" --target codex

    SF="$H/.codex/hooks.json"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "codex-half: stop hook repaired"
)

section "Codex: Target install only affects Codex"
(
    H="$TMPDIR_TEST/codex-isolation"
    mkdir -p "$H/.claude" "$H/.codex"
    echo '{}' > "$H/.claude/settings.json"
    cp "$FIXTURES/codex-empty.json" "$H/.codex/hooks.json"
    run_install "$H" --target codex

    claude_hooks=$(jq '.hooks // empty' "$H/.claude/settings.json" 2>/dev/null || echo "")
    [ -z "$claude_hooks" ] && pass "codex-isolation: claude untouched" || fail "codex-isolation: claude modified"
)

# ############################################################
# CROSS-TARGET: Install with existing hooks from another tool
# ############################################################

section "Cross-target: Install all 3 tools in sequence"
(
    H="$TMPDIR_TEST/cross-all"
    mkdir -p "$H/.claude" "$H/.gemini" "$H/.codex"
    echo '{}' > "$H/.claude/settings.json"
    echo '{}' > "$H/.gemini/settings.json"
    echo '{}' > "$H/.codex/hooks.json"

    run_install "$H" --target claude
    run_install "$H" --target gemini
    run_install "$H" --target codex

    assert_hook_event "$H/.claude/settings.json" "UserPromptSubmit" "on-start.sh" "cross-all: claude start"
    assert_hook_event "$H/.claude/settings.json" "PermissionRequest" "on-permission.sh" "cross-all: claude permission"
    assert_hook_event "$H/.claude/settings.json" "PostToolUse" "on-resume.sh" "cross-all: claude resume"
    assert_hook_event "$H/.gemini/settings.json" "BeforeAgent" "on-start.sh" "cross-all: gemini start"
    assert_hook_event "$H/.codex/hooks.json" "SessionStart" "on-start.sh" "cross-all: codex start"

    # Uninstall all
    run_uninstall "$H"

    assert_no_hook_event "$H/.claude/settings.json" "UserPromptSubmit" "on-start.sh" "cross-all: claude uninstalled"
    assert_no_hook_event "$H/.claude/settings.json" "PermissionRequest" "on-permission.sh" "cross-all: claude permission uninstalled"
    assert_no_hook_event "$H/.claude/settings.json" "PostToolUse" "on-resume.sh" "cross-all: claude resume uninstalled"
    assert_no_hook_event "$H/.gemini/settings.json" "BeforeAgent" "on-start.sh" "cross-all: gemini uninstalled"
    assert_no_hook_event "$H/.codex/hooks.json" "SessionStart" "on-start.sh" "cross-all: codex uninstalled"
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
