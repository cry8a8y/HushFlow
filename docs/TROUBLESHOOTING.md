# Troubleshooting

## Quick Diagnostic

```bash
hushflow doctor
```

This checks your installation, dependencies, config files, and hook registration.

## Common Issues

### Breathing window doesn't appear

1. Check if HushFlow is enabled: `grep enabled ~/.<tool>/hushflow/config`
2. Verify hooks are registered: `hushflow doctor`
3. Check delay setting — default is 5 seconds
4. Force inline fallback: `HUSHFLOW_TERMINAL=inline`
5. Enable debug logging and inspect `/tmp/hushflow-debug.log`

### Animation looks broken or has wrong colors

- **SSH / remote sessions**: HushFlow requires TrueColor (24-bit) support. It auto-degrades to 256-color, but some very old terminals may not render correctly.
- **Check terminal support**: `echo $COLORTERM` should show `truecolor` or `24bit`
- **Force a theme**: `hushflow theme teal`

### Window opens in wrong position (Linux)

- Install `xdotool` for dynamic positioning: `sudo apt install xdotool`
- Without xdotool, windows default to `+100+100`

### Multiple windows open simultaneously

- This can happen if the stop hook doesn't fire. HushFlow auto-cleans stale sessions on next start.
- Manual cleanup: `rm -rf /tmp/hushflow-*`

### Debug logging

```bash
HUSHFLOW_DEBUG=1
# Logs go to /tmp/hushflow-debug.log
```
