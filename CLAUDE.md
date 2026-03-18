# HushFlow — Claude Code Instructions

## Project Overview

HushFlow is a CLI tool that turns AI coding assistant wait time into guided breathing exercises. Pure Bash implementation, no build step.

## Key Conventions

- **Language**: Code, commits, and CLI output in English. Documentation available in EN/zh-TW/zh-CN/ja.
- **Commit format**: `<type>(<scope>): <description>` — types: feat, fix, docs, test, chore, refactor
- **PR flow**: All changes via branch → PR → merge. No direct push to main.
- **Testing**: Run all test suites before committing. All tests must pass.
  - `bash test/smoke-test.sh` — Core smoke tests (94 tests)
  - `bash test/install-contract-test.sh` — Installer contracts: 3 targets × 7 scenarios (64 tests)
  - `bash test/e2e-install-test.sh` — E2E install flow: fresh, non-git dir, update, reinstall (31 tests)
  - `bash scripts/test-ui-layout.sh --ci` — UI layout tests (requires tmux)
  - `pwsh test/install-ps1-test.ps1` — PowerShell installer tests (Windows only)
  - See `docs/testing/install-matrix.md` for the full cross-platform test matrix

## Architecture

- `breathe-compact.sh` — Core rendering engine (SIN64/COS32 lookup tables, 10fps double-buffer)
- `cli.sh` — CLI entry point for `npx hushflow`
- `set-exercise.sh` — Config management (exercises, themes, animations, sound)
- `hooks/on-start.sh` / `on-stop.sh` — AI tool lifecycle hooks
- `lib/stats.sh` — Session statistics (TSV format: `timestamp\tcycles\tduration\texercise\tanimation\ttheme`)
- `lib/wrap.sh` — Universal CLI wrapper (`hushflow wrap -- <cmd>`)
- `lib/sound.sh` — Async audio playback (ffplay/mpv/afplay/paplay)
- `lib/detect-background.sh` — Terminal background color detection (OSC 11)
- `themes/*.json` — Community themes (JSON with RGB color values)

## Important Rules

- **No external deps in render path** — `jq` only for config/theme loading, never in the animation loop
- **Cross-platform** — must work on macOS, Linux, and Windows (Git Bash)
- **No flicker** — all frame rendering uses double-buffer pattern (build string, single printf)
- **Stats format** — TSV, not JSON. Parsed with awk, no jq dependency for reading.
- **Sound** — always async (`& disown`), never blocks the UI thread
- **Themes** — JSON files with `colors.{primary,secondary,mid,mid_dim,dim}` as `"R;G;B"` strings

## File Patterns

- Shell scripts: `*.sh` (bash, shebang `#!/bin/bash`)
- Config: INI-style key=value in `~/.<tool>/hushflow/config`
- Themes: JSON in `themes/` or `~/.hushflow/themes/`
- Stats: TSV in `~/.hushflow/stats.log`
