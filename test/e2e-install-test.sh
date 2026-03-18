#!/bin/bash
# HushFlow E2E Install Tests
# Simulates real user install flows using install-remote.sh
# Tests: fresh install, existing non-git dir, update (re-install)
#
# Usage: bash test/e2e-install-test.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

# Check prerequisites
if ! command -v jq &>/dev/null; then
    echo "SKIP: jq not installed"
    exit 0
fi
if ! command -v git &>/dev/null; then
    echo "SKIP: git not installed"
    exit 0
fi

echo "HushFlow E2E Install Tests"
echo "=========================="

REMOTE_SRC="$TMPDIR_TEST/remote-src"
REMOTE_REPO="$TMPDIR_TEST/remote.git"
SNAPSHOT_ROOT="$TMPDIR_TEST/snapshots"
mkdir -p "$SNAPSHOT_ROOT"
mkdir -p "$REMOTE_SRC"
git -C "$REMOTE_SRC" init --quiet
while IFS= read -r -d '' tracked_file; do
    mkdir -p "$REMOTE_SRC/$(dirname "$tracked_file")"
    cp -p "$SCRIPT_DIR/$tracked_file" "$REMOTE_SRC/$tracked_file"
done < <(git -C "$SCRIPT_DIR" ls-files -z)
git -C "$REMOTE_SRC" add .
git -C "$REMOTE_SRC" -c user.name="HushFlow Tests" -c user.email="tests@example.com" \
    commit --quiet -m "test snapshot"
git clone --quiet --bare "$REMOTE_SRC" "$REMOTE_REPO"

# ============================================================
# Helper: run install-remote.sh with local repo (no network)
# ============================================================
run_remote_install() {
    local test_home="$1"; shift
    # Override REPO to use local checkout instead of GitHub
    HOME="$test_home" REPO="$REMOTE_REPO" HUSHFLOW_INSTALL_SKIP_PRECHECKS=1 \
        bash "$SCRIPT_DIR/install-remote.sh" "$@" 2>/dev/null
}

snapshot_home() {
    local source_home="$1"
    local snapshot_name="$2"
    local dest="$SNAPSHOT_ROOT/$snapshot_name"
    rm -rf "$dest"
    mkdir -p "$dest"
    printf '%s\n' "$source_home" > "$dest/.source-home"
    [ -d "$source_home/.hushflow" ] && cp -a "$source_home/.hushflow" "$dest/.hushflow"
    [ -d "$source_home/.claude" ] && cp -a "$source_home/.claude" "$dest/.claude"
}

rewrite_snapshot_paths() {
    local source_root="$1"
    local target_root="$2"
    local file="$3"
    [ -f "$file" ] || return 0

    local escaped_source escaped_target tmp_file
    escaped_source=$(printf '%s\n' "$source_root" | sed 's/[\/&]/\\&/g')
    escaped_target=$(printf '%s\n' "$target_root" | sed 's/[\/&]/\\&/g')
    tmp_file="$file.tmp"
    sed "s/${escaped_source}/${escaped_target}/g" "$file" > "$tmp_file"
    mv "$tmp_file" "$file"
}

restore_home_snapshot() {
    local snapshot_name="$1"
    local target_home="$2"
    local source_home=""
    mkdir -p "$target_home"
    source_home=$(cat "$SNAPSHOT_ROOT/$snapshot_name/.source-home" 2>/dev/null || echo "")
    [ -d "$SNAPSHOT_ROOT/$snapshot_name/.hushflow" ] && cp -a "$SNAPSHOT_ROOT/$snapshot_name/.hushflow" "$target_home/.hushflow"
    [ -d "$SNAPSHOT_ROOT/$snapshot_name/.claude" ] && cp -a "$SNAPSHOT_ROOT/$snapshot_name/.claude" "$target_home/.claude"
    if [ -n "$source_home" ]; then
        rewrite_snapshot_paths "$source_home" "$target_home" "$target_home/.claude/settings.json"
        rewrite_snapshot_paths "$source_home" "$target_home" "$target_home/.gemini/settings.json"
        rewrite_snapshot_paths "$source_home" "$target_home" "$target_home/.codex/hooks.json"
    fi
}

prepare_installed_snapshot() {
    local snapshot_name="$1"
    local seed_home="$TMPDIR_TEST/seed-$snapshot_name"
    mkdir -p "$seed_home"
    run_remote_install "$seed_home"
    snapshot_home "$seed_home" "$snapshot_name"
}

# ============================================================
# Assertions
# ============================================================
assert_file_exists() {
    local file="$1" label="$2"
    [ -f "$file" ] && pass "$label" || fail "$label"
}

assert_dir_exists() {
    local dir="$1" label="$2"
    [ -d "$dir" ] && pass "$label" || fail "$label"
}

assert_hook_event() {
    local json_file="$1" event="$2" needle="$3" label="$4"
    local count
    count=$(jq -r --arg event "$event" --arg needle "$needle" \
        '[.hooks[$event][]?.hooks[]? | select(.command | contains($needle))] | length' \
        "$json_file" 2>/dev/null || echo "0")
    [ "$count" -ge 1 ] && pass "$label" || fail "$label (count=$count)"
}

# ############################################################
# SCENARIO 1: Fresh install — no ~/.hushflow exists
# ############################################################

section "Scenario 1: Fresh install (clean state)"
(
    H="$TMPDIR_TEST/fresh"
    mkdir -p "$H"

    run_remote_install "$H"

    INSTALL_DIR="$H/.hushflow"

    # Repo cloned correctly
    assert_dir_exists "$INSTALL_DIR/.git" "fresh: .git directory exists"

    # Core files present
    assert_file_exists "$INSTALL_DIR/breathe-compact.sh" "fresh: breathe-compact.sh exists"
    assert_file_exists "$INSTALL_DIR/hooks/on-start.sh" "fresh: hooks/on-start.sh exists"
    assert_file_exists "$INSTALL_DIR/hooks/on-stop.sh" "fresh: hooks/on-stop.sh exists"
    assert_file_exists "$INSTALL_DIR/cli.sh" "fresh: cli.sh exists"
    assert_file_exists "$INSTALL_DIR/doctor.sh" "fresh: doctor.sh exists"
    assert_file_exists "$INSTALL_DIR/install.sh" "fresh: install.sh exists"

    # Scripts are executable
    [ -x "$INSTALL_DIR/breathe-compact.sh" ] && pass "fresh: breathe-compact.sh is executable" || fail "fresh: breathe-compact.sh not executable"
    [ -x "$INSTALL_DIR/hooks/on-start.sh" ] && pass "fresh: on-start.sh is executable" || fail "fresh: on-start.sh not executable"

    # doctor.sh runs successfully
    if HOME="$H" bash "$INSTALL_DIR/doctor.sh" >/dev/null 2>&1; then
        pass "fresh: doctor.sh exits 0"
    else
        fail "fresh: doctor.sh exits non-zero"
    fi

    # Hooks registered for Claude (auto-detected via ~/.claude)
    SF="$H/.claude/settings.json"
    assert_file_exists "$SF" "fresh: claude settings.json created"
    assert_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "fresh: claude start hook registered"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "fresh: claude stop hook registered"

    # Config created
    assert_file_exists "$H/.claude/hushflow/config" "fresh: claude config created"
)

# ############################################################
# SCENARIO 2: Existing non-git directory (e.g. only stats.log)
# ############################################################

section "Scenario 2: Existing non-git directory"
(
    H="$TMPDIR_TEST/existing-nongit"
    mkdir -p "$H/.hushflow"

    # Simulate pre-existing stats.log (from hooks running without full install)
    echo -e "2026-03-17T10:00:00\t5\t120\t0\tconstellation\tteal" > "$H/.hushflow/stats.log"

    run_remote_install "$H"

    INSTALL_DIR="$H/.hushflow"

    # Repo set up correctly
    assert_dir_exists "$INSTALL_DIR/.git" "nongit: .git directory created"

    # Core files present
    assert_file_exists "$INSTALL_DIR/breathe-compact.sh" "nongit: breathe-compact.sh exists"
    assert_file_exists "$INSTALL_DIR/hooks/on-start.sh" "nongit: hooks/on-start.sh exists"
    assert_file_exists "$INSTALL_DIR/doctor.sh" "nongit: doctor.sh exists"

    # Existing stats.log preserved
    if [ -f "$INSTALL_DIR/stats.log" ] && grep -q "2026-03-17" "$INSTALL_DIR/stats.log"; then
        pass "nongit: stats.log preserved"
    else
        fail "nongit: stats.log lost or corrupted"
    fi

    # doctor.sh runs successfully
    if HOME="$H" bash "$INSTALL_DIR/doctor.sh" >/dev/null 2>&1; then
        pass "nongit: doctor.sh exits 0"
    else
        fail "nongit: doctor.sh exits non-zero"
    fi

    # Hooks registered
    SF="$H/.claude/settings.json"
    assert_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "nongit: claude start hook registered"
    assert_hook_event "$SF" "Stop" "on-stop.sh" "nongit: claude stop hook registered"
)

# ############################################################
# SCENARIO 3: Existing git install (update via git pull)
# ############################################################

prepare_installed_snapshot "installed-home"

section "Scenario 3: Existing git install (update)"
(
    H="$TMPDIR_TEST/existing-git"
    mkdir -p "$H"
    restore_home_snapshot "installed-home" "$H"

    INSTALL_DIR="$H/.hushflow"

    # Record the initial commit hash
    initial_head=$(git -C "$INSTALL_DIR" rev-parse HEAD)

    # Second install (should do git pull, not re-clone)
    run_remote_install "$H"

    # Still a valid git repo
    assert_dir_exists "$INSTALL_DIR/.git" "update: .git still exists"

    # Core files still present
    assert_file_exists "$INSTALL_DIR/breathe-compact.sh" "update: breathe-compact.sh exists"
    assert_file_exists "$INSTALL_DIR/doctor.sh" "update: doctor.sh exists"

    # HEAD is valid (git pull didn't break anything)
    updated_head=$(git -C "$INSTALL_DIR" rev-parse HEAD 2>/dev/null || echo "BROKEN")
    [ "$updated_head" != "BROKEN" ] && pass "update: git repo healthy after re-install" || fail "update: git repo broken"

    # doctor.sh still works
    if HOME="$H" bash "$INSTALL_DIR/doctor.sh" >/dev/null 2>&1; then
        pass "update: doctor.sh exits 0"
    else
        fail "update: doctor.sh exits non-zero"
    fi

    # Hooks not duplicated
    SF="$H/.claude/settings.json"
    count=$(jq -r '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("on-start.sh"))] | length' "$SF" 2>/dev/null || echo "0")
    [ "$count" -eq 1 ] && pass "update: no duplicate start hooks" || fail "update: $count start hooks (expected 1)"
)

# ############################################################
# SCENARIO 4: Uninstall then reinstall
# ############################################################

section "Scenario 4: Uninstall then reinstall"
(
    H="$TMPDIR_TEST/reinstall"
    mkdir -p "$H"
    restore_home_snapshot "installed-home" "$H"

    INSTALL_DIR="$H/.hushflow"

    # Uninstall (removes hooks and config, but not ~/.hushflow itself)
    HOME="$H" bash "$INSTALL_DIR/install.sh" --uninstall 2>/dev/null || true

    # Verify hooks removed
    SF="$H/.claude/settings.json"
    count=$(jq -r '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command | contains("on-start.sh"))] | length' "$SF" 2>/dev/null || echo "0")
    [ "$count" -eq 0 ] && pass "reinstall: hooks removed after uninstall" || fail "reinstall: hooks still present"

    # Reinstall
    run_remote_install "$H"

    # Hooks restored
    assert_hook_event "$SF" "UserPromptSubmit" "on-start.sh" "reinstall: hooks restored after reinstall"

    # doctor works
    if HOME="$H" bash "$INSTALL_DIR/doctor.sh" >/dev/null 2>&1; then
        pass "reinstall: doctor.sh exits 0 after reinstall"
    else
        fail "reinstall: doctor.sh exits non-zero after reinstall"
    fi
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
