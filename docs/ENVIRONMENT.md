# Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HUSHFLOW_UI_MODE` | `window` | `window`, `tmux-pane`, `tmux-popup`, `inline`, or `off` |
| `HUSHFLOW_DELAY_SECONDS` | config `delay` | Override the startup delay |
| `HUSHFLOW_COLS` | auto-detect | Override terminal width (columns) |
| `HUSHFLOW_ROWS` | auto-detect | Override terminal height (rows) |
| `HUSHFLOW_TERMINAL` | auto-detect | Force terminal type (e.g. `ghostty`, `iterm`, `xterm`) |
| `HUSHFLOW_PLUGIN_DIR` | `~/.hushflow/plugins` | Custom plugin directory |
| `HUSHFLOW_DEBUG` | off | Set to `1` to enable debug logging to `/tmp/hushflow-debug.log` |
| `HUSHFLOW_CONFIG_DIR` | `~/.<tool>/hushflow` | Override config directory |
| `HUSHFLOW_COLOR_IN` | theme primary | Override inhale color as `R;G;B` |
| `HUSHFLOW_COLOR_OUT` | theme secondary | Override exhale color as `R;G;B` |
