# HushFlow — Project Status

## Completed (v1.0 + v1.0.1)

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
- **Go Public Prep**: CONTRIBUTING.md, CLAUDE.md, CI, README v1.0 + 4 語言翻譯同步.
- **v1.1 Bug Fixes (2026-03-18)**: All P0/P1/P2 from product audit — 10 items fixed.
- **Repo Public (2026-03-18)**: GitHub repo set to public.
- **npm Published (2026-03-18)**: `hushflow@1.0.1` on npm, `npx hushflow install` works.
- **GitHub Release v1.0.0**: First public release with release notes.
- **README CEO Review (2026-03-18)**: Dynamic badges, emotional hook, mobile-friendly layout, Contributing section, Stars badge.

---

## Next Up (v1.1)

### Homebrew Formula
- **What**: `brew install hushflow` via a Homebrew tap (`cry8a8y/homebrew-hushflow`).
- **Why**: One-line install for macOS/Linux users. 需要建獨立 repo。
- **Priority**: P2
- **Effort**: S

### npm bin warning fix
- **What**: `npm publish` 時 `bin[hushflow]` 被 auto-corrected。目前可運作但有警告。
- **Fix**: 確認 `bin/hushflow.js` 的 shebang 和 package.json bin entry 格式正確。
- **Priority**: P2
- **Effort**: S

---

## Future Items (Deferred)

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
