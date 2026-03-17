# HushFlow

Every prompt you send to Claude gives you 10-60+ seconds of dead time. Stop wasting it.

This extension turns Claude's thinking time into guided breathing exercises. It auto-launches when Claude starts working and disappears when it's done. You stay in flow, your nervous system gets a workout, and you never leave your coding session.

## Why

Slow, structured breathing at ~5.5 breaths per minute increases heart rate variability (HRV), a key biomarker of stress resilience and cardiovascular health. Even brief sessions reduce cortisol and sharpen focus. Every prompt becomes a micro-session for your nervous system.

## What You Get

- **4 breathing exercises** (see below)
- **4 animation styles**: Pulse (gradient bars), Ripples (concentric lines), Dots (scattered particles), Wave (bell curve)
- **Auto-launch**: Breathing starts after a configurable delay (default 5s) when Claude is working
- **Auto-dismiss**: Animation closes the moment Claude finishes
- **Non-blocking**: By default opens in a separate Ghostty window; optional tmux pane/popup modes are still available

## Demo

![HushFlow demo](demo.gif)

## Quick Start

Requires **Ghostty** on macOS for the standalone window mode. Optional **tmux** support is available for pane/popup mode.

```bash
git clone https://github.com/halluton/Mindful-Claude.git
cd Mindful-Claude
./install.sh
```

The installer adds hooks to `~/.claude/settings.json`, creates a config at `~/.claude/mindful/config`, and installs the `/mindful` slash command. Requires `jq`.

Start a Claude Code session and the breathing animation will appear automatically in a compact Ghostty window after the configured delay.

> **Tip:** If you prefer the original embedded feel, set `MINDFUL_UI_MODE=tmux-pane` before launching Claude inside tmux.

## `/mindful` Slash Command

Type `/mindful` in any Claude Code session to view status and change settings: toggle on/off, switch exercise, or adjust the delay.

### Exercises

| Exercise | Pattern | Best For |
|---|---|---|
| **Coherent Breathing** | 5.5s in / 5.5s out | Sustained HRV improvement |
| **Physiological Sigh** | Double inhale / long exhale | Quick calm-down |
| **Box Breathing** | 4s in / 4s hold / 4s out / 4s hold | Focus and concentration |
| **4-7-8 Breathing** | 4s in / 7s hold / 8s out | Deep relaxation |

## How It Works

```
You send a prompt to Claude Code
         |
         v
    on-start.sh fires
    |-- Checks ~/.claude/mindful/config, exits if disabled
    |-- Creates marker file /tmp/mindful-claude-working
    '-- Launches a delayed UI helper in background
         |
         v
    helper waits 5 seconds
    |-- If Claude is still working: opens breathe.sh in a Ghostty window
    '-- If Claude already finished: exits silently
         |
         v
    Claude finishes, on-stop.sh fires
    |-- Removes marker file
    '-- Stops the window/pane
```

## Configuration

### Config File

Settings are stored in `~/.claude/mindful/config`:

```
enabled=true
exercise=0
delay=5
```

### Environment Variables

Environment variables override the config file. Set these in `.zshrc` or `.bashrc`:

| Variable | Default | Description |
|---|---|---|
| `MINDFUL_UI_MODE` | `window` | UI mode: `window`, `tmux-pane`, `tmux-popup`, or `off` |
| `MINDFUL_DELAY_SECONDS` | config `delay` | Seconds to wait before showing breathing animation |

## Manual Installation

If you don't want to use the installer, you can set it up manually.

1. Make scripts executable:

```bash
chmod +x breathe.sh set-exercise.sh hooks/*.sh
```

2. Add the hooks to your Claude Code settings. Edit `~/.claude/settings.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "command": "/full/path/to/hooks/on-start.sh"
      }
    ],
    "Stop": [
      {
        "command": "/full/path/to/hooks/on-stop.sh"
      }
    ]
  }
}
```

Use full absolute paths.

3. (Optional) Install the `/mindful` slash command:

```bash
mkdir -p ~/.claude/commands
cp commands/mindful.md ~/.claude/commands/mindful.md
```

4. Change exercise from the terminal:

```bash
./set-exercise.sh hrv    # Coherent Breathing (5.5s in, 5.5s out)
./set-exercise.sh sigh   # Physiological Sigh (double inhale + long exhale)
./set-exercise.sh box    # Box Breathing (4s in, 4s hold, 4s out, 4s hold)
./set-exercise.sh 478    # 4-7-8 Breathing (4s in, 7s hold, 8s out)
```

5. Start a Claude Code session.

### UI Modes

- `window` (default): launches a dedicated Ghostty window on macOS
- `tmux-pane`: opens a non-focused pane below the current tmux client
- `tmux-popup`: opens a centered tmux popup
- `off`: keeps the hooks installed but disables visuals

Example:

```bash
export MINDFUL_UI_MODE=tmux-pane
claude
```

## License

MIT. See [LICENSE](LICENSE) for details.
