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
- **Go Public Prep**: CONTRIBUTING.md, CLAUDE.md, CI (GitHub Actions), README v1.0 + 4 語言翻譯同步.

---

## v1.1 Bug Fixes & Polish — ✅ All Fixed (2026-03-18)

- ~~P0: wrap.sh handle_signal 未定義~~ → 已定義 `handle_signal()`
- ~~P0: Slash command `/hushflow` 過時~~ → 已更新含所有 v1.0 功能
- ~~P1: 主題驗證~~ → `set-exercise.sh` 設定時驗證 theme 是否存在
- ~~P1: CLI 打錯字只顯示 help~~ → 加 "Unknown command" 錯誤訊息
- ~~P1: Stats 空值顯示~~ → 加空值檢查
- ~~P1: 安裝後無 onboarding~~ → 加使用說明
- ~~P2: Config delay 非數字保護~~ → wrap.sh + open-window.sh 驗證
- ~~P2: install.ps1 缺少 backup~~ → 寫入前備份
- ~~P2: Plugin source 無錯誤處理~~ → bash -n 語法檢查後才 source

- ~~P2: Hook 開視窗失敗靜默~~ → inline fallback 寫入 debug log + ui-fallback 標記，doctor 可偵測

---

## Future Items (Deferred)

### ~~Repo → Public~~ ✅ (2026-03-18)

### Homebrew Formula
- **What**: `brew install hushflow` via a Homebrew tap (`cry8a8y/homebrew-hushflow`).
- **Why**: One-line install for macOS/Linux users. 需要建獨立 repo。
- **Priority**: P2
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
