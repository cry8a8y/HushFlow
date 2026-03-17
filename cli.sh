#!/bin/bash
# HushFlow CLI entry point (for npx usage)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-help}" in
    install)
        exec bash "$SCRIPT_DIR/install.sh" "${@:2}"
        ;;
    uninstall)
        exec bash "$SCRIPT_DIR/install.sh" --uninstall
        ;;
    config|set)
        exec bash "$SCRIPT_DIR/set-exercise.sh" "${@:2}"
        ;;
    theme)
        exec bash "$SCRIPT_DIR/set-exercise.sh" theme "${@:2}"
        ;;
    animation|anim)
        exec bash "$SCRIPT_DIR/set-exercise.sh" animation "${@:2}"
        ;;
    doctor)
        exec bash "$SCRIPT_DIR/doctor.sh"
        ;;
    help|--help|-h|*)
        echo "HushFlow — Turn AI thinking time into mindful breathing."
        echo ""
        echo "Usage:"
        echo "  hushflow install [--target claude|gemini|codex]"
        echo "  hushflow uninstall"
        echo "  hushflow config [hrv|sigh|box|478]"
        echo "  hushflow theme [teal|twilight|amber]"
        echo "  hushflow animation [constellation|ripple|wave|orbit|helix|rain]"
        echo "  hushflow doctor"
        echo "  hushflow help"
        ;;
esac
