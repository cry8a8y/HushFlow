# HushFlow Architecture

HushFlow acts as a silent observer to your AI terminal sessions.

## 🧠 Complete Logic Flow

```text
       ┌──────────────┐
       │  You send a  │
       │    Prompt    │
       └──────┬───────┘
              │
              ▼ (Trigger Hook)
       ┌──────────────┐           ┌──────────────────┐
       │  AI Tool     │──────────▶│  HushFlow Agent  │
       │  starts work │           │  (Background)    │
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
              │                   │  Open Companion  │
              │                   │      Window      │
              │                   └────────┬─────────┘
              │                            │
              │                            ▼
              │                   ┌──────────────────┐
              │                   │    Breathing     │◀──┐
              │                   │    Animation     │───┘
              │                   └────────┬─────────┘
              ▼ (Finish Hook)              │
       ┌──────────────┐                    │ (Signal: Stop)
       │  AI Tool     │────────────────────┘
       │  responds    │
       └──────────────┘           ┌──────────────────┐
              │                   │  HushFlow Agent  │
              ▼                   │  Close & Cleanup │
       (Back to you)              └──────────────────┘
```

## ⚡ Under the Hood

| Metric | Value | Notes |
|--------|-------|-------|
| **Render** | 10 fps | Double-buffered, single `printf` per frame |
| **CPU** | < 2% | Trig lookup tables, no `bc`/`awk` in render loop |
| **Memory** | ~3 MB RSS | Pure Bash, no background daemons |
| **Startup** | < 50 ms | No interpreter boot, just `bash` |
| **Dependencies** | 0 in render path | `jq` only at config load |
