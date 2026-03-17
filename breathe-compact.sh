#!/bin/bash
# Compact breathing animation tuned for a small standalone Ghostty window.

MARKER_FILE="/tmp/mindful-claude-working"
CONFIG_FILE="$HOME/.claude/mindful/config"

COLOR='\033[38;2;247;131;93m'
DIM='\033[38;2;173;151;143m'
RESET='\033[0m'

EXERCISES=(
    "Coherent|5.5|0|5.5|0"
    "Sigh|4|1|10|0|double_inhale"
    "Box|4|4|4|4"
    "4-7-8|4|7|8|0"
)

current_exercise=0
if [ -f "$CONFIG_FILE" ]; then
    saved=$(grep "^exercise=" "$CONFIG_FILE" 2>/dev/null | cut -d= -f2)
    if [ "$saved" -ge 0 ] 2>/dev/null && [ "$saved" -lt ${#EXERCISES[@]} ] 2>/dev/null; then
        current_exercise=$saved
    fi
fi

IFS='|' read -r EX_NAME IN_DUR HOLD1_DUR EX_DUR HOLD2_DUR EX_TYPE <<< "${EXERCISES[$current_exercise]}"
EX_TYPE="${EX_TYPE:-standard}"

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
    local x=$1
    echo $(( x * (2000 - x) / 1000 ))
}

detect_size() {
    local cols lines
    cols=$(tput cols 2>/dev/null)
    lines=$(tput lines 2>/dev/null)
    [ -z "$cols" ] && cols=${COLUMNS:-36}
    [ -z "$lines" ] && lines=${LINES:-12}
    PANE_W=$cols
    PANE_H=$lines
}
detect_size

BAR_MAX=$((PANE_W - 12))
[ "$BAR_MAX" -gt 24 ] && BAR_MAX=24
[ "$BAR_MAX" -lt 10 ] && BAR_MAX=10

declare -a BAR
BAR[0]=""
for ((i=1; i<=BAR_MAX; i++)); do
    BAR[$i]="${BAR[$((i-1))]}█"
done

center_text() {
    local row="$1"
    local text="$2"
    local len=${#text}
    local col=$(((PANE_W - len) / 2 + 1))
    [ "$col" -lt 1 ] && col=1
    printf '\033[%s;1H\033[2K\033[%s;%sH%b' "$row" "$row" "$col" "$text"
}

cleanup() {
    printf '\033[?25h\033[0m\033[2J'
}
trap cleanup EXIT
printf '\033]0;HushFlow\a\033[?25l\033[2J'

tick=0

while true; do
    [ ! -f "$MARKER_FILE" ] && exit 0

    cycle_tick=$((tick % CYCLE_TICKS))
    t=$cycle_tick

    if [ "$t" -lt "$IN_TICKS" ]; then
        phase="inhale"
        remaining_ticks=$((IN_TICKS - t))
        linear=$(( t * 1000 / IN_TICKS ))
        if [ "$EX_TYPE" = "double_inhale" ]; then
            progress=$(( $(ease "$linear") * 850 / 1000 ))
        else
            progress=$(ease "$linear")
        fi
    elif [ "$t" -lt "$((IN_TICKS + H1_TICKS))" ]; then
        remaining_ticks=$((IN_TICKS + H1_TICKS - t))
        if [ "$EX_TYPE" = "double_inhale" ]; then
            phase="sip"
            pt=$((t - IN_TICKS))
            linear=$(( pt * 1000 / H1_TICKS ))
            progress=$(( 850 + $(ease "$linear") * 150 / 1000 ))
        else
            phase="hold"
            progress=1000
        fi
    elif [ "$t" -lt "$((IN_TICKS + H1_TICKS + EX_TICKS))" ]; then
        phase="exhale"
        remaining_ticks=$((IN_TICKS + H1_TICKS + EX_TICKS - t))
        pt=$((t - IN_TICKS - H1_TICKS))
        linear=$(( pt * 1000 / EX_TICKS ))
        progress=$((1000 - $(ease "$linear")))
    else
        phase="hold"
        remaining_ticks=$((CYCLE_TICKS - t))
        progress=0
    fi

    fill=$((BAR_MAX * progress / 1000))
    [ "$fill" -lt 1 ] && [ "$progress" -gt 0 ] && fill=1
    empty=$((BAR_MAX - fill))

    remaining_s=$(( (remaining_ticks + TICK_RATE - 1) / TICK_RATE ))
    spaces=$(printf '%*s' "$empty" '')

    printf '\033[H'
    center_text 2 "${COLOR}HushFlow${RESET}"
    center_text 4 "${DIM}${EX_NAME}${RESET}"
    center_text 6 "${COLOR}[${BAR[$fill]}${spaces}]${RESET}"
    center_text 8 "${COLOR}${phase}  ${remaining_s}s${RESET}"
    center_text 10 "${DIM}Esc to ignore, breathe to reset${RESET}"

    sleep 0.1
    tick=$((tick + 1))
done
