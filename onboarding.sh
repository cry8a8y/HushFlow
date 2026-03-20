#!/bin/bash
# HushFlow Guided Onboarding — first-run setup wizard.
# Sets exercise, theme, runs a 5-second demo, then marks .onboarded.
# Re-run anytime: hushflow onboarding

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"
CONFIG_FILE="$CONFIG_DIR/config"

# --- Helpers ---

set_value() {
    local key=$1 val=$2
    if grep -q "^${key}=" "$CONFIG_FILE" 2>/dev/null; then
        local tmp
        tmp=$(mktemp) || { echo "Error: failed to create temp file" >&2; return 1; }
        awk -v k="$key" -v v="$val" 'BEGIN{FS=OFS="="} $1==k{$2=v} {print}' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    else
        echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
}

cleanup() {
    # Remove temp files but leave partial config (user can re-run)
    rm -f /tmp/hushflow-onboard-$$ 2>/dev/null
}
trap cleanup EXIT

# --- Non-interactive terminal: skip wizard, mark onboarded ---
# HUSHFLOW_FORCE_INTERACTIVE=1 overrides for testing with piped input

if [ ! -t 0 ] && [ "${HUSHFLOW_FORCE_INTERACTIVE:-0}" != "1" ]; then
    mkdir -p "$CONFIG_DIR"
    if [ ! -f "$CONFIG_FILE" ]; then
        printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=random\nsound=false\n' > "$CONFIG_FILE"
    fi
    touch "$CONFIG_DIR/.onboarded"
    exit 0
fi

# --- Ensure config ---

mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
    printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=random\nsound=false\n' > "$CONFIG_FILE"
fi

# ============================================================
# Step 1: Welcome
# ============================================================
echo ""
echo "  Welcome to HushFlow!"
echo "  Let's set up your breathing exercise."
echo ""
printf "  Press Enter to continue... "
read -r

# ============================================================
# Step 2: Choose Exercise
# ============================================================
echo ""
echo "  Choose a breathing exercise:"
echo ""
echo "    1) Coherent Breathing  — 5.5s in, 5.5s out (default)"
echo "    2) Physiological Sigh  — double inhale + long exhale"
echo "    3) Box Breathing       — 4s in, 4s hold, 4s out, 4s hold"
echo "    4) 4-7-8 Breathing     — 4s in, 7s hold, 8s out"
echo ""
printf "  Your choice [1-4, default 1]: "
read -r exercise_choice

case "${exercise_choice:-1}" in
    1) set_value exercise 0; exercise_name="Coherent Breathing" ;;
    2) set_value exercise 1; exercise_name="Physiological Sigh" ;;
    3) set_value exercise 2; exercise_name="Box Breathing" ;;
    4) set_value exercise 3; exercise_name="4-7-8 Breathing" ;;
    *) set_value exercise 0; exercise_name="Coherent Breathing" ;;
esac
echo "  -> $exercise_name"

# ============================================================
# Step 3: Choose Theme
# ============================================================
echo ""
echo "  Choose a color theme:"
echo ""
echo "    1) teal     — Ocean teal (default)"
echo "    2) twilight  — Soft purple"
echo "    3) amber     — Warm sunset"

# List community themes
_theme_names=()
for _tdir in "$SCRIPT_DIR/themes" "$HOME/.hushflow/themes"; do
    if [ -d "$_tdir" ]; then
        for _tf in "$_tdir"/*.json; do
            [ -f "$_tf" ] || continue
            _tname=$(basename "$_tf" .json)
            _theme_names+=("$_tname")
        done
    fi
done

_theme_offset=4
for i in "${!_theme_names[@]}"; do
    echo "    $((_theme_offset + i))) ${_theme_names[$i]}"
done

echo ""
printf "  Your choice [name or number, default teal]: "
read -r theme_choice
theme_choice="${theme_choice:-teal}"

# Resolve number to name
case "$theme_choice" in
    1) theme_choice="teal" ;;
    2) theme_choice="twilight" ;;
    3) theme_choice="amber" ;;
    [0-9]*)
        idx=$(( theme_choice - _theme_offset ))
        if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#_theme_names[@]}" ]; then
            theme_choice="${_theme_names[$idx]}"
        fi
        ;;
esac

# Lowercase
theme_choice=$(echo "$theme_choice" | tr '[:upper:]' '[:lower:]')
set_value theme "$theme_choice"
echo "  -> $theme_choice"

# ============================================================
# Step 4: 5-Second Live Demo
# ============================================================
echo ""
echo "  Let's try it! Here's 5 seconds of $exercise_name..."
echo "  (Press Ctrl-C to skip)"
echo ""

# Set up environment for breathe-compact.sh
demo_session="/tmp/hushflow-onboard-$$"
mkdir -p "$demo_session"
echo "$(date +%s)" > "$demo_session/working"

(
    export HUSHFLOW_SESSION_DIR="$demo_session"
    export HUSHFLOW_CONFIG_DIR="$CONFIG_DIR"
    timeout 5 bash "$SCRIPT_DIR/breathe-compact.sh" 2>/dev/null
) || true

# Clean up demo session
rm -rf "$demo_session" 2>/dev/null

# ============================================================
# Step 5: Done
# ============================================================
echo ""
echo "  You're all set!"
echo ""
echo "  Next time your AI thinks, HushFlow will guide your breathing."
echo "  Run 'hushflow onboarding' anytime to change settings."
echo ""

touch "$CONFIG_DIR/.onboarded"
