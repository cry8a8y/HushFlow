# Changelog

## [2.1.0] - 2026-03-20

### Added
- **Guided Onboarding** — First time using HushFlow? A friendly wizard walks you through choosing your breathing exercise, color theme, and shows a 5-second live demo. Triggers automatically on your first AI wait.
- **Homebrew Install** — `brew install cry8a8y/hushflow/hushflow` for one-line setup on macOS and Linux.
- **Version Command** — `hushflow --version` / `hushflow version` / `hushflow -V` now shows the installed version.
- **Re-run Onboarding** — Changed your mind? `hushflow onboarding` lets you reconfigure anytime.
- **23 New Tests** — Onboarding wizard tests covering flags, config writes, edge cases, and CLI integration.

### Changed
- **Install messages** — Post-install output now mentions the onboarding wizard and uses short `hushflow` commands instead of full script paths.

## [2.0.0] - 2026-03-18

Major release — HushFlow is now a polished, production-grade breathing companion for AI-powered terminals.

### Added
- **Session Notifications** — macOS notification after each breathing session shows exercise name, cycles completed, and duration. You'll know exactly how much calm you earned.
- **Permission-Aware Breathing** — Breathing window gracefully pauses when your AI tool asks for permission, and smartly resumes after you approve (3-tier: instant for <30s, gentle for 30-60s, notification for >60s).
- **Random Animation Mode** — Each session picks a different animation style automatically. Every wait feels fresh.
- **Immersive Sound System** — Zen-crafted soundscape with phase-matched audio (inhale bloom, hold stillness, exhale recede, completion bell). Async crossfade, zero UI blocking.
- **290+ Automated Tests** — Smoke tests, unit tests, terminal detection, sound system, installer contracts, E2E install flow, and UI layout verification.
- **Community Themes** — 5 community themes (Catppuccin Mocha, Dracula, Nord, Solarized Dark, Gruvbox) alongside 3 built-in themes.

### Changed
- **Sound off by default** — Sound is now opt-in (`hushflow sound on`) instead of opt-out, for a quieter first experience.
- **Random animation default** — New installs start with `animation=random` instead of `constellation`.
- **Ghostty optimizations** — Eliminated "Process exited" flash, faster window close, direct window ID targeting.

### Fixed
- Permission hook registration — `PermissionRequest` and `PostToolUse` hooks now properly install for Claude Code.
- Session resume after permission — `HUSHFLOW_SESSION_DIR` correctly exported to child processes.
- Sound timing — Audio duration now matches breath phase length, preventing overlap.
- Animation performance — Removed subshells from render loop, improved hook safety.
- Bash 3.2 compatibility — ESC key handling works on macOS default bash.
- Installer config defaults now consistent across `install.sh` and `set-exercise.sh`.

## [1.0.3] - 2026-03-18

- Testing infrastructure: 250 automated tests
- Installer fixes (idempotency, JSON validation)
- README restructured as 3-layer funnel

## [1.0.1] - 2026-03-18

- npm published (`npx hushflow install`)
- GitHub Release v1.0.0

## [1.0.0] - 2026-03-18

- First public release
- 4 breathing exercises, 6 animations, 3 themes
- Cross-platform: macOS, Linux, Windows
- Multi-tool: Claude Code, Gemini CLI, Codex CLI
