#!/bin/bash
# Detect terminal background color via OSC 11 query
# Returns: "dark", "light", or "unknown"

detect_background() {
    [ ! -t 0 ] && echo "unknown" && return
    [ ! -t 1 ] && echo "unknown" && return

    local response="" old_settings=""
    old_settings=$(stty -g 2>/dev/null) || { echo "unknown"; return; }
    stty raw -echo min 0 time 2 2>/dev/null || { stty "$old_settings" 2>/dev/null; echo "unknown"; return; }

    printf '\033]11;?\033\\' > /dev/tty 2>/dev/null

    local char=""
    while IFS= read -r -n1 -t 1 char 2>/dev/null; do
        response+="$char"
        [[ "$response" == *'\' ]] && break
        [[ "$response" == *$'\a' ]] && break
        [ ${#response} -gt 50 ] && break
    done < /dev/tty

    stty "$old_settings" 2>/dev/null

    if [[ "$response" =~ rgb:([0-9a-fA-F]+)/([0-9a-fA-F]+)/([0-9a-fA-F]+) ]]; then
        local r_hex="${BASH_REMATCH[1]:0:2}"
        local g_hex="${BASH_REMATCH[2]:0:2}"
        local b_hex="${BASH_REMATCH[3]:0:2}"
        local r=$((16#$r_hex)) g=$((16#$g_hex)) b=$((16#$b_hex))
        local lum=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
        [ "$lum" -lt 128 ] && echo "dark" || echo "light"
    else
        echo "unknown"
    fi
}
