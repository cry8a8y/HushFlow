# HushFlow — Development Progress

## What's Done

### Core Engine (`breathe-compact.sh`)
- 6 built-in animations: Constellation, Ripple, Wave, Orbit, Helix, Rain
- 3 color themes: Teal (default), Twilight, Amber — with 5-level color gradients
- 4 breathing exercises: Coherent (5.5s), Physiological Sigh, Box, 4-7-8
- Permanent title ("HushFlow") + AI-context subtitle on every frame
- Cycle counter: `Coherent · Cycle 3`
- 10-frame fade-in on startup
- Graceful exit: centered HushFlow logo + "· Done ·" with fade-out
- Plugin API: custom animations via `~/.hushflow/plugins/*.sh`
- Session-scoped temp directories (`/tmp/hushflow-$$`)

### Window Launcher (`hooks/open-window.sh`)
- Cross-platform: Ghostty, Terminal.app, iTerm2, gnome-terminal, konsole, xfce4, xterm, Windows Terminal
- Tmux integration: pane mode + popup mode (merged into single launcher)
- Same-screen positioning: centers on current Ghostty/Terminal window
- Configurable delay before window appears

### CLI (`cli.sh`)
- `hushflow set-theme <name>` / `hushflow set-exercise <name>` / `hushflow set-animation <name>`
- `hushflow list` — show current config
- `hushflow animation` — list available animations
- `hushflow doctor` — diagnostic checks (deps, scripts, hooks, config, sessions, terminal)

### Installer (`install.sh`)
- Multi-tool: Claude Code, Gemini CLI, Codex CLI
- jq output validation (`validate_and_write`)
- Idempotency detection
- Uninstall support
- 3-second install demo animation

### Testing
- 61 smoke tests (all passing)
- Functional tests: set-exercise, install, session lifecycle
- GitHub Actions CI: ubuntu + macOS matrix

### Hooks
- `on-start.sh` — creates session dir + marker, dispatches UI mode
- `on-stop.sh` — removes marker, cleans up window/pane/session

---

## Known Issues

### 1. Ghostty `window 1` targeting (High)
`open-window.sh` uses `set position/size of window 1` via System Events.
`window 1` is the frontmost window, which may be the user's terminal instead of
the newly created HushFlow window. This can resize the wrong window.

**Attempted fixes:**
- Window count before/after → still uses `window 1` which is ambiguous
- Title-based matching (`if wTitle contains "HushFlow"`) → causes bash heredoc quote conflicts inside `$(osascript <<EOF)`

**Potential fix:** Use Ghostty's window ID (`winId`) to find the correct System Events window. Need to map Ghostty script window ID to System Events window reference.

### 2. Window pixel size vs terminal grid mismatch
Previously hardcoded at 560x420 with COLS=58 ROWS=17. Now auto-calculated from
font size (14) × grid dimensions (36×14), but the cell-size approximation
(`fontSize * 0.6` width, `fontSize * 1.5` height) may not be exact for all fonts.

**Status:** Improved but may need per-font tuning.

---

## File Structure

```
HushFlow/
├── breathe-compact.sh      # Main animation engine
├── cli.sh                  # CLI interface
├── doctor.sh               # Diagnostic tool
├── install.sh              # Multi-tool installer
├── install-remote.sh       # Remote install helper
├── set-exercise.sh         # Config setter (legacy, wrapped by cli.sh)
├── hooks/
│   ├── on-start.sh         # Session start hook
│   ├── on-stop.sh          # Session stop hook
│   ├── open-window.sh      # Cross-platform window launcher
│   └── open-tmux-popup.sh  # Tmux-specific launcher (legacy)
├── lib/
│   └── detect-terminal.sh  # Terminal detection logic
├── test/
│   └── smoke-test.sh       # 61 tests
├── .github/workflows/
│   └── ci.yml              # GitHub Actions CI
├── TODOS.md                # Deferred items
└── docs/
    └── PROGRESS.md         # This file
```
