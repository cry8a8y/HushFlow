# UI Visual Verification Checklist

This checklist covers visual verification steps that cannot be fully automated. Use `scripts/test-ui-layout.sh --interactive` to launch each test scenario with guided prompts.

## Automated vs Manual Boundary

| Check | Automated | Manual |
|-------|:---------:|:------:|
| Title text visible | ✅ tmux capture-pane | — |
| No vertical overflow | ✅ line count check | — |
| No horizontal overflow | ✅ column width check | — |
| Animation has content | ✅ non-blank line count | — |
| Window opens correctly | — | ✅ Visual inspection |
| Window position (centered) | — | ✅ Visual inspection |
| No focus stealing | — | ✅ Check active window |
| Animation smooth (no flicker) | — | ✅ Visual inspection |
| Colors correct for theme | — | ✅ Visual inspection |
| Graceful close on stop | ✅ PID check | ✅ Confirm no orphan window |

## Manual Verification Steps

### Window Mode (macOS)

```bash
bash scripts/test-ui-layout.sh --mode window --cols 80 --rows 24
```

**Check:**
1. [ ] HushFlow window appeared near the main terminal
2. [ ] Window title contains "HushFlow" or "Breathe"
3. [ ] Animation is rendering smoothly (no visible flicker)
4. [ ] Title row (row 2) shows exercise name
5. [ ] Status bar (bottom row) shows breath phase
6. [ ] No text is cut off at edges
7. [ ] After confirmation, window closes cleanly
8. [ ] Main terminal regains focus automatically

### Window Mode (Linux)

```bash
bash scripts/test-ui-layout.sh --mode window --cols 80 --rows 24
```

**Check:**
1. [ ] Terminal window opened (gnome-terminal / xterm / etc.)
2. [ ] Window positioned reasonably on screen
3. [ ] Same visual checks as macOS (items 3-8 above)

### tmux-popup Mode

```bash
# Requires tmux 3.2+
tmux new-session -d -s hf-popup-test
tmux send-keys -t hf-popup-test "HUSHFLOW_UI_MODE=tmux-popup bash ~/HushFlow/hooks/on-start.sh" Enter
# Attach to see popup
tmux attach -t hf-popup-test
```

**Check:**
1. [ ] Popup appeared as floating overlay
2. [ ] Popup is centered within the terminal
3. [ ] Title "🧘 Breathe" is visible
4. [ ] Animation renders within popup bounds
5. [ ] Popup dismisses when marker file removed
6. [ ] No visual artifacts left after popup closes

### Small Terminal (40×12)

```bash
bash scripts/test-ui-layout.sh --mode tmux-pane --cols 40 --rows 12
```

**Check:**
1. [ ] Minimum size enforcement works (no crash)
2. [ ] Title is still readable (may be truncated)
3. [ ] Animation area uses available space efficiently
4. [ ] No overlapping text between title and animation

### Large Terminal (200×50)

```bash
bash scripts/test-ui-layout.sh --mode tmux-pane --cols 200 --rows 50
```

**Check:**
1. [ ] Animation doesn't stretch unnaturally
2. [ ] Content is centered, not stuck in top-left
3. [ ] Extra space is used gracefully

## Theme Visual Verification

Run each theme and verify colors are distinct and readable:

```bash
for theme in teal twilight amber dracula nord catppuccin-mocha solarized-dark gruvbox; do
    echo "--- Testing theme: $theme ---"
    bash scripts/test-ui-layout.sh --mode tmux-pane --theme "$theme" --duration 3
    echo "Press Enter to continue..."
    read
done
```

**Check per theme:**
1. [ ] Inhale color is visually distinct from exhale color
2. [ ] Text is readable against the background
3. [ ] Animation dots/particles are visible
4. [ ] No color banding or artifacts

## Animation Visual Verification

```bash
for anim in constellation ripple wave orbit helix rain; do
    echo "--- Testing animation: $anim ---"
    bash scripts/test-ui-layout.sh --mode tmux-pane --animation "$anim" --duration 5
    echo "Press Enter to continue..."
    read
done
```

**Check per animation:**
1. [ ] Animation moves smoothly
2. [ ] No dots/particles escape the animation area
3. [ ] Pattern is recognizable (stars, ripples, waves, etc.)
4. [ ] Phase transitions (inhale → exhale) are smooth

## Collecting Evidence

### tmux capture-pane artifacts

```bash
# Capture current pane to file
tmux capture-pane -p > /tmp/hf-capture-$(date +%s).txt

# Capture with ANSI colors preserved
tmux capture-pane -p -e > /tmp/hf-capture-color-$(date +%s).txt
```

### macOS screenshots

```bash
# Screenshot specific window
screencapture -w /tmp/hf-window-$(date +%s).png

# Screenshot entire screen
screencapture /tmp/hf-screen-$(date +%s).png
```

### Linux screenshots

```bash
# Using import (ImageMagick)
import /tmp/hf-window-$(date +%s).png

# Using scrot
scrot -u /tmp/hf-window-$(date +%s).png
```
