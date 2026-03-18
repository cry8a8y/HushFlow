# HushFlow Demo — Workflow Context Recording

Output demo.gif

Set Shell "bash"
Set FontSize 15
Set Width 800
Set Height 480
Set Padding 16
Set Theme "Dracula"
Set TypingSpeed 50ms

# Scene 1: Context — user is coding
Type "echo '> Sending prompt to Claude Code...'"
Enter
Sleep 1s

Type "echo '> AI is thinking... HushFlow activates automatically'"
Enter
Sleep 800ms

# Scene 2: Launch breathing animation inline (simulating what HushFlow does)
Type@0ms "mkdir -p /tmp/hushflow-demo && echo $(date +%s) > /tmp/hushflow-demo/working && HUSHFLOW_SESSION_DIR=/tmp/hushflow-demo HUSHFLOW_COLS=72 HUSHFLOW_ROWS=20 TERM=xterm-256color COLORTERM=truecolor bash ~/HushFlow/breathe-compact.sh /tmp/hushflow-demo &"
Enter

# Let animation render for 10 seconds
Sleep 10s

# Scene 3: AI finishes — remove marker to stop animation
Type@0ms "rm -f /tmp/hushflow-demo/working"
Enter
Sleep 2s

Type "echo '> AI finished. HushFlow auto-dismissed.'"
Enter
Sleep 2s
