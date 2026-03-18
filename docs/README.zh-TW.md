<p align="center">
  <img src="hushflow-banner.svg" alt="HushFlow — 把 AI 思考時間變成正念呼吸" width="720" />
</p>

<p align="center">
  <a href="../README.md">English</a> | <b>繁體中文</b> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <a href="https://github.com/cry8a8y/HushFlow/stargazers"><img src="https://img.shields.io/github/stars/cry8a8y/HushFlow?style=social" alt="GitHub Stars" /></a>
  &nbsp;
  <img src="https://img.shields.io/npm/v/hushflow?color=cb3837&label=npm" alt="npm" />
  <img src="https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20Windows-blue" alt="Platform Support" />
</p>

---

為 AI 終端機打造的呼吸層。把每一次等待，變成自動化的平靜片刻 — 跨工具、跨平台。

<br/>
<p align="center">
  <img src="../demo.gif" alt="HushFlow — AI 工作時，呼吸動畫自然出現在你的終端旁邊" width="720" />
</p>
<br/>

## 🚀 60 秒內極速上手

快速、乾淨、零配置。在你下一次呼吸前就安裝完成：

> [!IMPORTANT]
> **前置需求：** 安裝前請確保系統已安裝 `bash` (4.0+), `git` 以及 `jq`。

### 方法 1：Unix / macOS（最快推薦）
Linux 或 macOS 使用者的最乾淨選擇。不需要 Node.js。
```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | bash
```

### 方法 2：Windows (PowerShell)
完整支援 Windows Terminal，相容 PowerShell Core 與 WinPS。
```powershell
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
.\install.ps1
```

### 方法 3：Node.js / npm
如果你習慣用 npm 管理工具，或想直接試用 (`npx`)：
```bash
npm install -g hushflow
hushflow install
# 或使用：npx hushflow install
```

**這 60 秒內發生了什麼？**
1. 🔌 **即時鉤子**：自動與你的 AI 工具（Claude, Gemini 等）連動。
2. ⚙️ **自動配置**：在 `~/.<tool>/hushflow/config` 建立你的專屬設定。
3. ✅ **準備呼吸**：執行 `hushflow doctor` 確認一切就緒。

---

## ✅ 驗證安裝

完成安裝程式後：
1. **重啟** 你的 AI 終端工具（例如：Claude Code）。
2. 送出任何 **指令/對話**（例如："你好"）。
3. **等待 5 秒** — 呼吸視窗會自然出現在你的終端機旁邊。

---

## 🛠️ 支援的 AI 工具

| 工具 | 🟢 啟動 Hook | 🔴 停止 Hook | 狀態 |
|------|----------|----------|------|
| **Claude Code** | `UserPromptSubmit` | `Stop` | ✅ 完整支援 |
| **Gemini CLI** | `BeforeAgent` | `AfterAgent` | ✅ 完整支援 |
| **Codex CLI** | `SessionStart` | `Stop` | ⏳ **僅支援 Session 層級**（每個會話啟動一次） |

```bash
hushflow install --target gemini   # 安裝特定工具
```

## ✨ 功能特色

- 🧘 **自動正念** — 設定延遲後自動啟動，AI 完成後自動消失。完全自動化。
- 🎯 **專注優先** — 在獨立視窗或 tmux 窗格中運行。你的主終端焦點始終如一。
- 🛠️ **原生整合** — 完美支援 **Claude Code**、**Gemini CLI** 與 **Codex CLI**。
- 💻 **跨平台支援** — macOS、Linux 與 Windows。相容 Ghostty、iTerm2、Windows Terminal 等。
- 🫁 **專業呼吸法** — 內建 4 種模式：*諧振*、*生理性嘆息*、*箱式*、與 *4-7-8*。
- 🎨 **自訂主題** — 8+ 種主題（**3 種內建 + 5 種社群主題**，如 Catppuccin, Dracula）。
- ⚡ **極致效能** — 純 Bash 邏輯。渲染路徑零依賴。

---

## 🔒 透明度說明

### 修改的檔案
HushFlow 僅會修改 AI 工具的鉤子設定，以實現自動啟動/停止：
- **Claude Code**: `~/.claude/settings.json` (新增 `onPromptSubmit` 與 `onStop`)
- **Gemini CLI**: `~/.gemini/settings.json` (新增 `beforeAgent` 與 `afterAgent`)
- **Codex CLI**: `~/.codex/hooks.json`

### 移除安裝 (Uninstall)
想移除 HushFlow？就像安裝一樣簡單：
```bash
# 使用 CLI 指令
hushflow uninstall

# 或是在原始碼目錄執行
./install.sh --uninstall
```

---

## 📺 UI 模式
