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

Mindful breathing during AI wait time. Auto-launches when the AI starts, auto-dismisses when it's done.

Works with **Claude Code** and **Gemini CLI** (full per-prompt hooks). **Codex CLI** is supported at session level.

## 🚀 Install in 60 Seconds

```bash
curl -fsSL https://raw.githubusercontent.com/cry8a8y/HushFlow/main/install-remote.sh | sh
```

<details>
<summary>Other install methods</summary>

**npx:**

```bash
npx hushflow install
```

**Manual:**

```bash
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
./install.sh
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
.\install.ps1
```

</details>

**What the installer does:**
1. Copies HushFlow to `~/.hushflow/`
2. Registers start/stop hooks in your AI tool's config
3. Creates a default config at `~/.<tool>/hushflow/config`

**Verify it works:**

```bash
hushflow doctor        # Check installation & environment
```

Then send any prompt to your AI tool and wait 5 seconds — a breathing window will appear.

### 📋 Dependencies

| Type | Package | Platform | Purpose |
|------|---------|----------|---------|
| **Core** | `bash` 4.0+ | All | Shell runtime |
| **Core** | `jq` | All | Config & theme parsing |
| **macOS** | `osascript` | macOS | Window positioning (built-in) |
| **Linux** | `xdotool` | Linux (X11) | Window focus & geometry |
| **Optional** | `tmux` | Any | tmux-pane / tmux-popup UI mode |
| **Optional** | `ffplay` / `mpv` / `afplay` | Any | Sound playback |

## 📺 What You See

<br/>
<p align="center">
  <img src="demo.gif" alt="HushFlow — constellation animation with coherent breathing" width="720" />
</p>
<br/>

HushFlow adapts to your workflow with 4 UI modes:

| Mode | Best for | How to enable |
|------|----------|---------------|
| **Window** | Default — opens a companion terminal | `HUSHFLOW_UI_MODE=window` |
| **tmux pane** | tmux users — splits a pane | `HUSHFLOW_UI_MODE=tmux-pane` |
| **tmux popup** | tmux 3.2+ — floating overlay | `HUSHFLOW_UI_MODE=tmux-popup` |
| **Inline** | Minimal — renders in current terminal | `HUSHFLOW_UI_MODE=inline` |

## ✨ Features

<table>
<tr>
<td width="50%">

### 🧘 Breathing
- **4 exercises** — Coherent, Physiological Sigh, Box, 4-7-8
- **Auto-launch** — Starts when AI thinks, stops when done
- **Configurable delay** — Set when breathing begins
- **Sound cues** — Optional chimes at breath transitions

</td>
<td width="50%">

### 🎨 Visuals
- **6 animations** — Constellation, Ripple, Wave, Orbit, Helix, Rain
- **8+ themes** — Teal, Twilight, Amber + community themes
- **10fps engine** — SIN64 trig lookups, zero flicker
- **Plugin API** — Custom animations via scripts

</td>
</tr>
<tr>
<td width="50%">

### 🔌 Integration
- **3 AI tools** — Claude Code, Gemini CLI, Codex CLI
- **4 UI modes** — Window, tmux pane, popup, inline
- **Universal wrapper** — `hushflow wrap -- <any-command>`
- **Non-blocking** — Zero impact on AI tool output

</td>
<td width="50%">

### 📊 Tracking & More
- **Session stats** — Cycles, streaks, mindful time
- **Cross-platform** — macOS, Linux, Windows
- **6 terminals** — Ghostty, Terminal.app, iTerm2, GNOME, xterm, Windows Terminal
- **Self-diagnostics** — `hushflow doctor`

</td>
</tr>
</table>

### ⚡ Performance

| Metric | Value | Notes |
|--------|-------|-------|
| **Render** | 10 fps | Double-buffered, single `printf` per frame |
| **CPU** | < 2% | SIN64/COS32 lookup tables, no `bc`/`awk` in loop |
| **Memory** | ~3 MB RSS | Pure Bash, no background daemons |
| **Startup** | < 50 ms | No interpreter boot (Python/Node), just `bash` |
| **Dependencies** | 0 in render path | `jq` only at config load |

## 🛠️ Supported AI Tools

| Tool | 🟢 Start Hook | 🔴 Stop Hook | Status |
|------|-----------|-----------|--------|
| **Claude Code** | `UserPromptSubmit` | `Stop` | ✅ Full support |
| **Gemini CLI** | `BeforeAgent` | `AfterAgent` | ✅ Full support |
| **Codex CLI** | `SessionStart` | `Stop` | ⏳ Session-level |

```bash
hushflow install --target gemini   # Install for a specific tool
```

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

```mermaid
flowchart TD
    subgraph trigger ["🎯 Trigger"]
        A["💬 Send a prompt to your AI tool"]
    end

    subgraph hook ["🔗 Hook Lifecycle"]
        B["⚡ on-start.sh runs"]
        C{"⚙️ enabled?"}
        Z["🚫 Exit"]
        D["📌 Create session marker"]
        E["⏳ Wait for delay"]
    end

    subgraph breathe ["🧘 Breathing Session"]
        F["🖥️ Open companion window"]
        G["🌊 breathe-compact.sh renders animation"]
    end

    subgraph cleanup ["🧹 Cleanup"]
        H["✅ AI finishes"]
        I["🔴 on-stop.sh closes UI"]
        J["🗑️ Session cleaned up"]
    end

    A --> B --> C
    C -- No --> Z
    C -- Yes --> D --> E --> F --> G --> H --> I --> J

    style trigger fill:#1a1a2e,stroke:#0f3460,color:#e0e0e0
    style hook fill:#16213e,stroke:#0f3460,color:#e0e0e0
    style breathe fill:#0f3460,stroke:#533483,color:#e0e0e0
    style cleanup fill:#1a1a2e,stroke:#0f3460,color:#e0e0e0
```

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
