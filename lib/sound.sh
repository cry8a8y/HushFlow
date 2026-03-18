#!/bin/bash
# HushFlow sound helper — async audio playback
# Source this file, then call: hf_play_sound <sound_name> [duration_secs]

_HF_SOUND_PLAYER=""
_HF_SOUND_ENABLED=""
_HF_SOUND_PID=""

_hf_detect_sound_player() {
    [ -n "$_HF_SOUND_PLAYER" ] && return
    if command -v ffplay &>/dev/null; then
        _HF_SOUND_PLAYER="ffplay"
    elif command -v mpv &>/dev/null; then
        _HF_SOUND_PLAYER="mpv"
    elif command -v afplay &>/dev/null; then
        _HF_SOUND_PLAYER="afplay"
    elif command -v paplay &>/dev/null; then
        _HF_SOUND_PLAYER="paplay"
    else
        _HF_SOUND_PLAYER="none"
    fi
}

_hf_check_sound_enabled() {
    [ -n "$_HF_SOUND_ENABLED" ] && return
    local config="${HUSHFLOW_CONFIG_DIR:-$HOME/.claude/hushflow}/config"
    if [ -f "$config" ] && grep -q "^sound=true" "$config"; then
        _HF_SOUND_ENABLED="true"
    else
        _HF_SOUND_ENABLED="false"
    fi
}

# Kill any currently playing sound
hf_stop_sound() {
    if [ -n "$_HF_SOUND_PID" ] && kill -0 "$_HF_SOUND_PID" 2>/dev/null; then
        kill "$_HF_SOUND_PID" 2>/dev/null
        wait "$_HF_SOUND_PID" 2>/dev/null
    fi
    _HF_SOUND_PID=""
}

hf_play_sound() {
    _hf_check_sound_enabled
    [ "$_HF_SOUND_ENABLED" != "true" ] && return 0
    _hf_detect_sound_player
    [ "$_HF_SOUND_PLAYER" = "none" ] && return 0

    local sound_name="$1"
    local duration="${2:-}"
    local sound_file=""
    local _hf_dir="${HUSHFLOW_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

    # Try duration-matched file first (e.g., inhale-5.5s.ogg), then fall back to base
    for _dir in "$HOME/.hushflow/sounds" "$_hf_dir/sounds"; do
        if [ -n "$duration" ]; then
            for ext in ogg wav mp3; do
                [ -f "$_dir/${sound_name}-${duration}s.${ext}" ] && sound_file="$_dir/${sound_name}-${duration}s.${ext}" && break 2
            done
        fi
        for ext in ogg wav mp3; do
            [ -f "$_dir/${sound_name}.${ext}" ] && sound_file="$_dir/${sound_name}.${ext}" && break 2
        done
    done

    [ -z "$sound_file" ] && return 0

    # Kill previous sound before playing new one
    hf_stop_sound

    # If we found a duration-matched file, play it directly (already has fade-out baked in).
    # Otherwise use the player's duration flag as fallback truncation.
    local _need_truncate=""
    if [ -n "$duration" ] && [[ "$sound_file" != *"-${duration}s."* ]]; then
        _need_truncate="1"
    fi

    case "$_HF_SOUND_PLAYER" in
        ffplay)
            if [ -n "$_need_truncate" ]; then
                ffplay -nodisp -autoexit -loglevel quiet -t "$duration" "$sound_file" &>/dev/null &
            else
                ffplay -nodisp -autoexit -loglevel quiet "$sound_file" &>/dev/null &
            fi
            ;;
        mpv)
            if [ -n "$_need_truncate" ]; then
                mpv --no-video --really-quiet --end="$duration" "$sound_file" &>/dev/null &
            else
                mpv --no-video --really-quiet "$sound_file" &>/dev/null &
            fi
            ;;
        afplay)
            if [ -n "$_need_truncate" ]; then
                afplay -t "$duration" "$sound_file" &>/dev/null &
            else
                afplay "$sound_file" &>/dev/null &
            fi
            ;;
        paplay)
            paplay "$sound_file" &>/dev/null &
            ;;
    esac
    _HF_SOUND_PID=$!
}
