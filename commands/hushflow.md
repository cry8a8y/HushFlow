Configure HushFlow.

Read the config file at `~/.claude/hushflow/config` to check current settings. If it doesn't exist, the defaults are: enabled=true, exercise=0, delay=5, theme=teal, animation=random, sound=false.

Show the user the current status:
- **Enabled**: true/false
- **Exercise**: 0=Coherent Breathing (5.5s in, 5.5s out), 1=Physiological Sigh (double inhale + long exhale), 2=Box Breathing (4-4-4-4), 3=4-7-8 Breathing (4s in, 7s hold, 8s out)
- **Delay**: seconds before the breathing window appears
- **Theme**: teal (ocean), twilight (purple), amber (warm), auto (detect dark/light), or any community theme name (catppuccin-mocha, dracula, nord, solarized-dark, gruvbox)
- **Animation**: random (default — picks a different animation each session), constellation, ripple, wave, orbit, helix, rain
- **Sound**: true/false — optional chime sounds at breath transitions (requires ffplay, mpv, afplay, or paplay)

Then ask what they'd like to change (toggle on/off, switch exercise, change delay, change theme, change animation, toggle sound). Update `~/.claude/hushflow/config` with the new values using sed. Create the file and directory if they don't exist. The config format is simple key=value lines:

```
enabled=true
exercise=0
delay=5
theme=teal
animation=random
sound=false
```

Additional commands the user can run directly:
- `hushflow stats` — View session statistics, streaks, and mindful time
- `hushflow wrap -- <command>` — Run breathing while any command executes
- `hushflow theme list` — List all available themes (built-in + community)
- `hushflow doctor` — Check installation and environment
