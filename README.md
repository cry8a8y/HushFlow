<p align="center">
  <img src="docs/hushflow-banner.svg" alt="HushFlow — Breathe while your AI thinks" width="720" />
</p>

<p align="center">
  <b>English</b> | <a href="docs/README.zh-TW.md">繁體中文</a> | <a href="docs/README.zh-CN.md">简体中文</a> | <a href="docs/README.ja.md">日本語</a>
</p>

<p align="center">
  <a href="https://github.com/cry8a8y/HushFlow/stargazers"><img src="https://img.shields.io/github/stars/cry8a8y/HushFlow?style=social" alt="GitHub Stars" /></a>
  <img src="https://img.shields.io/npm/v/hushflow?color=cb3837&label=npm" alt="npm" />
  <img src="https://github.com/cry8a8y/HushFlow/actions/workflows/ci.yml/badge.svg" alt="CI Status" />
  <img src="https://img.shields.io/github/license/cry8a8y/HushFlow" alt="License" />
  <img src="https://img.shields.io/badge/platform-macOS%20|%20Linux%20|%20Windows-blue" alt="Platform Support" />
</p>

<p align="center">
  <b>Every AI wait is a chance to breathe.</b><br/>
  <i>Turn 50-200 daily idle moments into effortless focus & recovery.</i>
</p>

A breathing layer for AI-powered terminals. Turns every wait into a calm ritual — across tools, across platforms, automatically.

---

## 🚀 Get Started in < 60 Seconds

> [!IMPORTANT]
> **Prerequisites:** `bash` (4.0+), `git`, and `jq` are required.
> **Optional:** `tmux` (for tmux pane/popup mode), audio player (`ffplay`, `mpv`, `afplay`, or `paplay`) for immersive sound.

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
1. Run `hushflow doctor` to verify your setup.
2. **Restart** your AI tool (e.g., Claude Code).
3. Send any **Prompt**.
4. **Wait 5s** — The breathing window will appear naturally.

<p align="center">
  <img src="demo.gif" alt="HushFlow Demo" width="720" />
</p>

---

## 🧘 Why HushFlow?

Typical developers face dozens of "dead moments" every day waiting for AI models to plan, edit, or test. Most fill these gaps with micro-distractions (scrolling, checking Slack) that break the flow state. 

**HushFlow turns them into recovery.** Leveraging the physiological sigh, it naturally lowers heart rate and maintains your focus, all without leaving your terminal.

- ⚡ **Ultra-lightweight**: < 2% CPU during animation.
- 🧠 **Tiny footprint**: ~3MB RAM (Shell-native).
- 🔒 **Zero Telemetry**: All logic stays local. Forever.

---

## ✨ Features

- 🧘 **Auto-Mindfulness** — Appears after a delay, disappears when AI finishes. Zero-click calm.
- 🎯 **Focus-First** — Runs in a separate window or tmux pane. Your terminal stays focused.
- 🛠️ **Universal Integration** — Native for **Claude Code**, **Gemini CLI**, and **Codex CLI**.
- 📊 **Mindful Stats** — Track your breathing sessions and keep your daily streak alive with `hushflow stats`.
- 🔔 **Session Notifications** — macOS notification after each session with exercise name, cycles completed, and duration.
- 💻 **Cross-Platform** — macOS, Linux, and Windows. optimized for **Ghostty 1.3.1**, iTerm2, Windows Terminal.
- 🫁 **Breath Work** — 4 built-in patterns: *Coherent*, *Sigh*, *Box*, and *4-7-8*.
- 🎨 **Custom Themes** — 8+ themes (**3 built-in + 5 community** like Catppuccin, Dracula).
- 🎵 **Immersive Audio** — Zen-crafted soundscape with phase-specific breath cues.
- ⚡ **Engineered for Speed** — Pure Bash logic. Render path has zero external dependencies.

## 🖥️ Supported Terminals

| Platform | Terminals | Notes |
|----------|-----------|-------|
| macOS | **Ghostty** (optimized), iTerm2, Terminal.app | TrueColor recommended |
| Linux | gnome-terminal, Konsole, xfce4-terminal, xterm, Ghostty | `xdotool` for window positioning |
| Windows | Windows Terminal, PowerShell | Via Git Bash |
| Fallback | Any terminal | Inline mode (no separate window) |

## ⚔️ Why HushFlow vs. Others

| Feature | **HushFlow** | Mindful-Claude |
| :--- | :--- | :--- |
| **Integration** | Native (Claude/Gemini/Codex) | Wrapper-only |
| **Experience** | Separate Window / Tmux Pane | Main terminal only |
| **Performance** | Shell Native (~3MB RAM) | Node.js Heavy |
| **Customization** | 8+ Themes / Immersive Sound | Basic |

## 🎵 Immersive Audio

HushFlow features an optional built-in soundscape designed for deep immersion and functional guidance. Enable it with `hushflow sound on`.

> **Supported players:** `ffplay` (FFmpeg), `mpv`, `afplay` (macOS built-in), `paplay` (PulseAudio/PipeWire).

- **Inhale**: **Harmonic Bloom** — A deep 60Hz swell with warming fireplace crackles.
- **Hold**: **Tri-Harmonic Stillness** — Interweaving resonances that eliminate flat tones.
- **Exhale**: **Parabolic Recede** — Silky 65Hz airflow that settles naturally like a tide.
- **Complete**: **The Master Bell** — A heavy 82Hz bronze bell struck by a mellow mallet.

*Let the hum of a Tibetan bell dissolve your coding anxiety as the AI finishes its task.*

## 📊 Usage Statistics

Track your progress and build a habit. Use `hushflow stats` to view your daily cycles, total mindful hours, and current streak.

---

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

HushFlow is designed to be completely non-intrusive:
- **Hook Settings**: Appends execution triggers to `~/.claude/settings.json`, `~/.gemini/settings.json`, and `~/.codex/hooks.json`.
- **Config Path**: Stores preferences, themes, and streak data in `~/.hushflow/`.
- **Session State**: Uses a temporary `.session` file for state sync (auto-cleaned).
- **Uninstall**: Run `hushflow uninstall` to clean up all the above immediately.
- **Privacy**: Zero telemetry. 100% local execution.

## 📚 Advanced Docs

- [Community Themes](themes/) (Catppuccin, Dracula, Nord, Solarized, Gruvbox)
- [Plugin API](docs/PLUGIN-API.md) — Create custom animations
- [Environment Variables](docs/ENVIRONMENT.md) — Advanced configuration
- [Troubleshooting](docs/TROUBLESHOOTING.md) — Common issues & fixes

---

## 🤝 Contributing & Support

HushFlow is derived from [Mindful-Claude](https://github.com/halluton/Mindful-Claude). Contributions are welcome! Whether it's a new theme, plugin, or fix — check out [CONTRIBUTING.md](CONTRIBUTING.md).

If HushFlow helps you stay calm, please give it a ⭐ — it helps others find the project.

MIT. See [LICENSE](LICENSE) for details.

---
<p align="center">
  <i>breathe in. breathe out. ship code.</i>
</p>
