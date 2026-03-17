#!/bin/bash
# HushFlow sound helper — async audio playback
# Source this file, then call: hf_play_sound <sound_name>

_HF_SOUND_PLAYER=""
_HF_SOUND_ENABLED=""

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

hf_play_sound() {
    _hf_check_sound_enabled
    [ "$_HF_SOUND_ENABLED" != "true" ] && return 0
    _hf_detect_sound_player
    [ "$_HF_SOUND_PLAYER" = "none" ] && return 0

    local sound_name="$1"
    local sound_file=""
    local _hf_dir="${HUSHFLOW_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

    for _dir in "$HOME/.hushflow/sounds" "$_hf_dir/sounds"; do
        for ext in wav mp3 ogg; do
            [ -f "$_dir/${sound_name}.${ext}" ] && sound_file="$_dir/${sound_name}.${ext}" && break 2
        done
    done

    [ -z "$sound_file" ] && return 0

    case "$_HF_SOUND_PLAYER" in
        ffplay)  ffplay -nodisp -autoexit -loglevel quiet "$sound_file" &>/dev/null & disown ;;
        mpv)     mpv --no-video --really-quiet "$sound_file" &>/dev/null & disown ;;
        afplay)  afplay "$sound_file" &>/dev/null & disown ;;
        paplay)  paplay "$sound_file" &>/dev/null & disown ;;
    esac
}
