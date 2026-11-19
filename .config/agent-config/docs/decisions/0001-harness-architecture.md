# 0001: Layered harness, vendored from one source

Accepted 2026-11-19. Partly superseded by [0002](0002-autonomy-and-committed-skills.md): no guardrails; skills committed in dotfiles and installed into projects with `npx skills` instead of custom `vendor`/`doctor` commands.

**Context.** Five overlapping global design skills compete for the same trigger; klyz, LUPI and reckon carry drifted copies of the same skills; there are no guardrails; decisions live in machine-local auto-memory. Research behind this: `~/reports/Claude Code agentic harness setup.md`.

**Decisions.**

1. **Distribution:** `agent-config` is the single canonical source. Packs are vendored into each project's `.agents/skills` with file hashes, and a drift check compares them. Rejected: a global plugin per project (Claude-only, not pinned per repo) and all-global skills (more overlap and token cost).
2. **UI base:** impeccable upstream, unchanged, plus a thin `ui` router with add-on references taken from ui-taste, ui-ux-pro-max, emil-design-eng, refactoring-ui, design-taste-frontend and web-design-guidelines. Rejected: ui-taste as base (older impeccable 4.6, paid MCP upsell) and forking impeccable (loses upstream updates).
3. **Image generation:** deferred (2026-11-19). Preferred route when revisited: Codex CLI `codex exec` with the stable `image_generation` feature on the existing ChatGPT plan, with an HTML-mockup-plus-screenshot fallback. Rejected: paid image APIs.
4. **Parity:** everything works in both Claude Code and Codex. `.agents/skills` and `AGENTS.md` are canonical; Claude-only mechanisms get Codex equivalents where possible.

**Consequences.** `deploy.py` gains `vendor` and `doctor` commands. Project-specific handoff skills fold into the global `wiki` skill. Design skills in `~/.agents/skills` other than impeccable are uninstalled once their add-ons are extracted.
