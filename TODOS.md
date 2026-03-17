# HushFlow — Project Status

## Completed (v1.0)

- **Multiple Breathing Patterns**: Coherent, Physiological Sigh, Box, and 4-7-8 rhythms.
- **6 Animation Styles**: Constellation, Ripple, Wave, Orbit, Helix, Rain — all with SIN64 trig lookups.
- **Plugin API**: Custom animation support via `~/.hushflow/plugins/`.
- **Diagnostic Tool**: `hushflow doctor` for system-wide health checks.
- **Cross-Platform**: macOS (Ghostty/Terminal/iTerm), Linux, Windows Terminal.
- **Multi-Tool Integration**: Claude Code, Gemini CLI, Codex CLI.
- **Session Statistics**: `hushflow stats` — daily/weekly/all-time tracking with streak counter.
- **Community Themes**: JSON-based themes (Catppuccin, Dracula, Nord, Solarized, Gruvbox) + custom theme support.
- **Universal CLI Wrapper**: `hushflow wrap -- <command>` for any long-running command.
- **Sound Integration**: Optional chime sounds at breath transitions (ffplay/mpv/afplay/paplay).
- **Auto-Theme Detection**: OSC 11 terminal background color detection for dark/light theme selection.
- **Streak Counter**: Consecutive-day tracking in session statistics.

---

## Future Items (Deferred)

### Homebrew Formula
- **What**: `brew install hushflow` via a Homebrew tap (`cry8a8y/homebrew-tap`).
- **Why**: One-line install for macOS/Linux users.
- **Priority**: P1
- **Effort**: S

### Guided Onboarding / First-Run Experience
- **What**: Interactive first-run wizard that walks users through choosing exercise, theme, and animation.
- **Why**: Lower barrier to entry for new users.
- **Priority**: P3
- **Effort**: M

### Gamification / Achievements
- **What**: Milestones (100 cycles, 1 hour total, 7-day streak) with badge display in `hushflow stats`.
- **Why**: Habit reinforcement beyond simple streak.
- **Priority**: P3
- **Effort**: M

### Sound Packs
- **What**: Bundled sound packs (nature, lofi, tibetan) downloadable via CLI.
- **Why**: Richer multi-sensory experience without bloating the base install.
- **Priority**: P3
- **Effort**: L

### Warp / Fig Terminal Integration
- **What**: Native integration with Warp and Fig terminals.
- **Priority**: P3
- **Effort**: M

### Export Stats to Markdown / JSON
- **What**: `hushflow stats --export json` for programmatic access.
- **Priority**: P3
- **Effort**: S
