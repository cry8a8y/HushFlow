<p align="center">
  <img src="docs/hushflow-banner.svg" alt="HushFlow — Breathe while your AI thinks" width="720" />
</p>

<p align="center">
  <b>English</b> | <a href="docs/README.zh-TW.md">繁體中文</a> | <a href="docs/README.zh-CN.md">简体中文</a> | <a href="docs/README.ja.md">日本語</a>
</p>

<p align="center">
  <a href="https://github.com/cry8a8y/HushFlow/stargazers"><img src="https://img.shields.io/github/stars/cry8a8y/HushFlow?style=social" alt="GitHub Stars" /></a>
  &nbsp;
  <img src="https://img.shields.io/npm/v/hushflow?color=cb3837&label=npm" alt="npm" />
  <img src="https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20Windows-blue" alt="Platform Support" />
</p>

---

A breathing layer for AI-powered terminals. Turns every wait into a calm ritual — across tools, across platforms, automatically.

<br/>
<p align="center">
  <img src="demo.gif" alt="HushFlow — breathing animation appears beside your terminal while AI works" width="720" />
</p>
<br/>

## 🚀 Quick Start

Get up and running in 30 seconds. Choose your preferred method:

### Method 1: One-Line (Recommended)
The cleanest way to install. No Node.js required.
```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | sh
```

### Method 2: Node.js / npm
If you prefer managing CLI tools via npm:
```bash
npm install -g hushflow
hushflow install
```

<details>
<summary><b>Other Installation Methods (Manual / Windows)</b></summary>

**Manual (Git):**
```bash
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
chmod +x install.sh
./install.sh
```

**Windows (PowerShell):**
```powershell
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
.\install.ps1
```
</details>

**What happens during installation?**
1. 🔌 **Hooks**: Automatically registers with your AI tools (Claude, Gemini, etc.).
2. ⚙️ **Config**: Creates a default profile at `~/.<tool>/hushflow/config`.
3. ✅ **Verify**: Run `hushflow doctor` to ensure everything is set up correctly.

### 📋 Dependencies

| Type | Package | Platform | Purpose |
|------|---------|----------|---------|
| **Core** | `bash` 4.0+ | All | Shell runtime |
| **Core** | `jq` | All | Config & theme parsing |
| **macOS** | `osascript` | macOS | Window positioning (built-in) |
| **Linux** | `xdotool` | Linux (X11) | Window focus & geometry |
| **Optional** | `tmux` | Any | tmux-pane / tmux-popup UI mode |
| **Optional** | `ffplay` / `mpv` / `afplay` | Any | Sound playback |

## 🛠️ Supported AI Tools

| Tool | 🟢 Start Hook | 🔴 Stop Hook | Status |
|------|-----------|-----------|--------|
| **Claude Code** | `UserPromptSubmit` | `Stop` | ✅ Full support |
| **Gemini CLI** | `BeforeAgent` | `AfterAgent` | ✅ Full support |
| **Codex CLI** | `SessionStart` | `Stop` | ⏳ Session-level |

```bash
hushflow install --target gemini   # Install for a specific tool
```

## ✨ Features

- 🧘 **Auto-Mindfulness** — Appears after a delay, disappears when AI finishes. Zero-click calm.
- 🎯 **Focus-First** — Runs in a separate window or tmux pane. Your terminal focus stays exactly where it belongs.
- 🛠️ **Universal Compatibility** — Native integration for **Claude Code**, **Gemini CLI**, and **Codex CLI**.
- 💻 **Cross-Platform** — macOS, Linux, and Windows. Support for Ghostty, iTerm2, Windows Terminal, and more.
- 🫁 **Breath Work** — 4 built-in patterns: *Coherent*, *Physiological Sigh*, *Box*, and *4-7-8*.
- 🎨 **Deep Customization** — 6+ animations and 8+ themes (Catppuccin, Dracula, Nord, etc.).
- ⚡ **Engineered for Speed** — Pure Bash logic. < 2% CPU, ~3MB RAM. Render path has zero external dependencies.

## 📺 UI Modes

HushFlow adapts to your workflow with 4 UI modes:

| Mode | Best for | How to enable |
|------|----------|---------------|
| **Window** | Default — opens a companion terminal | `HUSHFLOW_UI_MODE=window` |
| **tmux pane** | tmux users — splits a pane | `HUSHFLOW_UI_MODE=tmux-pane` |
| **tmux popup** | tmux 3.2+ — floating overlay | `HUSHFLOW_UI_MODE=tmux-popup` |
| **Inline** | Minimal — renders in current terminal | `HUSHFLOW_UI_MODE=inline` |

## ⌨️ Commands

```bash
# Breathing exercise
hushflow config hrv            # Coherent Breathing
hushflow config sigh           # Physiological Sigh
hushflow config box            # Box Breathing
hushflow config 478            # 4-7-8 Breathing

# Theme & animation
hushflow theme twilight        # Soft purple
hushflow theme list            # List all available themes
hushflow animation orbit       # Orbiting comets

# Sound, stats & wrapper
hushflow sound on              # Enable breath transition chimes
hushflow stats                 # View sessions, streaks, mindful time
hushflow wrap -- npm install   # Breathe while any command runs

# Diagnostics
hushflow doctor                # Check installation & environment
```

> [!TIP]
> In Claude Code, you can also use the `/hushflow` slash command for interactive settings.

## 🧠 How It Works

HushFlow acts as a silent observer to your AI terminal sessions.

```text
       ┌──────────────┐
       │  You send a  │
       │    Prompt    │
       └──────┬───────┘
              │
              ▼ (Trigger Hook)
       ┌──────────────┐           ┌──────────────────┐
       │  AI Tool     │──────────▶│  HushFlow Agent  │
       │  starts work │           │  (Background)    │
       └──────────────┘           └────────┬─────────┘
              │                            │
              │ Waiting...                 ▼
              │                     [ Enabled? ] ───▶ [No: Exit]
              │                            │
              │                            ▼ [Yes]
              │                     Wait Delay (5s)
              │                            │
              │                            ▼
              │                   ┌──────────────────┐
              │                   │  Open Companion  │
              │                   │      Window      │
              │                   └────────┬─────────┘
              │                            │
              │                            ▼
              │                   ┌──────────────────┐
              │                   │    Breathing     │◀──┐
              │                   │    Animation     │───┘
              │                   └────────┬─────────┘
              ▼ (Finish Hook)              │
       ┌──────────────┐                    │ (Signal: Stop)
       │  AI Tool     │────────────────────┘
       │  responds    │
       └──────────────┘           ┌──────────────────┐
              │                   │  HushFlow Agent  │
              ▼                   │  Close & Cleanup │
       (Back to you)              └──────────────────┘
```

### ⚡ Under the Hood

| Metric | Value | Notes |
|--------|-------|-------|
| **Render** | 10 fps | Double-buffered, single `printf` per frame |
| **CPU** | < 2% | Trig lookup tables, no `bc`/`awk` in render loop |
| **Memory** | ~3 MB RSS | Pure Bash, no background daemons |
| **Startup** | < 50 ms | No interpreter boot, just `bash` |
| **Dependencies** | 0 in render path | `jq` only at config load |

## 📚 Advanced Docs

| Topic | Link |
|-------|------|
| **Community Themes** | 5 themes (Catppuccin, Dracula, Nord, Solarized, Gruvbox) + [create your own](CONTRIBUTING.md) |
| **Plugin API** | Custom animations — [docs/PLUGIN-API.md](docs/PLUGIN-API.md) |
| **Environment Variables** | `HUSHFLOW_UI_MODE`, `HUSHFLOW_DEBUG`, etc. — [full list](docs/ENVIRONMENT.md) |
| **Troubleshooting** | `hushflow doctor` or [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |

## 🤝 Contributing

Contributions welcome! Whether it's a new theme, animation plugin, bug fix, or translation — check out [CONTRIBUTING.md](CONTRIBUTING.md) to get started.

If HushFlow helps you stay calm while coding, consider giving it a ⭐ — it helps others find the project.

## 💖 Acknowledgments

HushFlow is derived from [Mindful-Claude](https://github.com/halluton/Mindful-Claude) by Halluton, licensed under the MIT License. See [THIRD-PARTY-NOTICES](THIRD-PARTY-NOTICES) for the original license.

## 📄 License

MIT. See [LICENSE](LICENSE) for details.
