<p align="center">
  <img src="hushflow-banner.svg" alt="HushFlow — 把 AI 思考時間變成正念呼吸" width="720" />
</p>

<p align="center">
  <a href="../README.md">English</a> | <b>繁體中文</b> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <a href="https://github.com/cry8a8y/HushFlow/stargazers"><img src="https://img.shields.io/github/stars/cry8a8y/HushFlow?style=social" alt="GitHub Stars" /></a>
  <img src="https://img.shields.io/npm/v/hushflow?color=cb3837&label=npm" alt="npm" />
  <img src="https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20Windows-blue" alt="Platform Support" />
</p>

為 AI 終端機打造的呼吸層。把每一次等待，變成自動化的平靜片刻 — 跨工具、跨平台。

---

## 🚀 60 秒內極速上手

> [!IMPORTANT]
> **前置需求：** 安裝前請確保系統已安裝 `bash` (4.0+), `git` 以及 `jq`。

### 方法 1：Unix / macOS（最快推薦）
```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | bash
```

### 方法 2：Windows (PowerShell)
```powershell
git clone https://github.com/cry8a8y/HushFlow.git; cd HushFlow; .\install.ps1
```

### 方法 3：npm / npx
```bash
npx hushflow install
```

### ✅ 5 秒驗證
1. **重啟** 你的 AI 終端工具（例如：Claude Code）。
2. 送出任何 **指令/對話**。
3. **等待 5 秒** — 呼吸視窗會自然出現。

<p align="center">
  <img src="../demo.gif" alt="HushFlow Demo" width="720" />
</p>

---

## ✨ 功能特色

- 🧘 **自動正念** — 設定延遲後自動啟動，AI 完成後自動消失。完全自動化。
- 🎯 **專注優先** — 在獨立視窗或 tmux 窗格中運行。主終端焦點不被干擾。
- 🛠️ **原生整合** — 完美支援 **Claude Code**、**Gemini CLI** 與 **Codex CLI**。
- 💻 **跨平台支援** — macOS、Linux 與 Windows。相容 Ghostty、iTerm2、Windows Terminal 等。
- 🫁 **專業呼吸法** — 內建 4 種模式：*諧振*、*生理性嘆息*、*箱式*、與 *4-7-8*。
- 🎨 **自訂主題** — 8+ 種主題（**3 種內建 + 5 種社群主題**，如 Catppuccin, Dracula）。
- 🎵 **沈浸式音效** — 禪意打造的 10 秒深層循環：*火爐*、*深層禪定* 與 *大師古鐘*。
- ⚡ **極致效能** — 純 Bash 邏輯。渲染路徑零依賴。

## 🎵 沈浸式音效

HushFlow 內建一套專為深層沈浸與生理引導設計的聲景。使用 `hushflow sound on` 即可啟用。

- **吸氣 (Inhale)**：**諧波綻放 (Harmonic Bloom)** — 深沈的 60Hz 低音隨吸氣漲落，伴隨溫暖的火爐碎裂聲。
- **憋氣 (Hold)**：**三維干涉律動 (Tri-Harmonic Stillness)** — 交織的物理共鳴，徹底消除死板平音，營造靜謐空間感。
- **吐氣 (Exhale)**：**拋物線沈降 (Parabolic Recede)** — 絲滑的 65Hz 氣流感，像潮汐般自然退去。
- **完成 (Complete)**：**大師古鐘 (The Master Bell)** — 重型 82Hz 青銅古鐘，由溫潤木槌敲擊，餘韻悠長。

*基於聲學物理設計，旨在誘發副交感神經放鬆。*

## 📺 UI 模式

- 🪟 **Window** (預設) — 開啟伴隨終端視窗。
- 📑 **tmux pane** — 在目前的會話中分割窗格。
- 🫧 **tmux popup** — 浮動覆蓋層 (需要 tmux 3.2+)。
- ⌨️ **Inline** — 在當前終端機中極簡渲染。

## ⌨️ 常用指令

```bash
hushflow config hrv    # 設定諧振呼吸
hushflow theme nord    # 套用 Nord 主題
hushflow sound on      # 啟用呼吸提示音
hushflow stats         # 查看使用統計
hushflow doctor        # 執行健康檢查
```

## 🧠 運作原理

HushFlow 在背景監控你的 AI 終端會話：
1. 🔌 **鉤子觸發**：AI 工具發出啟動代理工作的信號。
2. ⏳ **智慧延遲**：等待 5s 確保你真的在等待，而非閱讀。
3. 🧘 **儀式感**：使用雙緩衝 Bash 動畫開啟視窗/窗格。
4. 🔴 **自動清理**：當 AI 工具發出「停止」信號時自動關閉。

> [!TIP]
> 查看 [完整架構與流程圖 (英文)](ARCHITECTURE.md) 以瞭解更多技術細節。

## 🔒 透明度與信任

- **修改檔案**：僅修改 AI 工具的鉤子設定（如 `~/.claude/settings.json`, `~/.gemini/settings.json`）。
- **解除安裝**：執行 `hushflow uninstall` 即可立即還原所有變更。
- **隱私聲明**：零遠端連線。所有邏輯皆在你的本地端執行。

## 📚 進階文件

- [社群主題](README.zh-TW.md) (Catppuccin, Dracula, Nord, Solarized, Gruvbox)
- [Plugin API](PLUGIN-API.md) — 自訂動畫外掛
- [環境變數](ENVIRONMENT.md) — 進階設定選項

---

## 🤝 貢獻與支援

HushFlow 衍生自 [Mindful-Claude](https://github.com/halluton/Mindful-Claude)。歡迎貢獻！無論是新主題、外掛或修正 — 請參閱 [CONTRIBUTING.md](../CONTRIBUTING.md)。

如果 HushFlow 讓你在寫程式時更平靜，歡迎給個 ⭐ — 幫助更多人發現這個專案。

MIT. 詳見 [LICENSE](../LICENSE)。
