# HushFlow Handoff

## Current Direction

- Project display name is now `HushFlow`.
- Goal shifted from tmux-first UI to a standalone Ghostty window for Claude.
- Existing `/mindful` command name and `~/.claude/mindful` config path were intentionally kept for compatibility during prototyping.

## Changes Made

- Added standalone Ghostty window launcher:
  - [hooks/open-standalone-window.sh](/Users/danawang/Mindful-Claude/hooks/open-standalone-window.sh)
- Added compact animation tuned for a small standalone window:
  - [breathe-compact.sh](/Users/danawang/Mindful-Claude/breathe-compact.sh)
- Updated Claude hooks to support standalone mode by default:
  - [hooks/on-start.sh](/Users/danawang/Mindful-Claude/hooks/on-start.sh)
  - [hooks/on-stop.sh](/Users/danawang/Mindful-Claude/hooks/on-stop.sh)
- Kept tmux modes as fallback:
  - `MINDFUL_UI_MODE=tmux-pane`
  - `MINDFUL_UI_MODE=tmux-popup`
  - `MINDFUL_UI_MODE=off`
- Updated installer and docs:
  - [install.sh](/Users/danawang/Mindful-Claude/install.sh)
  - [README.md](/Users/danawang/Mindful-Claude/README.md)
  - [commands/mindful.md](/Users/danawang/Mindful-Claude/commands/mindful.md)

## Discussion Summary

- `tmux` was tested as the default Ghostty workflow and rejected for daily local use.
- Main reasons:
  - UX felt worse than native Ghostty tabs.
  - Mouse wheel behavior in tmux was poor.
  - Too much interaction overhead for multi-agent local work.
- The user wants:
  - Native Ghostty workflow
  - No extra Ghostty app icon in the macOS Dock
  - A smaller, calmer companion window during Claude thinking time

## What Works

- Standalone Ghostty window no longer creates a second Ghostty Dock instance.
- Compact animation no longer breaks layout in the smaller window.
- Branding is updated to `HushFlow` in user-facing copy.

## Known Issues

- Standalone window size is still too large.
- Attempted AppleScript bounds adjustment did not visibly resize the Ghostty window.
- Lowering font size helped density but made text too small.

## Recommended Next Steps

1. Investigate whether Ghostty AppleScript can resize windows via standard window properties or whether a different macOS automation path is needed.
2. If Ghostty resizing remains limited, consider:
   - Even more compact layout with fewer rows
   - Alternate presentation outside Ghostty
3. After UI stabilizes, decide whether to migrate:
   - `/mindful` -> `/hushflow`
   - `~/.claude/mindful` -> `~/.claude/hushflow`
   - repo folder name

## Quick Test Commands

Open test window:

```sh
echo test > /tmp/mindful-claude-working
MINDFUL_DELAY_SECONDS=0 /Users/danawang/Mindful-Claude/hooks/open-standalone-window.sh
```

Close test window:

```sh
rm -f /tmp/mindful-claude-working
/Users/danawang/Mindful-Claude/hooks/on-stop.sh
```
