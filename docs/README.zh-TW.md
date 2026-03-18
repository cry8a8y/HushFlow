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

### 方法 1：一行指令安裝（最快推薦）
最乾淨的方式。不需要 Node.js 或任何額外依賴。
```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | sh
```

### 方法 2：Node.js / npm
如果你習慣用 npm 管理工具：
```bash
npm install -g hushflow
hushflow install
```

<details>
<summary><b>其他安裝方式（手動 / Windows）</b></summary>

**手動安裝 (Git)：**
```bash
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
chmod +x install.sh
./install.sh
```

**Windows (PowerShell)：**
```powershell
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
.\install.ps1
```
</details>

**這 60 秒內發生了什麼？**
1. 🔌 **即時鉤子**：自動與你的 AI 工具（Claude, Gemini 等）連動。
2. ⚙️ **自動配置**：在 `~/.<tool>/hushflow/config` 建立你的專屬設定。
3. ✅ **準備呼吸**：執行 `hushflow doctor` 確認一切就緒。

### 📋 依賴套件

| 類型 | 套件 | 平台 | 用途 |
|------|------|------|------|
| **核心** | `bash` 4.0+ | 全部 | Shell 執行環境 |
| **核心** | `jq` | 全部 | 設定檔與主題解析 |
| **macOS** | `osascript` | macOS | 視窗定位（內建） |
| **Linux** | `xdotool` | Linux (X11) | 視窗焦點與座標 |
| **可選** | `tmux` | 任意 | tmux-pane / tmux-popup 模式 |
| **可選** | `ffplay` / `mpv` / `afplay` | 任意 | 音效播放 |

## 🛠️ 支援的 AI 工具

| 工具 | 🟢 啟動 Hook | 🔴 停止 Hook | 狀態 |
|------|----------|----------|------|
| **Claude Code** | `UserPromptSubmit` | `Stop` | ✅ 完整支援 |
| **Gemini CLI** | `BeforeAgent` | `AfterAgent` | ✅ 完整支援 |
| **Codex CLI** | `SessionStart` | `Stop` | ⏳ Session 層級 |

```bash
hushflow install --target gemini   # 安裝特定工具
```

## ✨ 功能特色

- 🧘 **自動正念** — 設定延遲後自動啟動，AI 完成後自動消失。完全自動化。
- 🎯 **專注優先** — 在獨立視窗或 tmux 窗格中運行。你的主終端焦點始終如一。
- 🛠️ **原生整合** — 完美支援 **Claude Code**、**Gemini CLI** 與 **Codex CLI**。
- 💻 **跨平台支援** — macOS、Linux 與 Windows。相容 Ghostty、iTerm2、Windows Terminal 等。
- 🫁 **專業呼吸法** — 內建 4 種模式：*諧振*、*生理性嘆息*、*箱式*、與 *4-7-8*。
- 🎨 **深度自定義** — 6+ 種動畫與 8+ 種主題（Catppuccin, Dracula, Nord 等）。
- ⚡ **極致效能** — 純 Bash 邏輯。 < 2% CPU, ~3MB RAM。渲染路徑零依賴。

## 📺 UI 模式

HushFlow 提供 4 種 UI 模式，適應不同工作流程：

| 模式 | 適合場景 | 啟用方式 |
|------|---------|---------|
| **Window** | 預設 — 開啟伴隨終端視窗 | `HUSHFLOW_UI_MODE=window` |
| **tmux pane** | tmux 使用者 — 分割窗格 | `HUSHFLOW_UI_MODE=tmux-pane` |
| **tmux popup** | tmux 3.2+ — 浮動覆蓋層 | `HUSHFLOW_UI_MODE=tmux-popup` |
| **Inline** | 極簡 — 在當前終端渲染 | `HUSHFLOW_UI_MODE=inline` |

## ⌨️ 指令

```bash
# 呼吸練習
hushflow config hrv            # 諧振呼吸
hushflow config sigh           # 生理性嘆息
hushflow config box            # 箱式呼吸
hushflow config 478            # 4-7-8 呼吸

# 主題與動畫
hushflow theme twilight        # 暮光紫
hushflow theme list            # 列出所有可用主題
hushflow animation orbit       # 雙彗星軌道

# 音效、統計與包裝
hushflow sound on              # 啟用呼吸轉換提示音
hushflow stats                 # 查看使用統計與連續天數
hushflow wrap -- npm install   # 任何指令執行時都能呼吸

# 診斷工具
hushflow doctor                # 檢查安裝狀態與環境
```

> [!TIP]
> 在 Claude Code 中，也可以使用 `/hushflow` 指令進行互動式設定。

## 🧠 運作原理

HushFlow 就像是你 AI 終端會話中的沈默觀察者。

```text
       ┌──────────────┐
       │  你發送一個  │
       │   Prompt     │
       └──────┬───────┘
              │
              ▼ (觸發 Hook)
       ┌──────────────┐           ┌──────────────────┐
       │  AI 工具     │──────────▶│  HushFlow Agent  │
       │  開始工作    │           │     (背景運行)    │
       └──────────────┘           └────────┬─────────┘
              │                            │
              │ 等待中...                   ▼
              │                     [ 是否啟用？ ] ──▶ [否: 退出]
              │                            │
              │                            ▼ [是]
              │                       等待延遲 (5s)
              │                            │
              │                            ▼
              │                   ┌──────────────────┐
              │                   │    開啟伴隨      │
              │                   │      視窗        │
              │                   └────────┬─────────┘
              │                            │
              │                            ▼
              │                   ┌──────────────────┐
              │                   │    呼吸動畫      │◀──┐
              │                   │    循環播放      │───┘
              │                   └────────┬─────────┘
              ▼ (完成 Hook)                │
       ┌──────────────┐                    │ (停止信號)
       │  AI 工具     │────────────────────┘
       │  完成回應    │
       └──────────────┘           ┌──────────────────┐
              │                   │  HushFlow Agent  │
              ▼                   │   關閉與清理     │
       (交還給使用者)              └──────────────────┘
```

### ⚡ 技術底層

| 指標 | 數值 | 說明 |
|------|------|------|
| **渲染** | 10 fps | 雙緩衝，每幀單次 `printf` |
| **CPU** | < 2% | 三角函數查找表，迴圈內無 `bc`/`awk` |
| **記憶體** | ~3 MB RSS | 純 Bash，無背景服務 |
| **啟動** | < 50 ms | 無直譯器啟動，僅 `bash` |
| **依賴** | 渲染路徑 0 個 | `jq` 僅在載入設定時使用 |

## 📚 進階文件

| 主題 | 連結 |
|------|------|
| **社群主題** | 5 個主題（Catppuccin、Dracula、Nord、Solarized、Gruvbox）+ [自製主題](../CONTRIBUTING.md) |
| **外掛 API** | 自訂動畫 — [docs/PLUGIN-API.md](PLUGIN-API.md) |
| **環境變數** | `HUSHFLOW_UI_MODE`、`HUSHFLOW_DEBUG` 等 — [完整清單](ENVIRONMENT.md) |
| **疑難排解** | `hushflow doctor` 或 [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) |

## 🤝 貢獻

歡迎貢獻！無論是新主題、動畫外掛、Bug 修復或翻譯 — 請參閱 [CONTRIBUTING.md](../CONTRIBUTING.md) 開始。

如果 HushFlow 讓你在寫程式時更平靜，歡迎給個 ⭐ — 幫助更多人發現這個專案。

## 💖 致謝

HushFlow 衍生自 [Mindful-Claude](https://github.com/halluton/Mindful-Claude)（作者：Halluton），基於 MIT 授權。詳見 [THIRD-PARTY-NOTICES](../THIRD-PARTY-NOTICES)。

## 📄 授權

MIT。詳見 [LICENSE](../LICENSE)。
