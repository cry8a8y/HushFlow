#!/bin/bash
# HushFlow breathing animation — multiple styles.
# Styles: constellation, ripple, wave, orbit, helix, rain.
# Entire frame is buffered and output with a single printf (no flicker).

hf_log() { [ "${HUSHFLOW_DEBUG:-}" = "1" ] && echo "$(date '+%H:%M:%S') [breathe] $*" >> /tmp/hushflow-debug.log; }

SESSION_DIR="${HUSHFLOW_SESSION_DIR:-/tmp/hushflow-$$}"
MARKER_FILE="$SESSION_DIR/working"
CONFIG_FILE="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}/config"
WINDOW_TITLE="${HUSHFLOW_WINDOW_TITLE:-HushFlow}"

# === Theme ===
theme=""
if [ -f "$CONFIG_FILE" ]; then
    theme=$(grep "^theme=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
fi

# Auto-theme: detect terminal background
if [ "${theme:-}" = "auto" ]; then
    _breathe_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "$_breathe_dir/lib/detect-background.sh" ]; then
        source "$_breathe_dir/lib/detect-background.sh"
        _bg=$(detect_background 2>/dev/null || echo "unknown")
        case "$_bg" in
            dark)  theme="teal" ;;
            light) theme="amber" ;;
            *)     theme="teal" ;;
        esac
    else
        theme="teal"
    fi
fi

# Load theme colors — built-in first, then JSON community themes
_theme_loaded=0
case "${theme:-teal}" in
    twilight) C_B='209;196;233' C_D='126;87;194' C_MID='167;141;213' C_MDIM='142;128;175' C_DIM='158;158;158'; _theme_loaded=1 ;;
    amber)    C_B='255;224;178' C_D='245;124;0'  C_MID='250;174;89'  C_MDIM='205;160;114' C_DIM='161;136;127'; _theme_loaded=1 ;;
    teal)     C_B='128;203;196' C_D='0;121;107'  C_MID='64;162;151'  C_MDIM='90;144;140'  C_DIM='120;144;156'; _theme_loaded=1 ;;
esac

# JSON community/custom theme loader
if [ "$_theme_loaded" -eq 0 ] && [ -n "${theme:-}" ] && command -v jq &>/dev/null; then
    _hf_dir="${HUSHFLOW_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    for _theme_dir in "$HOME/.hushflow/themes" "$_hf_dir/themes"; do
        _theme_file="$_theme_dir/${theme}.json"
        if [ -f "$_theme_file" ]; then
            eval "$(jq -r '
              .colors | to_entries | map(
                {primary:"C_B",secondary:"C_D",mid:"C_MID",mid_dim:"C_MDIM",dim:"C_DIM"}[.key] as $var |
                select($var) | "\($var)=\u0027\(.value)\u0027"
              ) | join("\n")
            ' "$_theme_file" 2>/dev/null)"
            if [ -n "$C_B" ] && [ -n "$C_D" ]; then
                _theme_loaded=1
                hf_log "loaded JSON theme: $theme from $_theme_file"
                break
            fi
        fi
    done
fi

# Fallback to teal if theme not found
if [ "$_theme_loaded" -eq 0 ]; then
    C_B='128;203;196' C_D='0;121;107' C_MID='64;162;151' C_MDIM='90;144;140' C_DIM='120;144;156'
    hf_log "theme '${theme:-teal}' not found, using teal"
fi
unset _theme_loaded _theme_dir _theme_file _hf_dir

# Environment variable overrides (e.g., HUSHFLOW_COLOR_IN='255;0;0')
[ -n "${HUSHFLOW_COLOR_IN:-}" ] && C_B="$HUSHFLOW_COLOR_IN"
[ -n "${HUSHFLOW_COLOR_OUT:-}" ] && C_D="$HUSHFLOW_COLOR_OUT"
[ -n "${HUSHFLOW_COLOR_MID:-}" ] && C_MID="$HUSHFLOW_COLOR_MID"
[ -n "${HUSHFLOW_COLOR_MDIM:-}" ] && C_MDIM="$HUSHFLOW_COLOR_MDIM"
[ -n "${HUSHFLOW_COLOR_DIM:-}" ] && C_DIM="$HUSHFLOW_COLOR_DIM"

# === Color capability detection ===
# TrueColor (24-bit): COLORTERM=truecolor or 24bit
# 256-color: tput colors >= 256
# Fallback: basic 16-color ANSI
_hf_detect_truecolor() {
    if [ "${COLORTERM:-}" = "truecolor" ] || [ "${COLORTERM:-}" = "24bit" ]; then
        echo 1
    else
        echo 0
    fi
}

_hf_use_truecolor=$(_hf_detect_truecolor)
if [ "$_hf_use_truecolor" -eq 0 ]; then
    _tc=$(tput colors 2>/dev/null || echo 8)
    if [ "$_tc" -ge 256 ] 2>/dev/null; then
        hf_log "TrueColor not detected (COLORTERM=${COLORTERM:-unset}), using 256-color fallback"
    else
        hf_log "Limited color support ($_tc colors), using 256-color fallback"
    fi
fi

# Convert "R;G;B" to nearest 256-color code
_rgb_to_256() {
    local r g b
    IFS=';' read -r r g b <<< "$1"
    # 6x6x6 color cube: 16 + 36*r + 6*g + b (scaled 0-5)
    local r6=$(( (r * 5 + 127) / 255 ))
    local g6=$(( (g * 5 + 127) / 255 ))
    local b6=$(( (b * 5 + 127) / 255 ))
    echo $(( 16 + 36 * r6 + 6 * g6 + b6 ))
}

if [ "$_hf_use_truecolor" -eq 1 ]; then
    COLOR_IN="\033[38;2;${C_B}m"
    COLOR_OUT="\033[38;2;${C_D}m"
    COLOR_MID="\033[38;2;${C_MID}m"
    COLOR_MDIM="\033[38;2;${C_MDIM}m"
    DIM="\033[38;2;${C_DIM}m"
else
    COLOR_IN="\033[38;5;$(_rgb_to_256 "$C_B")m"
    COLOR_OUT="\033[38;5;$(_rgb_to_256 "$C_D")m"
    COLOR_MID="\033[38;5;$(_rgb_to_256 "$C_MID")m"
    COLOR_MDIM="\033[38;5;$(_rgb_to_256 "$C_MDIM")m"
    DIM="\033[38;5;$(_rgb_to_256 "$C_DIM")m"
fi
unset _hf_use_truecolor
RESET='\033[0m'

# === Exercise ===
EXERCISES=(
    "Coherent|5.5|0|5.5|0"
    "Sigh|4|1|10|0|double_inhale"
    "Box|4|4|4|4"
    "4-7-8|4|7|8|0"
)
current_exercise=0
if [ -f "$CONFIG_FILE" ]; then
    saved=$(grep "^exercise=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
    if [[ "$saved" =~ ^[0-9]+$ ]] && [ "$saved" -ge 0 ] && [ "$saved" -lt ${#EXERCISES[@]} ]; then
        current_exercise=$saved
    fi
fi
IFS='|' read -r EX_NAME IN_DUR HOLD1_DUR EX_DUR HOLD2_DUR EX_TYPE <<< "${EXERCISES[$current_exercise]}"
EX_TYPE="${EX_TYPE:-standard}"

# === Animation ===
animation=""
if [ -f "$CONFIG_FILE" ]; then
    animation=$(grep "^animation=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
fi
VALID_ANIMATIONS="constellation ripple wave orbit helix rain"

# Random mode: pick one animation for this session
if [ -z "$animation" ] || [ "$animation" = "random" ]; then
    _anim_arr=($VALID_ANIMATIONS)
    animation="${_anim_arr[$((RANDOM % ${#_anim_arr[@]}))]}"
    hf_log "random animation selected: $animation"
    unset _anim_arr
fi

# Validate built-in animation name (plugins are validated at render time)
_is_builtin_anim=0
for _a in $VALID_ANIMATIONS; do [ "$animation" = "$_a" ] && _is_builtin_anim=1; done
if [ "$_is_builtin_anim" -eq 0 ] && ! type "render_${animation}" &>/dev/null; then
    hf_log "warning: unknown animation '$animation', will fall back to constellation"
fi
unset _is_builtin_anim _a

# === Plugin: load custom animation if available ===
# Plugins are bash scripts in ~/.hushflow/plugins/ or $HUSHFLOW_PLUGIN_DIR/
# Each plugin should define a render_<name>() function that appends to $frame.
# Available variables: tick, progress (0-1000), PANE_W, PANE_H, center_row, center_col,
#   COLOR_IN, COLOR_OUT, COLOR_MID, COLOR_MDIM, DIM, RESET, SIN32[], COS32[], SIN64[], COS64[]
PLUGIN_DIR="${HUSHFLOW_PLUGIN_DIR:-$HOME/.hushflow/plugins}"
if [ -d "$PLUGIN_DIR" ]; then
    for plugin_file in "$PLUGIN_DIR"/*.sh; do
        [ -f "$plugin_file" ] || continue
        if bash -n "$plugin_file" 2>/dev/null; then
            source "$plugin_file"
        else
            hf_log "WARNING: plugin has syntax errors, skipped: $plugin_file"
        fi
    done
    hf_log "loaded plugins from $PLUGIN_DIR"
fi

# === Sound ===
_BREATHE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$_BREATHE_SCRIPT_DIR/lib/sound.sh" ]; then
    source "$_BREATHE_SCRIPT_DIR/lib/sound.sh"
fi
_last_phase="Breathe in"  # Initialize to first phase to avoid spurious sound on tick 0

# === Timing ===
TICK_RATE=10
sec_to_ticks() {
    local s=$1
    if [[ "$s" == *.* ]]; then
        local whole=${s%%.*}
        local frac=${s#*.}
        frac=${frac:0:1}
        echo $(( whole * TICK_RATE + frac ))
    else
        echo $(( s * TICK_RATE ))
    fi
}
IN_TICKS=$(sec_to_ticks "$IN_DUR")
H1_TICKS=$(sec_to_ticks "$HOLD1_DUR")
EX_TICKS=$(sec_to_ticks "$EX_DUR")
H2_TICKS=$(sec_to_ticks "$HOLD2_DUR")
CYCLE_TICKS=$((IN_TICKS + H1_TICKS + EX_TICKS + H2_TICKS))

ease() {
    # Sine ease-in-out: smooth acceleration + deceleration (mimics natural breathing)
    local idx=$(( $1 * 16 / 1000 ))
    [ "$idx" -gt 16 ] && idx=16
    EASE_OUT=$(( (1000 - COS32[idx]) / 2 ))
}

# === Trig lookup (32 entries, sin/cos * 1000) ===
SIN32=(0 195 383 556 707 831 924 981 1000 981 924 831 707 556 383 195 0 -195 -383 -556 -707 -831 -924 -981 -1000 -981 -924 -831 -707 -556 -383 -195)
COS32=(1000 981 924 831 707 556 383 195 0 -195 -383 -556 -707 -831 -924 -981 -1000 -981 -924 -831 -707 -556 -383 -195 0 195 383 556 707 831 924 981)

# === Trig lookup (64 entries, finer resolution for smooth curves) ===
SIN64=(0 98 195 290 383 471 556 634 707 773 831 882 924 957 981 995 1000 995 981 957 924 882 831 773 707 634 556 471 383 290 195 98 0 -98 -195 -290 -383 -471 -556 -634 -707 -773 -831 -882 -924 -957 -981 -995 -1000 -995 -981 -957 -924 -882 -831 -773 -707 -634 -556 -471 -383 -290 -195 -98)
COS64=(1000 995 981 957 924 882 831 773 707 634 556 471 383 290 195 98 0 -98 -195 -290 -383 -471 -556 -634 -707 -773 -831 -882 -924 -957 -981 -995 -1000 -995 -981 -957 -924 -882 -831 -773 -707 -634 -556 -471 -383 -290 -195 -98 0 98 195 290 383 471 556 634 707 773 831 882 924 957 981 995)

# ========== CONSTELLATION DATA ==========
HALF_DOTS=(
    "0:0"
    "0:90" "-1:50" "1:55" "-2:80" "2:90"
    "0:180" "-1:140" "1:150" "-2:200" "2:210" "-3:130" "3:140"
    "0:280" "-1:250" "1:240" "-2:300" "2:310" "-3:270" "3:260"
    "0:420" "-1:440" "1:410" "-2:380" "2:370"
    "-3:480" "3:500" "-4:350" "4:360"
    "0:560" "-1:530" "1:520" "-2:500" "2:490"
    "-1:650" "1:630" "-2:600" "2:580"
    "-3:700" "3:680" "-4:620" "4:640"
    "-5:550" "5:530"
    "0:850" "-1:800" "1:780"
    "-2:900" "2:870" "-3:830" "3:810"
    "-4:760" "4:740" "-5:700" "5:680"
)
DOTS=()
for dot in "${HALF_DOTS[@]}"; do
    IFS=':' read -r dr dc <<< "$dot"
    DOTS+=("${dr}:${dc}")
    if [ "$dc" -ne 0 ]; then
        DOTS+=("${dr}:-${dc}")
    fi
done
NUM_DOTS=${#DOTS[@]}
declare -a DOT_ROW DOT_COL DOT_DIST DOT_SROW DOT_SCOL
for ((i=0; i<NUM_DOTS; i++)); do
    IFS=':' read -r dr dc <<< "${DOTS[$i]}"
    DOT_ROW[$i]=$dr
    DOT_COL[$i]=$dc
    abs_dc=${dc#-}
    DOT_DIST[$i]=$abs_dc
done

# ========== RIPPLE DATA ==========
declare -a RIP_ROW RIP_COL RIP_DIST
NUM_RIP=0
RIP_ROW[0]=0; RIP_COL[0]=0; RIP_DIST[0]=0
NUM_RIP=1
rip_radii=(1 2 3 5 7 9)
rip_counts=(6 10 16 24 28 32)
rip_dists=(100 250 400 600 780 950)
for ((ri=0; ri<6; ri++)); do
    r=${rip_radii[$ri]}
    n=${rip_counts[$ri]}
    d=${rip_dists[$ri]}
    for ((j=0; j<n; j++)); do
        ai=$(( j * 64 / n ))
        RIP_ROW[$NUM_RIP]=$(( r * SIN64[ai] / 1000 ))
        RIP_COL[$NUM_RIP]=$(( r * COS64[ai] * 2 / 1000 ))
        RIP_DIST[$NUM_RIP]=$d
        NUM_RIP=$((NUM_RIP + 1))
    done
done

# ========== RAIN DATA ==========
NUM_DROPS=40
declare -a DROP_SPEED DROP_OFFSET DROP_THRESH DROP_SEED
for ((d=0; d<NUM_DROPS; d++)); do
    DROP_SEED[$d]=$(( d * 17 + 5 ))
    DROP_SPEED[$d]=$(( d % 3 + 1 ))
    DROP_OFFSET[$d]=$(( d * 31 % 100 ))
    DROP_THRESH[$d]=$(( d * 1000 / NUM_DROPS ))
done

# ========== TERMINAL SIZE ==========
read_size() {
    PANE_W=${HUSHFLOW_COLS:-$(tput cols 2>/dev/null || echo 59)}
    PANE_H=${HUSHFLOW_ROWS:-$(tput lines 2>/dev/null || echo 20)}
    # Enforce minimum terminal size for safe rendering
    [ "$PANE_W" -lt 20 ] && PANE_W=20
    [ "$PANE_H" -lt 8 ] && PANE_H=8
    center_row=$((PANE_H / 2))
    center_col=$((PANE_W / 2))
    half_w=$((PANE_W / 2))
    for ((i=0; i<NUM_DOTS; i++)); do
        DOT_SROW[$i]=$((center_row + DOT_ROW[$i]))
        DOT_SCOL[$i]=$((center_col + DOT_COL[$i] * half_w / 1000))
    done
    printf '\033[2J'
}
read_size

cleanup() {
    [ -n "${_hf_old_stty:-}" ] && stty "$_hf_old_stty" 2>/dev/null
    printf '\033[?25h\033[0m\033[2J\033[?1049l'
    # For non-graceful exits, on-stop.sh handles Ghostty window close
}
trap 'cleanup' EXIT
trap read_size WINCH
printf '\033]0;%s\a\033[?1049h\033[?25l\033[2J' "$WINDOW_TITLE"

# === Keyboard input: stty raw mode for ESC detection ===
# Use stty -icanon min 0 time 0 for instant non-blocking reads via dd.
# Bash 3.2's read -n1 overrides stty (sets min 1 time 0), so we use
# dd bs=1 count=1 which respects stty settings directly.
_hf_old_stty=""
if [ -t 0 ]; then
    _hf_old_stty=$(stty -g 2>/dev/null) || true
    stty -echo -icanon min 0 time 0 2>/dev/null || true
fi
hf_log "started animation=$animation exercise=$EX_NAME theme=${theme:-teal} PANE=${PANE_W}x${PANE_H}"

# ========== RENDER FUNCTIONS ==========

render_constellation() {
    for ((i=0; i<NUM_DOTS; i++)); do
        local dist=${DOT_DIST[$i]}
        if [ "$dist" -le "$progress" ]; then
            local sr=${DOT_SROW[$i]} sc=${DOT_SCOL[$i]}
            if [ "$sr" -ge 5 ] && [ "$sr" -lt "$PANE_H" ] && [ "$sc" -ge 1 ] && [ "$sc" -le "$PANE_W" ]; then
                local tw=$(( (i * 7 + tick) % 10 ))
                if [ "$dist" -lt 150 ]; then
                    if [ "$tw" -lt 2 ]; then
                        frame+="\033[${sr};${sc}H${COLOR_MID}•${RESET}"
                    else
                        frame+="\033[${sr};${sc}H${color}✦${RESET}"
                    fi
                elif [ "$dist" -lt 350 ]; then
                    if [ "$tw" -lt 2 ]; then
                        frame+="\033[${sr};${sc}H${color}✦${RESET}"
                    else
                        frame+="\033[${sr};${sc}H${color}•${RESET}"
                    fi
                elif [ "$dist" -lt 550 ]; then
                    frame+="\033[${sr};${sc}H${COLOR_MID}•${RESET}"
                elif [ "$dist" -lt 750 ]; then
                    frame+="\033[${sr};${sc}H${COLOR_MDIM}·${RESET}"
                else
                    if [ "$tw" -lt 1 ]; then
                        frame+="\033[${sr};${sc}H${COLOR_MDIM}•${RESET}"
                    else
                        frame+="\033[${sr};${sc}H${DIM}·${RESET}"
                    fi
                fi
            fi
        fi
    done
}

render_ripple() {
    for ((i=0; i<NUM_RIP; i++)); do
        local dist=${RIP_DIST[$i]}
        if [ "$dist" -le "$progress" ]; then
            local sr=$((center_row + RIP_ROW[$i]))
            local sc=$((center_col + RIP_COL[$i]))
            if [ "$sr" -ge 5 ] && [ "$sr" -lt "$PANE_H" ] && [ "$sc" -ge 1 ] && [ "$sc" -le "$PANE_W" ]; then
                local edge=$(( progress - dist + (tick % 5) * 20 ))
                if [ "$dist" -eq 0 ]; then
                    frame+="\033[${sr};${sc}H${color}●${RESET}"
                elif [ "$edge" -lt 150 ]; then
                    frame+="\033[${sr};${sc}H${color}●${RESET}"
                elif [ "$edge" -lt 350 ]; then
                    frame+="\033[${sr};${sc}H${COLOR_MID}○${RESET}"
                elif [ "$edge" -lt 600 ]; then
                    frame+="\033[${sr};${sc}H${COLOR_MDIM}◦${RESET}"
                else
                    frame+="\033[${sr};${sc}H${DIM}·${RESET}"
                fi
            fi
        fi
    done
}

render_wave() {
    local max_amp=$((PANE_H / 2 - 3))
    local amplitude=$(( progress * max_amp / 1000 ))
    local phase=$(( tick * 2 % 32 ))

    if [ "$amplitude" -lt 1 ]; then
        for ((c=3; c<=PANE_W-2; c+=2)); do
            frame+="\033[${center_row};${c}H${DIM}·${RESET}"
        done
        return
    fi

    for ((c=1; c<=PANE_W; c++)); do
        local idx=$(( (c * 2 + phase) % 32 ))
        local sin_val=${SIN32[$idx]}
        local y_off=$(( sin_val * amplitude / 1000 ))
        local crest=$((center_row - y_off))

        # Fill from crest toward center (max 3 rows)
        local fill_start=$crest fill_end=$center_row
        if [ "$y_off" -lt 0 ]; then
            fill_start=$center_row; fill_end=$crest
        fi
        local depth=0
        for ((fr=fill_start; fr<=fill_end && depth<3; fr++)); do
            if [ "$fr" -ge 5 ] && [ "$fr" -lt "$((PANE_H - 1))" ]; then
                if [ "$depth" -eq 0 ]; then
                    frame+="\033[${fr};${c}H${color}●${RESET}"
                elif [ "$depth" -eq 1 ]; then
                    frame+="\033[${fr};${c}H${COLOR_MID}•${RESET}"
                else
                    frame+="\033[${fr};${c}H${DIM}·${RESET}"
                fi
            fi
            depth=$((depth + 1))
        done

        # Spray at peaks
        local abs_sin=${sin_val#-}
        if [ "$abs_sin" -gt 950 ] && [ "$amplitude" -gt 2 ]; then
            local spray_r=$((crest - 1))
            [ "$y_off" -lt 0 ] && spray_r=$((crest + 1))
            if [ "$spray_r" -ge 5 ] && [ "$spray_r" -lt "$((PANE_H - 1))" ]; then
                frame+="\033[${spray_r};${c}H${DIM}·${RESET}"
            fi
        fi
    done
}

render_helix() {
    local max_amp=$((PANE_H / 2 - 3))
    local amplitude=$(( progress * max_amp / 1000 ))
    local phase=$(( tick * 2 % 32 ))

    if [ "$amplitude" -lt 1 ]; then
        frame+="\033[${center_row};${center_col}H${DIM}·${RESET}"
        return
    fi

    for ((c=1; c<=PANE_W; c++)); do
        local idx1=$(( (c * 2 + phase) % 32 ))
        local y1=$(( SIN32[idx1] * amplitude / 1000 ))
        local row1=$((center_row - y1))
        local idx2=$(( (c * 2 + phase + 16) % 32 ))
        local y2=$(( SIN32[idx2] * amplitude / 1000 ))
        local row2=$((center_row - y2))
        local abs_sin1=${SIN32[$idx1]#-}
        local abs_sin2=${SIN32[$idx2]#-}
        local diff=$((row1 - row2)); diff=${diff#-}

        if [ "$diff" -le 1 ]; then
            # Crossing point
            if [ "$row1" -ge 5 ] && [ "$row1" -lt "$((PANE_H - 1))" ]; then
                frame+="\033[${row1};${c}H${color}╳${RESET}"
            fi
        else
            # Strand 1 (bright)
            if [ "$row1" -ge 5 ] && [ "$row1" -lt "$((PANE_H - 1))" ]; then
                if [ "$abs_sin1" -gt 800 ]; then
                    frame+="\033[${row1};${c}H${color}●${RESET}"
                elif [ "$abs_sin1" -gt 400 ]; then
                    frame+="\033[${row1};${c}H${color}•${RESET}"
                else
                    frame+="\033[${row1};${c}H${COLOR_MID}·${RESET}"
                fi
            fi
            # Strand 2 (mid tone)
            if [ "$row2" -ge 5 ] && [ "$row2" -lt "$((PANE_H - 1))" ]; then
                if [ "$abs_sin2" -gt 800 ]; then
                    frame+="\033[${row2};${c}H${COLOR_MID}●${RESET}"
                elif [ "$abs_sin2" -gt 400 ]; then
                    frame+="\033[${row2};${c}H${COLOR_MID}•${RESET}"
                else
                    frame+="\033[${row2};${c}H${COLOR_MDIM}·${RESET}"
                fi
            fi
            # Rungs every 6 columns
            if [ $((c % 6)) -eq 0 ] && [ "$diff" -gt 2 ]; then
                local mid=$(( (row1 + row2) / 2 ))
                if [ "$mid" -ge 5 ] && [ "$mid" -lt "$((PANE_H - 1))" ]; then
                    frame+="\033[${mid};${c}H${DIM}┊${RESET}"
                fi
            fi
        fi
    done
}

render_rain() {
    local drop_area=$((PANE_H - 4))
    if [ "$drop_area" -lt 2 ]; then drop_area=2; fi
    local splash_zone=$((PANE_H - 3))

    # Puddle shimmer at bottom
    if [ "$progress" -gt 200 ]; then
        for ((pc=2; pc<PANE_W; pc+=3)); do
            if [ $(( (pc + tick / 3) % 5 )) -lt 2 ]; then
                frame+="\033[$((PANE_H-2));${pc}H${DIM}~${RESET}"
            fi
        done
    fi

    for ((d=0; d<NUM_DROPS; d++)); do
        if [ "${DROP_THRESH[$d]}" -le "$progress" ]; then
            local col=$(( ${DROP_SEED[$d]} % (PANE_W - 4) + 3 ))
            local speed=${DROP_SPEED[$d]}
            local offset=${DROP_OFFSET[$d]}
            local row=$(( (tick * speed + offset) % drop_area + 2 ))

            if [ "$col" -ge 1 ] && [ "$col" -le "$PANE_W" ] && [ "$row" -ge 5 ] && [ "$row" -lt "$((PANE_H - 1))" ]; then
                if [ "$row" -ge "$splash_zone" ]; then
                    # Splash
                    frame+="\033[${row};${col}H${COLOR_MID}∙${RESET}"
                    [ "$col" -gt 1 ] && frame+="\033[${row};$((col-1))H${DIM}·${RESET}"
                    [ "$col" -lt "$PANE_W" ] && frame+="\033[${row};$((col+1))H${DIM}·${RESET}"
                elif [ "$speed" -eq 3 ]; then
                    frame+="\033[${row};${col}H${color}│${RESET}"
                    local t1=$((row - 1))
                    [ "$t1" -ge 5 ] && frame+="\033[${t1};${col}H${COLOR_MID}┆${RESET}"
                    local t2=$((row - 2))
                    [ "$t2" -ge 5 ] && frame+="\033[${t2};${col}H${DIM}·${RESET}"
                elif [ "$speed" -eq 2 ]; then
                    frame+="\033[${row};${col}H${color}┆${RESET}"
                    local t1=$((row - 1))
                    [ "$t1" -ge 5 ] && frame+="\033[${t1};${col}H${DIM}·${RESET}"
                else
                    frame+="\033[${row};${col}H${COLOR_MID}·${RESET}"
                fi
            fi
        fi
    done
}

render_orbit() {
    local max_a=$((half_w - 6))
    local max_b=$((PANE_H / 2 - 3))
    local a=$(( max_a * progress / 1000 ))
    local b=$(( max_b * progress / 1000 ))

    # Pulsing center
    local pulse=$(( tick % 20 ))
    if [ "$pulse" -lt 7 ]; then
        frame+="\033[${center_row};${center_col}H${color}✦${RESET}"
    elif [ "$pulse" -lt 14 ]; then
        frame+="\033[${center_row};${center_col}H${COLOR_MID}✧${RESET}"
    else
        frame+="\033[${center_row};${center_col}H${color}✧${RESET}"
    fi

    if [ "$a" -lt 2 ] || [ "$b" -lt 1 ]; then return; fi

    # Outer orbit path (64 points, dashed)
    for ((j=0; j<64; j++)); do
        local row=$(( center_row - SIN64[j] * b / 1000 ))
        local col=$(( center_col + COS64[j] * a / 1000 ))
        if [ "$row" -ge 5 ] && [ "$row" -lt "$PANE_H" ] && [ "$col" -ge 1 ] && [ "$col" -le "$PANE_W" ]; then
            if [ $((j % 8)) -eq 0 ]; then
                frame+="\033[${row};${col}H${DIM}◦${RESET}"
            else
                frame+="\033[${row};${col}H${DIM}·${RESET}"
            fi
        fi
    done

    # Outer comet: 6-dot trail
    local oi=$(( (tick * 2) % 64 ))
    local t_ch=("●" "◉" "○" "◦" "·" "·")
    local t_co=("$color" "$color" "$COLOR_MID" "$COLOR_MID" "$COLOR_MDIM" "$DIM")
    for ((ti=0; ti<6; ti++)); do
        local tidx=$(( (oi - ti + 64) % 64 ))
        local tr=$(( center_row - SIN64[tidx] * b / 1000 ))
        local tc=$(( center_col + COS64[tidx] * a / 1000 ))
        if [ "$tr" -ge 5 ] && [ "$tr" -lt "$PANE_H" ] && [ "$tc" -ge 1 ] && [ "$tc" -le "$PANE_W" ]; then
            frame+="\033[${tr};${tc}H${t_co[$ti]}${t_ch[$ti]}${RESET}"
        fi
    done

    # Inner counter-orbit (40% radius, reverse direction)
    local ia=$(( a * 2 / 5 ))
    local ib=$(( b * 2 / 5 ))
    if [ "$ia" -ge 1 ] && [ "$ib" -ge 1 ]; then
        local ioi=$(( (64 - tick * 3 % 64 + 64) % 64 ))
        local ic_ch=("○" "◦" "·")
        local ic_co=("$COLOR_MID" "$COLOR_MDIM" "$DIM")
        for ((ti=0; ti<3; ti++)); do
            local tidx=$(( (ioi - ti + 64) % 64 ))
            local tr=$(( center_row - SIN64[tidx] * ib / 1000 ))
            local tc=$(( center_col + COS64[tidx] * ia / 1000 ))
            if [ "$tr" -ge 5 ] && [ "$tr" -lt "$PANE_H" ] && [ "$tc" -ge 1 ] && [ "$tc" -le "$PANE_W" ]; then
                frame+="\033[${tr};${tc}H${ic_co[$ti]}${ic_ch[$ti]}${RESET}"
            fi
        done
    fi
}

# ========== GREETINGS ==========
GREETINGS=(
    "AI is thinking… breathe"
    "Models loading, mind rest"
    "Tokens flow, thoughts slow"
    "Let the model work…"
    "Connecting the dots…"
    "Between prompts, breathe"
    "Ideas come between breaths"
    "Pause. Breathe. Ship."
)
GREETING="${GREETINGS[$((RANDOM % ${#GREETINGS[@]}))]}"
FADE_TICKS=10      # 10-frame fade-in
FADEOUT_TICKS=15   # 1.5 second fade-out

# === Stats: log session on exit ===
log_session_stats() {
    local cycles=$((tick / CYCLE_TICKS))
    local duration=$((tick / TICK_RATE))
    local stats_dir="$HOME/.hushflow"
    local stats_file="$stats_dir/stats.log"
    mkdir -p "$stats_dir"
    # Sanitize values: strip tabs and newlines to protect TSV format
    local safe_ex="${EX_NAME//[$'\t\n']/ }"
    local safe_anim="${animation//[$'\t\n']/ }"
    local safe_theme="${theme:-teal}"
    safe_theme="${safe_theme//[$'\t\n']/ }"
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$(date +%s)" "$cycles" "$duration" "$safe_ex" "$safe_anim" "$safe_theme" \
        >> "$stats_file" 2>/dev/null
    hf_log "stats logged: cycles=$cycles duration=${duration}s"
}

# Graceful exit: show summary, "Done" message, fade out, then exit
graceful_exit() {
    # Restore terminal to normal mode before fade-out
    [ -n "${_hf_old_stty:-}" ] && stty "$_hf_old_stty" 2>/dev/null
    # Stop current phase sound, then play completion bell
    type hf_stop_sound &>/dev/null && hf_stop_sound
    type hf_play_sound &>/dev/null && hf_play_sound complete
    # Log stats
    log_session_stats

    # Session summary
    local cycles=$((tick / CYCLE_TICKS))
    local duration=$((tick / TICK_RATE))
    local summary="${cycles} cycles · ${duration}s"

    # Logo + Done centered on screen
    local logo="HushFlow"
    local done_msg="· Done ·"
    local logo_row=$(( PANE_H / 2 - 1 ))
    local done_row=$(( PANE_H / 2 + 1 ))
    local logo_col=$(( (PANE_W - ${#logo}) / 2 + 1 ))
    local done_col=$(( (PANE_W - ${#done_msg}) / 2 + 1 ))

    for ((f=0; f<FADEOUT_TICKS; f++)); do
        local out=""
        # Clear entire screen
        for ((r=1; r<=PANE_H; r++)); do
            out+="\033[${r};1H\033[2K"
        done
        # Logo in main color, centered
        out+="\033[${logo_row};${logo_col}H${COLOR_IN}${logo}${RESET}"
        # "Done" below logo
        out+="\033[${done_row};${done_col}H${COLOR_MID}${done_msg}${RESET}"
        # Session summary below Done
        local sum_row=$((PANE_H / 2 + 3))
        local sum_col=$(( (PANE_W - ${#summary}) / 2 + 1 ))
        out+="\033[${sum_row};${sum_col}H${DIM}${summary}${RESET}"
        # Fade: apply faint after first 5 frames
        if [ "$f" -ge 8 ]; then
            out="\033[2m${out}"
        fi
        printf '%b' "$out"
        sleep 0.1
    done
    # Final clear
    printf '\033[2J\033[H'

    # Ghostty bug: "Process exited" flashes before monitor can dismiss it.
    # Hide window off-screen BEFORE exiting so the message is invisible.
    if [ -d "/Applications/Ghostty.app" ] && [ -n "${HUSHFLOW_WINDOW_TITLE:-}" ]; then
        osascript -e "
            tell application \"System Events\" to tell process \"Ghostty\"
                try
                    set w to first window whose name contains \"HushFlow\"
                    set position of w to {-9999, -9999}
                end try
            end tell" &>/dev/null
    fi

    exit 0
}

# ========== MAIN LOOP ==========
tick=0

while true; do
    [ ! -f "$MARKER_FILE" ] && graceful_exit

    cycle_tick=$((tick % CYCLE_TICKS))
    t=$cycle_tick

    if [ "$t" -lt "$IN_TICKS" ]; then
        phase="Breathe in"; color="$COLOR_IN"
        remaining_ticks=$((IN_TICKS - t))
        linear=$(( t * 1000 / IN_TICKS ))
        ease "$linear"
        if [ "$EX_TYPE" = "double_inhale" ]; then
            progress=$(( EASE_OUT * 850 / 1000 ))
        else
            progress=$EASE_OUT
        fi
    elif [ "$t" -lt "$((IN_TICKS + H1_TICKS))" ]; then
        remaining_ticks=$((IN_TICKS + H1_TICKS - t))
        if [ "$EX_TYPE" = "double_inhale" ]; then
            phase="Sip in"; color="$COLOR_IN"
            pt=$((t - IN_TICKS))
            linear=$(( pt * 1000 / H1_TICKS ))
            ease "$linear"
            progress=$(( 850 + EASE_OUT * 150 / 1000 ))
        else
            phase="Hold"; color="$COLOR_IN"
            progress=1000
        fi
    elif [ "$t" -lt "$((IN_TICKS + H1_TICKS + EX_TICKS))" ]; then
        phase="Breathe out"; color="$COLOR_OUT"
        remaining_ticks=$((IN_TICKS + H1_TICKS + EX_TICKS - t))
        pt=$((t - IN_TICKS - H1_TICKS))
        linear=$(( pt * 1000 / EX_TICKS ))
        ease "$linear"
        progress=$((1000 - EASE_OUT))
    else
        phase="Hold"; color="$COLOR_OUT"
        remaining_ticks=$((CYCLE_TICKS - t))
        progress=0
    fi

    # Play sound on phase transition (with duration matching + skip zero-length holds)
    if [ "$phase" != "$_last_phase" ] && type hf_play_sound &>/dev/null; then
        case "$phase" in
            "Breathe in") hf_play_sound inhale "$IN_DUR" ;;
            "Sip in")     hf_play_sound inhale "$HOLD1_DUR" ;;
            "Breathe out") hf_play_sound exhale "$EX_DUR" ;;
            "Hold")
                _hold_dur="$HOLD1_DUR"
                [ "$t" -ge "$((IN_TICKS + H1_TICKS + EX_TICKS))" ] && _hold_dur="$HOLD2_DUR"
                if [ "$_hold_dur" != "0" ]; then
                    hf_play_sound hold "$_hold_dur"
                fi
                ;;
        esac
        _last_phase="$phase"
    fi

    remaining_s=$(( (remaining_ticks + TICK_RATE - 1) / TICK_RATE ))

    # Build frame buffer (clear animation area: row 5 to PANE_H-2)
    # Row 4 is blank spacer between greeting and animation for visual breathing room
    frame=""
    for ((r=5; r<PANE_H; r++)); do
        frame+="\033[${r};1H\033[2K"
    done

    case "$animation" in
        ripple) render_ripple ;;
        wave)   render_wave ;;
        orbit)  render_orbit ;;
        helix)  render_helix ;;
        rain)   render_rain ;;
        constellation) render_constellation ;;
        *)
            # Try plugin-provided render function, fallback to constellation
            if type "render_${animation}" &>/dev/null; then
                "render_${animation}"
            else
                hf_log "unknown animation '$animation', falling back to constellation"
                render_constellation
            fi
            ;;
    esac

    # Fade-in: first FADE_TICKS frames use ANSI faint attribute
    fade_prefix=""
    if [ "$tick" -lt "$FADE_TICKS" ]; then
        fade_prefix="\033[2m"
    fi

    # Cycle counter
    cycle_num=$(( tick / CYCLE_TICKS + 1 ))

    # Row 1 is blank padding (symmetric with bottom)

    # Title (row 2) — bold, anchoring element
    title="HushFlow"
    tc=$(( (PANE_W - ${#title}) / 2 + 1 ))
    [ "$tc" -lt 1 ] && tc=1
    frame+="\033[2;1H\033[2K\033[2;${tc}H${fade_prefix}\033[1m${color}${title}${RESET}"

    # Subtitle (row 3) — dimmed, recedes into background
    gc=$(( (PANE_W - ${#GREETING}) / 2 + 1 ))
    [ "$gc" -lt 1 ] && gc=1
    frame+="\033[3;1H\033[2K\033[3;${gc}H${fade_prefix}${DIM}${GREETING}${RESET}"

    # Exercise name + cycle (row PANE_H-1) — subdued, secondary info
    info_row=$((PANE_H - 1))
    info_text="${EX_NAME}  ·  Cycle ${cycle_num}"
    ic=$(( (PANE_W - ${#info_text}) / 2 + 1 ))
    frame+="\033[${info_row};1H\033[2K\033[${info_row};${ic}H${fade_prefix}${DIM}${info_text}${RESET}"

    # Status (bottom of content area)
    status="${phase}... ${remaining_s}s"
    sc_pos=$(( (PANE_W - ${#status}) / 2 + 1 ))
    frame+="\033[${PANE_H};1H\033[2K\033[${PANE_H};${sc_pos}H${fade_prefix}\033[1m${color}${status}${RESET}"

    # ESC hint (pinned to actual terminal bottom, extra faint for subtlety)
    if [ -t 0 ]; then
        _esc_hint="ESC to close"
        _esc_pos=$(( (PANE_W - ${#_esc_hint}) / 2 + 1 ))
        _term_bottom=$(tput lines 2>/dev/null || echo "$PANE_H")
        frame+="\033[${_term_bottom};1H\033[2K\033[${_term_bottom};${_esc_pos}H\033[2;38;2;110;115;120m${_esc_hint}${RESET}"
    fi

    printf '%b' "$frame"

    # Frame delay (sleep) + non-blocking key check (dd)
    # dd respects stty min 0 time 0 (instant return), unlike bash read -n1
    # which overrides stty settings on bash 3.2.
    sleep 0.1
    _hf_key=""
    if [ -t 0 ]; then
        _hf_key=$(dd bs=1 count=1 2>/dev/null) || true
    fi

    # ESC key detection
    if [ "$_hf_key" = $'\x1b' ]; then
        # Distinguish bare ESC from escape sequences (arrow keys, etc.)
        _hf_seq=$(dd bs=1 count=1 2>/dev/null) || true
        if [ -z "$_hf_seq" ]; then
            # Bare ESC pressed — close window
            hf_log "ESC pressed, closing"
            rm -f "$MARKER_FILE"
            graceful_exit
        fi
    fi

    tick=$((tick + 1))
done
