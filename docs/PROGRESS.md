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
- Session-scoped launch script propagates session, config, title, and fade ticks to new terminals
- Falls back cleanly when terminal-specific automation fails

### CLI (`cli.sh`)
- `hushflow config [hrv|sigh|box|478]` — set breathing exercise (or show all config)
- `hushflow theme [teal|twilight|amber|auto|<community>]` — set color theme
- `hushflow theme list` — list all available themes
- `hushflow animation [random|constellation|ripple|wave|orbit|helix|rain]` — set animation style
- `hushflow sound [on|off]` — toggle breath transition sounds
- `hushflow wrap -- <command>` — run breathing while any command executes
- `hushflow stats` — view session statistics and streak
- `hushflow doctor` — diagnostic checks (deps, scripts, hooks, config, sessions, terminal)
- `hushflow install` / `hushflow uninstall` — manage hook installation

### Installer (`install.sh`)
- Multi-tool: Claude Code, Gemini CLI, Codex CLI
- jq output validation (`validate_and_write`)
- Idempotency detection
- Uninstall support
- 3-second install demo animation
- Registers 4 Claude Code hooks: UserPromptSubmit, Stop, PermissionRequest, PostToolUse

### Testing
- 156+ smoke tests (`test/smoke-test.sh`)
- 29 unit tests (`test/unit-test.sh`)
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

### 1. macOS terminal automation variability (Medium)
Ghostty / Terminal.app / iTerm2 window automation depends on AppleScript and
accessibility integration, which can vary across macOS versions and local app
permissions. When terminal-specific launch automation fails, `open-window.sh`
now falls back to inline mode instead of failing the hook.

**Current behavior:**
- Empty config files no longer cause `open-window.sh` to exit under `pipefail`
- Terminal launch commands are emitted via a session-scoped launch script
- Ghostty launch failures degrade to inline mode instead of breaking the session

**Potential follow-up:** Add more terminal-specific diagnostics so `hushflow doctor`
can distinguish "hook installed" from "window launch automation blocked".

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
├── breathe-compact.ps1     # PowerShell animation engine (Windows)
├── cli.sh                  # CLI interface
├── doctor.sh               # Diagnostic tool
├── install.sh              # Multi-tool installer (Bash)
├── install.ps1             # Multi-tool installer (PowerShell/Windows)
├── install-remote.sh       # Remote install helper
├── set-exercise.sh         # Config setter (wrapped by cli.sh)
├── commands/
│   └── hushflow.md         # Claude Code slash command definition
├── hooks/
│   ├── on-start.sh         # Session start hook
│   ├── on-start.ps1        # Session start hook (PowerShell)
│   ├── on-stop.sh          # Session stop hook
│   ├── on-stop.ps1         # Session stop hook (PowerShell)
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
├── plugins/
│   └── example-pulse.sh    # Example custom animation plugin
├── sounds/                 # Audio files (.ogg format)
├── themes/                 # Community JSON themes
│   ├── catppuccin-mocha.json
│   ├── dracula.json
│   ├── gruvbox.json
│   ├── nord.json
│   └── solarized-dark.json
├── test/
│   ├── smoke-test.sh       # 156+ tests
│   ├── unit-test.sh        # 29 tests
│   ├── terminal-detect-test.sh  # 19 tests
│   ├── sound-test.sh       # 27 tests
│   ├── install-contract-test.sh # 76+ tests
│   └── e2e-install-test.sh # 31 tests
├── scripts/
│   └── test-ui-layout.sh   # UI layout tests (requires tmux)
├── .github/workflows/
│   └── ci.yml              # GitHub Actions CI
├── TODOS.md                # Deferred items
└── docs/
    ├── ARCHITECTURE.md     # Architecture overview
    ├── PROGRESS.md         # This file
    ├── PLUGIN-API.md       # Plugin development guide
    ├── ENVIRONMENT.md      # Environment variables reference
    ├── TROUBLESHOOTING.md  # Common issues & fixes
    ├── README.zh-TW.md     # 繁體中文文件
    ├── README.zh-CN.md     # 简体中文文件
    ├── README.ja.md        # 日本語文件
    ├── testing/             # Test documentation
    └── designs/             # Design documents
```
