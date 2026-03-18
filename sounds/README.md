# HushFlow Sounds

Place sound files here for breath transition audio cues.

## Sound names
- `inhale.ogg` — played at start of inhale (10s base)
- `exhale.ogg` — played at start of exhale (10s base)
- `hold.ogg` — played at start of hold (10s base)
- `complete.ogg` — played when session ends (5s)

## Duration-matched variants
Pre-trimmed files with fade-out, matched to each breathing pattern:
- `inhale-4s.ogg`, `inhale-5.5s.ogg`
- `hold-1s.ogg`, `hold-4s.ogg`, `hold-7s.ogg`
- `exhale-4s.ogg`, `exhale-5.5s.ogg`, `exhale-8s.ogg`

The player auto-selects the best match. Falls back to the base file with player-level truncation if no match exists.

## Supported formats
WAV, MP3, OGG

## Custom sounds
Place your own files in `~/.hushflow/sounds/` to override defaults.

## Requirements
One of: ffplay (FFmpeg), mpv, afplay (macOS), or paplay (PulseAudio)
