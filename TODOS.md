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

## v1.1 Bug Fixes & Polish (P0 — 下次優先)

### BUG: wrap.sh handle_signal 未定義
- **What**: `lib/wrap.sh` 的 `trap handle_signal INT TERM` 引用了不存在的函數，Ctrl+C 會 crash。
- **Fix**: 移除 trap 或定義 `handle_signal() { cleanup; exit 130; }`
- **Priority**: P0
- **Effort**: S

### Slash command `/hushflow` 過時
- **What**: `commands/hushflow.md` 只列 3 主題，沒有 stats/wrap/sound/community themes 的選項。
- **Fix**: 更新 slash command 加入所有 v1.0 功能。
- **Priority**: P0
- **Effort**: S

### 主題/動畫找不到時靜默回退
- **What**: 用戶設了不存在的 theme 或 animation，靜默回退到 teal/constellation，用戶不知道沒生效。
- **Fix**: `set-exercise.sh` 設定時驗證 theme/animation 是否存在，不存在則警告。
- **Priority**: P1
- **Effort**: S

### CLI 打錯字只顯示 help
- **What**: `hushflow cofnig`（typo）→ 直接顯示整個 help，不提示「你是不是要打 config？」
- **Fix**: cli.sh catch-all 加 "Unknown command: $1. Run 'hushflow help' for usage."
- **Priority**: P1
- **Effort**: S

### Stats 空值顯示 `Favorite:  ()`
- **What**: `lib/stats.sh` 當 fav_exercise/fav_animation 為空時顯示不完整。
- **Fix**: 加空值檢查，空的就不顯示 Favorite 行。
- **Priority**: P1
- **Effort**: S

### 安裝後無 onboarding 說明
- **What**: `install.sh` 裝完只說「重啟終端機」，沒解釋第一次使用會看到什麼。
- **Fix**: 安裝結束後加一段簡短說明：「下次你送 prompt 給 AI 時，HushFlow 會自動啟動呼吸動畫。」
- **Priority**: P1
- **Effort**: S

---

## v1.1 穩健性改善 (P2)

### Config delay 非數字保護
- **What**: `delay=abc` 會讓 `sleep` 失敗，UI 不出現。
- **Fix**: on-start.sh / open-window.sh 讀取 delay 後驗證是否為正整數。
- **Priority**: P2
- **Effort**: S

### install.ps1 缺少 settings.json backup
- **What**: Bash 版有 backup，PowerShell 版沒有，覆蓋錯誤無法恢復。
- **Fix**: 寫入前先 `Copy-Item settings.json settings.json.bak`。
- **Priority**: P2
- **Effort**: S

### Plugin source 無錯誤處理
- **What**: 有 syntax error 的 plugin 被 `source` 後靜默失敗，render 函數不存在。
- **Fix**: Source 後檢查 `type render_<name>` 是否存在，不存在則警告並跳過。
- **Priority**: P2
- **Effort**: S

### Hook 開視窗失敗靜默
- **What**: 終端不支援開新視窗時完全沒提示，用戶以為工具壞了。
- **Fix**: Fallback 時寫入 debug log，`hushflow doctor` 可偵測到。
- **Priority**: P2
- **Effort**: M

---

## Future Items (Deferred)

### Repo → Public
- **What**: 把 GitHub repo 從 private 改成 public。
- **Priority**: P1 — v1.0 完成後即可公開
- **Effort**: S

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
