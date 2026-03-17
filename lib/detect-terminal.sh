#!/bin/bash
# Detect available terminal emulator for opening companion windows.
# Returns one of: ghostty, iterm, terminal-app, gnome-terminal, konsole,
#                 xfce4-terminal, xterm, windows-terminal, powershell, inline

detect_terminal() {
    # User override
    if [ -n "${HUSHFLOW_TERMINAL:-}" ]; then
        echo "$HUSHFLOW_TERMINAL"
        return
    fi

    case "$(uname -s)" in
        Darwin)
            if [ -d "/Applications/Ghostty.app" ]; then echo "ghostty"
            elif [ -d "/Applications/iTerm.app" ]; then echo "iterm"
            else echo "terminal-app"
            fi
            ;;
        Linux)
            if command -v ghostty &>/dev/null; then echo "ghostty-linux"
            elif command -v gnome-terminal &>/dev/null; then echo "gnome-terminal"
            elif command -v konsole &>/dev/null; then echo "konsole"
            elif command -v xfce4-terminal &>/dev/null; then echo "xfce4-terminal"
            elif command -v xterm &>/dev/null; then echo "xterm"
            else echo "inline"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            if command -v wt.exe &>/dev/null; then echo "windows-terminal"
            elif command -v powershell.exe &>/dev/null; then echo "powershell"
            else echo "inline"
            fi
            ;;
        *)
            echo "inline"
            ;;
    esac
}

# If sourced, export function. If run directly, print result.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    detect_terminal
fi
