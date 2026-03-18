# HushFlow Architecture

HushFlow acts as a silent observer to your AI terminal sessions.

## Complete Logic Flow

```text
       ┌──────────────┐
       │  You send a  │
       │    Prompt    │
       └──────┬───────┘
              │
              ▼ (UserPromptSubmit)
       ┌──────────────┐           ┌──────────────────┐
       │  AI Tool     │──────────▶│  on-start.sh     │
       │  starts work │           │  (async hook)    │
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
              │                   │  open-window.sh  │
              │                   │  (detect terminal│
              │                   │   + launch)      │
              │                   └────────┬─────────┘
              │                            │
              │                            ▼
              │                   ┌──────────────────┐
              │                   │  breathe-compact │◀──┐
              │                   │  .sh (animation  │───┘
              │                   │  + sound.sh)     │
              │                   └────────┬─────────┘
              │                            │
              │  PermissionRequest?        │
              │  ┌─────────────────┐       │
              │  │ on-permission.sh│───────▶│ rm working (pause)
              │  └─────────────────┘       │
              │  PostToolUse (approved)?   │
              │  ┌─────────────────┐       │
              │  │ on-resume.sh   │───────▶│ ≤30s: auto-resume
              │  │ (3-tier expiry)│        │ 30-60s: slow resume
              │  └─────────────────┘       │ >60s: notify only
              │                            │
              ▼ (Stop)                     │
       ┌──────────────┐                    │ (Signal: Stop)
       │  AI Tool     │────────────────────┘
       │  responds    │           ┌──────────────────┐
       └──────────────┘           │  on-stop.sh      │
              │                   │  Close & Cleanup  │
              ▼                   └──────────────────┘
       (Back to you)
```

## Hook Lifecycle

| Event | Hook | Trigger | Mode |
|-------|------|---------|------|
| `UserPromptSubmit` | `on-start.sh` | User sends prompt | async |
| `Stop` | `on-stop.sh` | AI finishes response | async |
| `PermissionRequest` | `on-permission.sh` | Tool needs approval | async |
| `PostToolUse` | `on-resume.sh` | After tool executes | async |

All hooks share `lib/hook-common.sh` for bootstrap (logging, config/session loading).

## Sound System

```text
  hf_play_sound("inhale", 5.5)
       │
       ▼
  Find file: inhale-5.5s.ogg > inhale.ogg (duration-matched first)
       │
       ▼
  Start new sound (background)
       │
       ▼
  _HF_SOUND_PID=$!
       │
       ▼
  Delayed kill old (150ms crossfade overlap)
```

Player priority: ffplay > mpv > afplay > paplay

## Under the Hood

| Metric | Value | Notes |
|--------|-------|-------|
| **Render** | 10 fps | Double-buffered, single `printf` per frame |
| **CPU** | < 2% | Trig lookup tables, no `bc`/`awk` in render loop |
| **Memory** | ~3 MB RSS | Pure Bash, no background daemons |
| **Startup** | < 50 ms | No interpreter boot, just `bash` |
| **Dependencies** | 0 in render path | `jq` only at config load |
| **Sound** | async | Never blocks UI thread, crossfade overlap |

## Security

- **Theme JSON**: Output validated with regex before `eval` (only `C_X='R;G;B'` format allowed)
- **Plugins**: Function audit after `source` — warns on non-`render_*` functions
- **Config values**: Theme, animation sanitized with regex before use
- **PostToolUse**: Fast-path exit via `.permission-pending` flag (avoids work on every tool call)
