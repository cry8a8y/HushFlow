# HushFlow Cross-Platform Install Test Matrix

## Installer Contract Tests

| Platform | Installer | Target | Automated | Manual | Command | Expected Result |
|----------|-----------|--------|:---------:|:------:|---------|-----------------|
| macOS | `install.sh` | Claude | ✅ CI | — | `bash test/install-contract-test.sh` | `UserPromptSubmit`/`Stop` hooks with `async: true` |
| macOS | `install.sh` | Gemini | ✅ CI | — | Same as above | `BeforeAgent`/`AfterAgent` hooks with `timeout: 60000/5000` |
| macOS | `install.sh` | Codex | ✅ CI | — | Same as above | `SessionStart`/`Stop` hooks with `timeout: 60/5` |
| Linux | `install.sh` | Claude | ✅ CI | — | Same as above | Same as macOS |
| Linux | `install.sh` | Gemini | ✅ CI | — | Same as above | Same as macOS |
| Linux | `install.sh` | Codex | ✅ CI | — | Same as above | Same as macOS |
| Windows | `install.ps1` | Claude | ✅ CI | — | `pwsh test/install-ps1-test.ps1` | Hooks written to settings.json |
| Windows | `install.ps1` | Gemini | ✅ CI | — | Same as above | Hooks written with correct timeouts |
| Windows | `install.ps1` | Codex | ✅ CI | — | Same as above | Hooks written to hooks.json |

### Scenarios per Target (7 each)

| Scenario | Verified By |
|----------|-------------|
| Fresh install from `{}` | jq JSON structure validation |
| Install with existing hooks | Verify other hooks preserved |
| Double install (idempotency) | Hook count = 1 after 2 installs |
| Half-broken repair | Missing stop hook auto-repaired |
| Uninstall (selective) | Only HushFlow hooks removed |
| Invalid JSON input | No crash, safe failure |
| Target isolation | Other agents' configs untouched |

## UI Layout Tests

| Platform | UI Mode | Automated | Manual | Command | Expected Result |
|----------|---------|:---------:|:------:|---------|-----------------|
| Linux | tmux-pane | ✅ CI | — | `bash scripts/test-ui-layout.sh --ci` | Title visible, no overflow, content present |
| Linux | Inline | ✅ CI | — | Same as above | No crash |
| macOS | Window | — | ✅ | `bash scripts/test-ui-layout.sh --interactive` | Window opens, positioned correctly, closes on stop |
| Linux | Window | — | ✅ | Same as above | Window opens via xdotool |
| Any | tmux-popup | — | ✅ | Same as above | Popup appears and dismisses |

### Size Matrix (Automated for tmux-pane)

| Size | Test ID | Notes |
|------|---------|-------|
| 40×12 (small) | `tmux-pane 40x12` | Tests minimum size enforcement |
| 80×24 (standard) | `tmux-pane 80x24` | Typical terminal |
| 200×50 (large) | `tmux-pane 200x50` | Wide/tall terminal |

### Theme & Animation Matrix

| Dimension | Variants Tested |
|-----------|----------------|
| Themes | teal, twilight, dracula |
| Animations | constellation, ripple, wave |

## CI Pipeline

| Job | Platform | Tests Run |
|-----|----------|-----------|
| `test-unix` | Ubuntu + macOS | smoke tests, installer contracts, syntax, themes, UI layout (Linux only) |
| `test-windows` | Windows | PowerShell installer tests, PS1 syntax check |

## Running Tests Locally

```bash
# All smoke tests (existing)
bash test/smoke-test.sh

# Installer contract tests (3 targets × 7 scenarios)
bash test/install-contract-test.sh

# UI layout — automated (requires tmux)
bash scripts/test-ui-layout.sh --ci

# UI layout — interactive (with human verification)
bash scripts/test-ui-layout.sh --interactive

# Single mode/size test
bash scripts/test-ui-layout.sh --mode tmux-pane --cols 40 --rows 12 --theme dracula

# PowerShell tests (requires pwsh)
pwsh test/install-ps1-test.ps1
```

## Hook Schema Reference

| Tool | Settings File | Start Event | Stop Event | Start Attrs | Stop Attrs |
|------|---------------|-------------|------------|-------------|------------|
| **Claude** | `~/.claude/settings.json` | `UserPromptSubmit` | `Stop` | `async: true` | `async: true` |
| **Gemini** | `~/.gemini/settings.json` | `BeforeAgent` | `AfterAgent` | `timeout: 60000` | `timeout: 5000` |
| **Codex** | `~/.codex/hooks.json` | `SessionStart` | `Stop` | `timeout: 60` | `timeout: 5` |

## Canonical Behavior

`install.sh` (Bash) is the **canonical implementation**. `install.ps1` (PowerShell) must match its behavior:

- ✅ Config defaults: `enabled=true`, `exercise=0`, `delay=5`, `theme=teal`, `animation=constellation`
- ✅ Idempotency: check before install, skip if hooks already present
- ✅ Selective uninstall: only remove HushFlow hooks, preserve others
- ✅ JSON validation: verify output before writing
- ✅ Backup: create `.backup` file before modifying settings
