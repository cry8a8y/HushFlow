# HushFlow — Development Progress

## What's Done

### Core Engine (`breathe-compact.sh`)
- 6 built-in animations: Constellation, Ripple, Wave, Orbit, Helix, Rain
- 3 color themes: Teal (default), Twilight, Amber — with 5-level color gradients
- 4 breathing exercises: Coherent (5.5s), Physiological Sigh, Box, 4-7-8
- Permanent title ("HushFlow") + AI-context subtitle on every frame
- Cycle counter: `Coherent · Cycle 3`
- 10-frame fade-in on startup (customizable via `HUSHFLOW_FADE_TICKS`)
- Graceful exit: centered HushFlow logo + "· Done ·" with fade-out
- Plugin API: custom animations via `~/.hushflow/plugins/*.sh`
- Session-scoped temp directories (`/tmp/hushflow-$$`)
- Security: theme JSON validation before eval, plugin function auditing, config value sanitization

### Sound System (`lib/sound.sh`)
- Async audio playback (ffplay/mpv/afplay/paplay priority detection)
- Duration-matched sound files (e.g., `inhale-5.5s.ogg`) with fallback to base files
- Crossfade: new sound starts before old is killed (150ms overlap)
- Sound disabled by default (`sound=false`); enable with `hushflow sound on`

### Window Launcher (`hooks/open-window.sh`)
- Cross-platform: Ghostty, Terminal.app, iTerm2, gnome-terminal, konsole, xfce4, xterm, Windows Terminal
- Tmux integration: pane mode + popup mode (merged into single launcher)
- Same-screen positioning: centers on current Ghostty/Terminal window
- Configurable delay before window appears
- BREATHE_ENV propagates session, config, title, and fade ticks to new terminals

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
- Registers 4 Claude Code hooks: UserPromptSubmit, Stop, PermissionRequest, PostToolUse

### Testing
- 138+ smoke tests (`test/smoke-test.sh`)
- 19 terminal detection tests (`test/terminal-detect-test.sh`)
- 27 sound system tests (`test/sound-test.sh`)
- 76+ installer contract tests (`test/install-contract-test.sh`)
- 31 E2E install tests (`test/e2e-install-test.sh`)
- UI layout tests (`scripts/test-ui-layout.sh` — requires tmux)
- GitHub Actions CI: ubuntu + macOS matrix

### Hooks
- `on-start.sh` — creates session dir + marker, dispatches UI mode
- `on-stop.sh` — removes marker, cleans up window/pane/session, sends macOS notification with session summary (exercise name, cycles, duration)
- `on-permission.sh` — pauses breathing window on PermissionRequest
- `on-resume.sh` — smart resume after permission approval (3-tier: ≤30s auto, 30-60s slow, >60s notify); exports `HUSHFLOW_SESSION_DIR` for child processes
- `lib/hook-common.sh` — shared bootstrap (hf_log, CONFIG_DIR, SESSION_DIR loading)

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
│   ├── on-permission.sh    # PermissionRequest pause hook
│   ├── on-resume.sh        # PostToolUse smart resume hook
│   ├── open-window.sh      # Cross-platform window launcher
│   └── open-tmux-popup.sh  # Tmux-specific launcher (legacy)
├── lib/
│   ├── hook-common.sh      # Shared hook bootstrap
│   ├── detect-terminal.sh  # Terminal detection logic
│   ├── detect-background.sh # Background color detection (OSC 11)
│   ├── sound.sh            # Async audio playback + crossfade
│   ├── stats.sh            # Session statistics (TSV)
│   └── wrap.sh             # Universal CLI wrapper
├── sounds/                 # Audio files (Opus codec in .ogg containers)
├── themes/                 # Community JSON themes
├── test/
│   ├── smoke-test.sh       # 138+ tests
│   ├── terminal-detect-test.sh  # 19 tests
│   ├── sound-test.sh       # 27 tests
│   ├── install-contract-test.sh # 76+ tests
│   └── e2e-install-test.sh # 31 tests
├── .github/workflows/
│   └── ci.yml              # GitHub Actions CI
├── TODOS.md                # Deferred items
└── docs/
    ├── PROGRESS.md         # This file
    ├── ARCHITECTURE.md     # Architecture overview
    ├── README.zh-TW.md     # 繁體中文文件
    └── README.zh-CN.md     # 简体中文文件
```
