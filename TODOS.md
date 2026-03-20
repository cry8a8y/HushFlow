# HushFlow — Project Status

## Completed (v1.0 → v2.0)

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
- **v2.0 (2026-03-18)**: Session notifications, permission-aware breathing, random animation default, sound system, 290+ tests, Ghostty optimizations, 5 community themes.

---

## v3 Growth & Platform Expansion (CEO Review 2026-03-20)

> Design doc: [docs/designs/v3-growth-platform.md](docs/designs/v3-growth-platform.md)

### Phase 1: Foundations

#### Shared Exercises Config
- **What**: Extract breathing mode parameters (inhale/exhale/hold times) to `exercises.json`, consumed by both Bash and TypeScript.
- **Why**: Single source of truth for CLI and future VS Code extension. Avoids sync bugs.
- **Priority**: P1
- **Effort**: S
- **Depends on**: Nothing

#### Guided Onboarding / First-Run Experience
- **What**: Interactive first-run wizard that walks users through choosing exercise, theme, and animation, followed by a 5-second live demo.
- **Why**: 1,261 clones but only 2 stars — first impression determines retention.
- **Priority**: P1
- **Effort**: M
- **Depends on**: Nothing

### Phase 2: Distribution

#### Homebrew Formula
- **What**: `brew install hushflow` via a Homebrew tap (`cry8a8y/homebrew-hushflow`).
- **Why**: Zero-friction install for macOS/Linux. Higher trust than `curl | bash`. Required for landing page.
- **Priority**: P1
- **Effort**: S
- **Depends on**: Nothing

#### Landing Page (GitHub Pages)
- **What**: Project website with animated demo, SEO meta tags, one-line install commands, feature highlights.
- **Why**: Discovery is 0%. No search engine can find HushFlow today. This is the highest-leverage single change.
- **Priority**: P1
- **Effort**: S
- **Depends on**: Homebrew (to show `brew install` on the page)

### Phase 3: Shareability & Community

#### Stats Card
- **What**: `hushflow stats --card` generates a shareable ASCII art stats card for Twitter, Discord, GitHub profile READMEs.
- **Why**: Community flywheel fuel — users do your marketing for you.
- **Priority**: P2
- **Effort**: S
- **Depends on**: Nothing

#### Awesome Lists & Community Submissions
- **What**: Submit PRs to awesome-cli-apps, awesome-developer-tools, awesome-shell. Prepare HN/Reddit posts.
- **Why**: Zero-cost distribution with high ROI. Each list has tens of thousands of stars.
- **Priority**: P2
- **Effort**: S
- **Depends on**: Landing Page (to link to)

### Phase 4: Platform Expansion

#### VS Code / Cursor Extension
- **What**: WebView sidebar panel with Canvas breathing animations. Detects AI thinking and auto-shows breathing.
- **Why**: TAM expansion 10x — most developers use IDEs, not CLI.
- **Priority**: P2
- **Effort**: L
- **Depends on**: Shared exercises.json
- **Architecture**: Monorepo (`extension/` subdirectory), shared themes and breathing params.

---

## Future Items (P3 — Deferred)

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

### JetBrains / Neovim Plugin
- **What**: IDE plugins for IntelliJ family and Neovim (Lua).
- **Why**: Further platform expansion after VS Code proves the model.
- **Priority**: P3
- **Effort**: L
- **Depends on**: VS Code Extension (proves the architecture)

### DESIGN.md — Formal Design System
- **What**: Create DESIGN.md defining color system (5-layer RGB), typography (monospace), spacing (8px base grid), animation principles, and brand guidelines.
- **Why**: Ensures visual consistency across Landing Page, VS Code Extension, and Stats Card SVG as the product expands beyond CLI.
- **Priority**: P3
- **Effort**: S
- **Depends on**: Phase 2 Landing Page (more meaningful after multiple UI surfaces exist)
