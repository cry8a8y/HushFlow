# HushFlow Plugin API

Create custom breathing animations for HushFlow.

## Quick Start

```bash
# 1. Create the plugins directory
mkdir -p ~/.hushflow/plugins

# 2. Copy the example plugin
cp plugins/example-pulse.sh ~/.hushflow/plugins/pulse.sh

# 3. Activate it
hushflow animation pulse
```

## How It Works

On startup, `breathe-compact.sh` sources every `*.sh` file in the plugins directory:

```
~/.hushflow/plugins/*.sh       # default location
$HUSHFLOW_PLUGIN_DIR/*.sh      # override with env var
```

Each plugin defines a `render_<name>()` function. When `animation=<name>` is set in the config, the engine calls that function once per frame (~10 fps).

```
┌─────────────────────────────────────────────┐
│  breathe-compact.sh (engine)                │
│                                             │
│  1. Source all plugins/*.sh                 │
│  2. Compute tick, progress, phase, color    │
│  3. Clear animation area                    │
│  4. Call render_<animation>()               │
│  5. Draw title + status + info (engine)     │
│  6. Flush frame buffer to terminal          │
└─────────────────────────────────────────────┘
```

Your `render_<name>()` function only draws the animation area (rows 4 to `PANE_H - 2`). The engine handles title, breathing status, info line, fade-in, and frame flushing.

## Available Variables

### Timing

| Variable | Type | Description |
|----------|------|-------------|
| `tick` | int | Frame counter, increments every ~100ms (10 fps) |
| `progress` | int 0–1000 | Breathing progress. 0 = fully exhaled, 1000 = fully inhaled |

### Geometry

| Variable | Type | Description |
|----------|------|-------------|
| `PANE_W` | int | Terminal width in columns |
| `PANE_H` | int | Terminal height in rows |
| `center_row` | int | `PANE_H / 2` |
| `center_col` | int | `PANE_W / 2` |
| `half_w` | int | `PANE_W / 2` |

### Colors (ANSI escape sequences)

| Variable | Usage | Description |
|----------|-------|-------------|
| `color` | Primary | Current phase color — `COLOR_IN` during inhale, `COLOR_OUT` during exhale |
| `COLOR_IN` | Bright | Inhale color (e.g. bright teal) |
| `COLOR_OUT` | Bright | Exhale color (e.g. deep teal) |
| `COLOR_MID` | Medium | Mid-tone for secondary elements |
| `COLOR_MDIM` | Subtle | Muted mid-tone for tertiary elements |
| `DIM` | Faint | Dimmest color for background detail |
| `RESET` | — | Reset all ANSI attributes |

All color variables are complete ANSI escape sequences (e.g. `\033[38;2;128;203;196m`). Use them directly:

```bash
frame+="\033[${row};${col}H${color}●${RESET}"
```

### Trig Lookup Tables

Pre-computed sine/cosine values scaled to ±1000:

| Array | Entries | Resolution | Period |
|-------|---------|------------|--------|
| `SIN32[]` | 32 | 11.25° per entry | Full cycle at index 32 |
| `COS32[]` | 32 | 11.25° per entry | Full cycle at index 32 |
| `SIN64[]` | 64 | 5.625° per entry | Full cycle at index 64 |
| `COS64[]` | 64 | 5.625° per entry | Full cycle at index 64 |

Example — circle of radius `r`:

```bash
for ((i = 0; i < 32; i++)); do
    local row=$(( center_row + r * SIN32[i] / 1000 ))
    local col=$(( center_col + r * COS32[i] * 2 / 1000 ))  # *2 for character aspect ratio
    # ...
done
```

### Utility

| Function | Signature | Description |
|----------|-----------|-------------|
| `ease()` | `ease <0-1000>` → stdout | Sine ease-in-out. Input 0–1000, output 0–1000 |
| `hf_log()` | `hf_log "msg"` | Debug log to `/tmp/hushflow-debug.log` (when `HUSHFLOW_DEBUG=1`) |

## Writing a Plugin

### Minimal Template

```bash
#!/usr/bin/env bash
# HushFlow Plugin: MyAnimation

render_myanimation() {
    # Draw within rows 2 to PANE_H-2, cols 1 to PANE_W
    local row col
    for ((row = 3; row < PANE_H - 1; row++)); do
        for ((col = 1; col <= PANE_W; col += 4)); do
            if [ $(( (col + tick) % 8 )) -lt 2 ]; then
                frame+="\033[${row};${col}H${color}·${RESET}"
            fi
        done
    done
}
```

Activate: `hushflow animation myanimation`

### Rules

1. **Function name must match**: `render_<name>()` where `<name>` matches the animation config value.

2. **Append to `$frame`**: Do NOT `echo` or `printf` directly. The engine flushes `$frame` as a single write to avoid flicker.

3. **Stay in bounds**: Draw only in rows 4 to `PANE_H - 2`. Row 1 is the title, row `PANE_H` is the status line. Columns 1 to `PANE_W`.

4. **Use `progress` for breathing sync**: Scale your animation intensity with `progress` (0 = exhale → 1000 = inhale). This keeps your animation in sync with the breathing guide.

5. **Use theme colors**: Use the provided color variables instead of hardcoding ANSI codes. This ensures your plugin works with all themes (teal, twilight, amber).

6. **Integer math only**: Bash has no floating point. Use the trig lookup tables and scale by 1000 for precision.

7. **Compensate for character aspect ratio**: Terminal characters are ~2x taller than wide. Multiply horizontal offsets by 2 for circular shapes: `col = center_col + r * COS32[i] * 2 / 1000`.

### Performance Tips

- Keep loop iterations under ~200 per frame for smooth 10 fps
- Pre-compute data in the global scope (outside the function) — it runs once at startup
- Avoid subshells (`$(...)`) inside render — use arithmetic `$((...))` instead
- Minimize string operations; direct `frame+=` concatenation is fast

## Recommended Symbols

Use Unicode characters that render well in common terminals:

| Category | Symbols |
|----------|---------|
| Dots | `●` `•` `·` `◦` `∙` |
| Stars | `✦` `✧` `★` `☆` `✶` |
| Lines | `│` `─` `┆` `┊` `╳` |
| Misc | `○` `◇` `◈` `~` `≈` |

## File Structure

```
~/.hushflow/
└── plugins/
    ├── myanimation.sh      # render_myanimation()
    ├── snowfall.sh         # render_snowfall()
    └── ...
```

## Example

See [`plugins/example-pulse.sh`](../plugins/example-pulse.sh) — concentric rings that pulse with breathing rhythm.
