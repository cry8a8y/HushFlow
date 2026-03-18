<p align="center">
  <img src="docs/hushflow-banner.svg" alt="HushFlow — Breathe while your AI thinks" width="720" />
</p>

<p align="center">
  <b>English</b> | <a href="docs/README.zh-TW.md">繁體中文</a> | <a href="docs/README.zh-CN.md">简体中文</a> | <a href="docs/README.ja.md">日本語</a>
</p>

<p align="center">
  <a href="https://github.com/cry8a8y/HushFlow/stargazers"><img src="https://img.shields.io/github/stars/cry8a8y/HushFlow?style=social" alt="GitHub Stars" /></a>
  <img src="https://img.shields.io/npm/v/hushflow?color=cb3837&label=npm" alt="npm" />
  <img src="https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20Windows-blue" alt="Platform Support" />
</p>

A breathing layer for AI-powered terminals. Turns every wait into a calm ritual — across tools, across platforms, automatically.

---

## 🚀 Get Started in < 60 Seconds

> [!IMPORTANT]
> **Prerequisites:** `bash` (4.0+), `git`, and `jq` are required.

### Method 1: Unix / macOS (Fastest)
```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | bash
```

### Method 2: Windows (PowerShell)
```powershell
git clone https://github.com/cry8a8y/HushFlow.git; cd HushFlow; .\install.ps1
```

### Method 3: npm / npx
```bash
npx hushflow install
```

### ✅ Verify Installation in 5 Seconds
1. **Restart** your AI tool (e.g., Claude Code).
2. Send any **Prompt**.
3. **Wait 5s** — The breathing window will appear naturally.

<p align="center">
  <img src="demo.gif" alt="HushFlow Demo" width="720" />
</p>

---

## ✨ Features

- 🧘 **Auto-Mindfulness** — Appears after a delay, disappears when AI finishes. Zero-click calm.
- 🎯 **Focus-First** — Runs in a separate window or tmux pane. Your terminal stays focused.
- 🛠️ **Universal Integration** — Native for **Claude Code**, **Gemini CLI**, and **Codex CLI**.
- 💻 **Cross-Platform** — macOS, Linux, and Windows. Ghostty, iTerm2, Windows Terminal, etc.
- 🫁 **Breath Work** — 4 built-in patterns: *Coherent*, *Sigh*, *Box*, and *4-7-8*.
- 🎨 **Custom Themes** — 8+ themes (**3 built-in + 5 community** like Catppuccin, Dracula).
- 🎵 **Immersive Audio** — Zen-crafted soundscape: *Harmonic Bloom*, *Tri-Harmonic Stillness*, *Parabolic Recede*, and *The Master Bell*.
- ⚡ **Engineered for Speed** — Pure Bash logic. Render path has zero external dependencies.

## 🎵 Immersive Audio

HushFlow features a built-in soundscape designed for deep immersion and functional guidance. Enable it with `hushflow sound on`.

- **Inhale**: **Harmonic Bloom** — A deep 60Hz swell with warming fireplace crackles.
- **Hold**: **Tri-Harmonic Stillness** — Interweaving resonances that eliminate flat tones.
- **Exhale**: **Parabolic Recede** — Silky 65Hz airflow that settles naturally like a tide.
- **Complete**: **The Master Bell** — A heavy 82Hz bronze bell struck by a mellow mallet.

*Designed with acoustic physics to induce parasympathetic relaxation.*

## 📺 UI Modes

- 🪟 **Window** (Default) — Opens a companion terminal window.
- 📑 **tmux pane** — Splits a pane inside your current session.
- 🫧 **tmux popup** — Floating overlay (requires tmux 3.2+).
- ⌨️ **Inline** — Minimalistic rendering in your current terminal.

## ⌨️ Common Commands

```bash
hushflow config hrv    # Set Coherent Breathing
hushflow theme nord    # Apply Nord theme
hushflow animation     # Set animation style
hushflow sound on      # Enable breath audio
hushflow wrap -- cmd   # Run breathing while a command executes
hushflow stats         # View session statistics
hushflow doctor        # Run health check
```

## 🧠 How It Works

HushFlow monitors your AI terminal hooks in the background:
1. 🔌 **Hook Trigger**: AI tool signals the start of agentic work.
2. ⏳ **Smart Delay**: Waits 5s to ensure you're actually waiting, not reading.
3. 🧘 **Ritual**: Opens a window/pane with smooth Bash animations.
4. 🔴 **Cleanup**: Automatically closes when the AI tool finishes.

> [!TIP]
> View the [Full Architecture & Flowchart](docs/ARCHITECTURE.md) for more technical details.

## 🔒 Transparency & Trust

- **Modified Files**: HushFlow only touches your AI tool's hook settings (e.g., `~/.claude/settings.json`, `~/.gemini/settings.json`, `~/.codex/hooks.json`).
- **Uninstall**: Run `hushflow uninstall` to revert all changes immediately.
- **Privacy**: Zero telemetry. All logic runs locally in your shell.

## 📚 Advanced Docs

- [Community Themes](themes/) (Catppuccin, Dracula, Nord, Solarized, Gruvbox)
- [Plugin API](docs/PLUGIN-API.md) — Create custom animations
- [Environment Variables](docs/ENVIRONMENT.md) — Advanced configuration

---

## 🤝 Contributing & Support

HushFlow is derived from [Mindful-Claude](https://github.com/halluton/Mindful-Claude). Contributions are welcome! Whether it's a new theme, plugin, or fix — check out [CONTRIBUTING.md](CONTRIBUTING.md).

If HushFlow helps you stay calm, please give it a ⭐ — it helps others find the project.

MIT. See [LICENSE](LICENSE) for details.
