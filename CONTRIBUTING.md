# Contributing to HushFlow

Thank you for your interest in contributing to HushFlow! Whether it's a bug fix, new animation, community theme, or documentation improvement — every contribution is welcome.

## Getting Started

```bash
git clone https://github.com/cry8a8y/HushFlow.git
cd HushFlow
```

No build step required — HushFlow is pure Bash + JSON.

## Running Tests

```bash
bash test/smoke-test.sh
```

All tests must pass before submitting a PR.

## Project Structure

```
HushFlow/
├── breathe-compact.sh    # Core rendering engine
├── cli.sh                # CLI entry point (npx hushflow)
├── install.sh            # Installer (macOS/Linux)
├── install.ps1           # Installer (Windows)
├── set-exercise.sh       # Configuration management
├── doctor.sh             # Diagnostic tool
├── hooks/                # AI tool hook scripts (on-start/on-stop)
├── lib/                  # Helper modules (stats, wrap, sound, detect)
├── themes/               # Community theme JSON files
├── sounds/               # Sound files (user-provided)
├── plugins/              # Example animation plugins
├── commands/             # Slash command definitions
├── test/                 # Smoke tests
└── docs/                 # Documentation and translations
```

## How to Contribute

### Community Themes

Create a JSON file in `themes/`:

```json
{
  "name": "my-theme",
  "author": "your-github-username",
  "colors": {
    "primary": "R;G;B",
    "secondary": "R;G;B",
    "mid": "R;G;B",
    "mid_dim": "R;G;B",
    "dim": "R;G;B"
  }
}
```

Colors use semicolon-separated RGB values (0-255), e.g. `"131;148;150"`.

Test your theme:
```bash
hushflow theme my-theme
```

### Animation Plugins

See [Plugin API documentation](docs/PLUGIN-API.md) for the full guide.

### Bug Fixes & Features

1. Fork the repository
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Make your changes
4. Run `bash test/smoke-test.sh` — all tests must pass
5. Commit with conventional format: `feat(scope): description` or `fix(scope): description`
6. Open a Pull Request

## Commit Convention

```
<type>(<scope>): <description>

Types: feat, fix, docs, test, chore, refactor
Scopes: core, cli, hooks, themes, sound, stats, wrap, ci
```

## Code Style

- **Pure Bash** — no external dependencies in the core rendering path (except `jq` for JSON config)
- **Portable** — must work on macOS, Linux, and Windows (Git Bash / WSL)
- **No flicker** — use the existing double-buffer pattern in `breathe-compact.sh`
- **Performance** — use SIN64/COS32 lookup tables, not `bc` or external math
- Prefer `printf` over `echo` for ANSI escape sequences

## Reporting Issues

Please include:
- OS and terminal emulator
- Output of `hushflow doctor`
- Steps to reproduce

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
