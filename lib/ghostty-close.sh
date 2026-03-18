#!/bin/bash
# Dismiss Ghostty's "Process exited" prompt by sending Return key.
# Used as a fallback; the primary close is handled by open-window.sh monitor.

[ ! -d "/Applications/Ghostty.app" ] && exit 0

osascript <<'EOF'
tell application "System Events"
    tell process "Ghostty"
        try
            set w to first window whose name contains "HushFlow"
            perform action "AXRaise" of w
            delay 0.1
            keystroke return
        end try
    end tell
end tell
EOF
