#!/usr/bin/env bash
# HushFlow Plugin: Pulse
# A minimal example plugin — concentric rings that pulse with breathing.
#
# Install:
#   cp plugins/example-pulse.sh ~/.hushflow/plugins/pulse.sh
#   hushflow animation pulse
#
# Available variables (provided by breathe-compact.sh):
#   tick          — monotonically increasing frame counter (10 fps)
#   progress      — breathing progress 0‒1000 (0 = exhale, 1000 = inhale)
#   PANE_W/H      — terminal width/height
#   center_row/col — screen center
#   color         — current phase color (COLOR_IN or COLOR_OUT)
#   COLOR_IN/OUT/MID/MDIM, DIM, RESET — theme palette
#   SIN32[], COS32[], SIN64[], COS64[] — trig lookup tables (*1000)
#   frame         — string buffer; append ANSI escape sequences to this

render_pulse() {
    local max_r=$(( PANE_H / 2 - 2 ))
    [ "$max_r" -lt 2 ] && max_r=2

    # 3 concentric rings, staggered by breathing progress
    local ring
    for ring in 0 1 2; do
        # Each ring's radius scales with progress, offset by ring index
        local offset=$(( ring * 333 ))
        local p=$(( (progress + offset) % 1000 ))
        local r=$(( p * max_r / 1000 ))
        [ "$r" -lt 1 ] && continue

        # Intensity fades with distance from center
        local sym="●" clr="$color"
        if [ "$ring" -eq 1 ]; then
            sym="○"; clr="$COLOR_MID"
        elif [ "$ring" -eq 2 ]; then
            sym="·"; clr="$COLOR_MDIM"
        fi

        # Draw ring using 16 points
        local i
        for ((i = 0; i < 16; i++)); do
            local si=$(( i * 4 ))          # index into SIN64 (64 entries)
            local row=$(( center_row + r * SIN64[si] / 1000 ))
            local col=$(( center_col + r * COS64[si] * 2 / 1000 ))

            # Bounds check: stay within drawable area (row 2 to H-1)
            if [ "$row" -ge 4 ] && [ "$row" -lt "$PANE_H" ] \
            && [ "$col" -ge 1 ] && [ "$col" -le "$PANE_W" ]; then
                frame+="\033[${row};${col}H${clr}${sym}${RESET}"
            fi
        done
    done
}
