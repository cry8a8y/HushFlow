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
    wrap)
        shift
        [ "${1:-}" = "--" ] && shift
        exec bash "$SCRIPT_DIR/lib/wrap.sh" "$@"
        ;;
    sound)
        exec bash "$SCRIPT_DIR/set-exercise.sh" sound "${@:2}"
        ;;
    stats)
        exec bash "$SCRIPT_DIR/lib/stats.sh"
        ;;
    doctor)
        exec bash "$SCRIPT_DIR/doctor.sh"
        ;;
    onboarding)
        exec bash "$SCRIPT_DIR/onboarding.sh"
        ;;
    version|--version|-V)
        echo "hushflow 2.1.0"
        ;;
    help|--help|-h)
        echo "HushFlow — Turn AI thinking time into mindful breathing."
        echo ""
        echo "Usage:"
        echo "  hushflow install [--target claude|gemini|codex]"
        echo "  hushflow uninstall"
        echo "  hushflow config [hrv|sigh|box|478]"
        echo "  hushflow theme [teal|twilight|amber|<community-theme>]"
        echo "  hushflow theme list"
        echo "  hushflow animation [random|constellation|ripple|wave|orbit|helix|rain]"
        echo "  hushflow wrap -- <command>      Run breathing while a command executes"
        echo "  hushflow sound [on|off]"
        echo "  hushflow stats                  View session statistics and streak"
        echo "  hushflow doctor"
        echo "  hushflow onboarding             Re-run the first-time setup wizard"
        echo "  hushflow version"
        echo "  hushflow help"
        ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Run 'hushflow help' for usage." >&2
        exit 1
        ;;
esac
