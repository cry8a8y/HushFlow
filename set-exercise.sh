#!/bin/bash
# Configure HushFlow: exercises and themes
# Usage: set-exercise.sh [hrv|sigh|box|478]
#        set-exercise.sh theme [teal|twilight|amber]

CONFIG_DIR="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}"
CONFIG_FILE="$CONFIG_DIR/config"

# Lowercase helper (compatible with Bash 3.2 / macOS)
lc() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# Ensure config exists
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_FILE" ]; then
    printf 'enabled=true\nexercise=0\ndelay=5\ntheme=teal\nanimation=constellation\n' > "$CONFIG_FILE"
fi

set_value() {
    local key=$1 val=$2
    if grep -q "^${key}=" "$CONFIG_FILE"; then
        local tmp
        tmp=$(mktemp) || { echo "Error: failed to create temp file" >&2; return 1; }
        # Use awk to avoid sed regex injection from key/val
        awk -v k="$key" -v v="$val" 'BEGIN{FS=OFS="="} $1==k{$2=v} {print}' "$CONFIG_FILE" > "$tmp" && mv "$tmp" "$CONFIG_FILE"
    else
        echo "${key}=${val}" >> "$CONFIG_FILE"
    fi
}

ARG1=$(lc "$1")
ARG2=$(lc "$2")

# Sound subcommand
if [ "$ARG1" = "sound" ]; then
    case "$ARG2" in
        on|true|enable)
            set_value sound true
            echo "Sound enabled"
            ;;
        off|false|disable)
            set_value sound false
            echo "Sound disabled"
            ;;
        *)
            current_sound=$(grep "^sound=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
            echo "Sound: ${current_sound:-false} (off by default)"
            echo "  hushflow sound on    Enable breath transition sounds"
            echo "  hushflow sound off   Disable sounds"
            echo ""
            echo "Requires: ffplay, mpv, afplay, or paplay"
            echo "Place sound files in ~/.hushflow/sounds/"
            ;;
    esac
    exit 0
fi

# Animation subcommand
if [ "$ARG1" = "animation" ] || [ "$ARG1" = "anim" ]; then
    case "$ARG2" in
        constellation|stars)
            set_value animation constellation
            echo "Animation set to Constellation (twinkling stars)"
            ;;
        ripple|ripples)
            set_value animation ripple
            echo "Animation set to Ripple (concentric rings)"
            ;;
        wave|waves)
            set_value animation wave
            echo "Animation set to Wave (flowing sine)"
            ;;
        orbit|orbits)
            set_value animation orbit
            echo "Animation set to Orbit (dual comets)"
            ;;
        helix|dna)
            set_value animation helix
            echo "Animation set to Helix (double helix)"
            ;;
        rain)
            set_value animation rain
            echo "Animation set to Rain (gentle rainfall)"
            ;;
        *)
            echo "Available animations:"
            echo "  constellation - Twinkling star field (default)"
            echo "  ripple        - Concentric ripples"
            echo "  wave          - Flowing sine wave"
            echo "  orbit         - Dual orbiting comets"
            echo "  helix         - DNA double helix"
            echo "  rain          - Gentle rainfall"
            current_anim=$(grep "^animation=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
            echo ""
            echo "Current: ${current_anim:-constellation}"
            ;;
    esac
    exit 0
fi

# Theme subcommand
if [ "$ARG1" = "theme" ]; then
    case "$ARG2" in
        teal|t)
            set_value theme teal
            echo "Theme set to Teal (ocean)"
            ;;
        twilight|tw|purple)
            set_value theme twilight
            echo "Theme set to Twilight (purple)"
            ;;
        amber|a|warm)
            set_value theme amber
            echo "Theme set to Amber (warm)"
            ;;
        auto)
            set_value theme auto
            echo "Theme set to Auto (detects dark/light terminal)"
            ;;
        list|"")
            echo "Built-in themes:"
            echo "  teal     - Ocean teal (default)"
            echo "  twilight - Soft purple"
            echo "  amber    - Warm sunset"
            echo ""
            echo "Community themes:"
            _script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            for _tdir in "$_script_dir/themes" "$HOME/.hushflow/themes"; do
                if [ -d "$_tdir" ]; then
                    for _tf in "$_tdir"/*.json; do
                        [ -f "$_tf" ] || continue
                        _tname=$(basename "$_tf" .json)
                        if command -v jq &>/dev/null; then
                            _tdesc=$(jq -r '.name // empty' "$_tf" 2>/dev/null)
                            echo "  $_tname - $_tdesc"
                        else
                            echo "  $_tname"
                        fi
                    done
                fi
            done
            current_theme=$(grep "^theme=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
            echo ""
            echo "Current: ${current_theme:-teal}"
            ;;
        *)
            # Check if JSON community theme exists before accepting
            _script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            _found=0
            for _tdir in "$HOME/.hushflow/themes" "$_script_dir/themes"; do
                [ -f "$_tdir/${ARG2}.json" ] && _found=1 && break
            done
            if [ "$_found" -eq 1 ]; then
                set_value theme "$ARG2"
                echo "Theme set to $ARG2"
            else
                echo "Unknown theme: $ARG2" >&2
                echo "Run 'hushflow theme list' to see available themes." >&2
                exit 1
            fi
            ;;
    esac
    exit 0
fi

case "$ARG1" in
    hrv|coherence|0)
        set_value exercise 0
        echo "Set to Coherent Breathing (5.5s in, 5.5s out)"
        ;;
    sigh|physiological|1)
        set_value exercise 1
        echo "Set to Physiological Sigh (double inhale + long exhale)"
        ;;
    box|boxing|2)
        set_value exercise 2
        echo "Set to Box Breathing (4s in, 4s hold, 4s out, 4s hold)"
        ;;
    478|relax|3)
        set_value exercise 3
        echo "Set to 4-7-8 Breathing (4s in, 7s hold, 8s out)"
        ;;
    list|"")
        echo "Exercises:"
        echo "  hrv   - Coherent Breathing (5.5s in, 5.5s out)"
        echo "  sigh  - Physiological Sigh (double inhale + long exhale)"
        echo "  box   - Box Breathing (4s in, 4s hold, 4s out, 4s hold)"
        echo "  478   - 4-7-8 Breathing (4s in, 7s hold, 8s out)"
        current=0
        if [ -f "$CONFIG_FILE" ]; then
            current=$(grep "^exercise=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
        fi
        echo ""
        echo "Current exercise: ${current:-0}"
        echo ""
        echo "Themes:"
        echo "  teal     - Ocean teal (default)"
        echo "  twilight - Soft purple"
        echo "  amber    - Warm sunset"
        current_theme=$(grep "^theme=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
        echo "Current theme: ${current_theme:-teal}"
        echo ""
        echo "Animations:"
        echo "  constellation - Twinkling star field (default)"
        echo "  ripple        - Concentric ripples"
        echo "  wave          - Flowing sine wave"
        echo "  orbit         - Dual orbiting comets"
        echo "  helix         - DNA double helix"
        echo "  rain          - Gentle rainfall"
        current_anim=$(grep "^animation=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
        echo "Current animation: ${current_anim:-constellation}"
        echo ""
        echo "Usage: $(basename "$0") [exercise|theme <name>|animation <name>]"
        ;;
    *)
        echo "Unknown option: $1"
        echo "Run without arguments to see options"
        exit 1
        ;;
esac
