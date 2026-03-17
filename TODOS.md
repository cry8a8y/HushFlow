# HushFlow — Deferred Items

## Auto-Theme (Dark/Light detection)

**What:** Automatically select theme (teal/twilight/amber) based on terminal background color.

**Why:** Users with dark terminals get teal/twilight by default; light terminal users might prefer amber. Removes a manual config step.

**How:** Use `\033]11;?\033\\` OSC query to detect terminal background luminance. Map to theme.

**Complexity:** Medium — OSC 11 support varies across terminals. Need fallback behavior.

**Priority:** P3 — Nice to have, not blocking any user.

---

## Animation Enhancement Pass

**What:** Further polish the 6 built-in animations with richer visual effects as described in the plan file (async-wobbling-rabbit.md).

**Details:**
- Constellation: twinkle effect (20% of stars flash per frame), 5-level depth gradient
- Ripple: 6 rings (up from 4), wavefront glow, micro-pulsation on old rings
- Wave: fill body below wave peak (3 rows: dense/medium/sparse), spray particles at crests
- Orbit: 64-point paths via SIN64, 6-segment comet tails with 4-color gradient, inner counter-orbit
- Helix: dual-color strands, crossover markers, DNA ladder rungs every 6 cols
- Rain: speed-based trail lengths, splash particles on impact, bottom puddle shimmer

**Priority:** P2 — Visual quality improvement for existing users.

---

## Sound Integration

**What:** Optional ambient sound or chime at breath transitions.

**Why:** Multi-sensory feedback improves breathing exercise effectiveness.

**Complexity:** High — cross-platform audio is hard. Would need `afplay` (macOS), `paplay` (Linux), etc.

**Priority:** P3 — Exploratory.

---

## Multiple Breathing Patterns (體驗層面)

**What:** Support multiple breathing rhythms beyond the current single pattern: 4-7-8 Relaxation, Box Breathing (4-4-4-4), Coherent Breathing (5.5-5.5), Physiological Sigh, etc.

**Why:** Different stress levels call for different techniques. 4-7-8 is best for high anxiety; Box Breathing for focus; Coherent for general calm. Letting users choose makes the tool genuinely useful as a wellness tool, not just eye candy.

**How:**
- Define patterns as arrays: `PATTERN_478=(4 7 8)`, `PATTERN_BOX=(4 4 4 4)`, etc.
- `config` file gets `pattern=478` or `pattern=box`
- CLI: `hushflow set-pattern box`
- Animation scaling: particle size / speed / opacity syncs to inhale/hold/exhale phase

**Complexity:** Medium — pattern engine is straightforward; syncing animations to phase timing is the real work.

**Priority:** P3 — Current single rhythm works well for short AI wait times (10-60s). Revisit when users request it.

---

## Session Statistics & Tracking (數據層面)

**What:** Record breathing session data — cycles completed, total mindful time, per-day summaries.

**Why:** Quantified feedback ("Today you completed 12 breathing cycles while waiting for AI") motivates users to keep the tool installed. Gamification without being annoying.

**How:**
- Append to `~/.hushflow/stats.log`: timestamp, duration, cycles, exercise type
- CLI: `hushflow stats` — today / this week / all time summary
- Optional: show stats in graceful exit screen ("3 cycles · 2m 15s")

**Complexity:** Low-Medium — logging is trivial; summary formatting and stat aggregation need some work.

**Priority:** P2 — Strong retention mechanism.

---

## Universal CLI Wait Layer (整合層面)

**What:** Extend HushFlow beyond AI coding tools to any long-running CLI command — `npm install`, `docker build`, `cargo build`, `terraform apply`, etc.

**Why:** Transforms HushFlow from "AI coding assistant companion" to "CLI mindfulness layer." Much larger addressable audience.

**How:**
- Wrapper command: `hushflow wrap -- npm install` (starts breathing on launch, stops on exit)
- Shell integration: `hushflow shell-hook` adds a `preexec`/`precmd` hook that auto-triggers for commands exceeding N seconds
- Keep existing Claude Code / Gemini CLI / Codex CLI hooks as first-class integrations

**Complexity:** Medium-High — shell hook integration varies across bash/zsh/fish. Wrapper mode is simpler.

**Priority:** P3 — Changes product scope significantly. Shell hooks are fragile across shells. Other CLI waits (npm, docker) have their own output — AI wait is the true blank time. Revisit if there's demand.

---

## Community Themes (社群層面)

**What:** Support popular terminal color schemes as built-in themes (Dracula, Catppuccin, Nord, Solarized, Gruvbox, Tokyo Night) and allow user-defined custom themes.

**Why:** CLI tool communities love theming. This drives adoption and sharing (screenshots on Twitter/Reddit).

**How:**
- Theme file format: `~/.hushflow/themes/<name>.theme` with `COLOR=r;g;b` lines
- Built-in themes embedded in breathe-compact.sh (like current teal/twilight/amber)
- CLI: `hushflow set-theme dracula` or `hushflow set-theme ~/my-theme.theme`
- Community gallery: GitHub wiki or `themes/` directory in repo for PRs

**Complexity:** Low — theme loading is simple; curating good color palettes takes taste.

**Priority:** P2 — High community engagement, low effort.

---

## Shareable Animation Presets (社群層面)

**What:** Let users create and share custom animation presets combining animation type + theme + breathing pattern + timing.

**Why:** Community sharing drives organic growth. "Check out my HushFlow setup" posts.

**How:**
- Preset file: `~/.hushflow/presets/<name>.preset` with animation, theme, pattern, timing
- CLI: `hushflow use-preset zen-garden` or `hushflow share-preset my-setup`
- Plugin API already supports custom `render_<name>()` — presets are the config layer on top

**Complexity:** Low — mostly config file parsing + CLI commands.

**Priority:** P3 — Depends on plugin API maturity and community traction.
