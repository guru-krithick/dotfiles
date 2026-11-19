---
name: ui
description: Design, build, redesign, restyle, polish or critique a frontend interface - pages, landing pages, dashboards, components, forms, empty states, onboarding, design systems (PRODUCT.md, DESIGN.md, tokens), colour, typography, layout, motion, UX copy, responsive and accessibility fixes, including native iOS/Android screens. Routes the work to the vendored impeccable playbooks and adds palette/font lookup data, motion details, a quick visual diagnostic and a final web checklist. Use whenever the task changes how an interface looks, reads, moves or is laid out. Not for verifying a running app in the browser after a change (use web-ui-review) or for backend-only work.
---

This skill is the entry point; [impeccable](../impeccable/SKILL.md) does the work. Read the add-ons below only at the step that names them.

## Setup

1. **Find impeccable.** It is the sibling skill folder: `realpath "<ui-dir>/../impeccable"`, where `<ui-dir>` is the directory containing this SKILL.md (`${CLAUDE_SKILL_DIR}` in Claude Code). Fall back to `.agents/skills/impeccable` in the project, then `~/.agents/skills/impeccable`. If none exists, say so and stop; a project that copies `ui` must also copy `impeccable`.
2. **Read impeccable's SKILL.md and follow it**, using that folder as its `<skill-base-dir>`: run its `scripts/impeccable context` once, load the playbook for the request, and read `reference/craft-floor.md` before any UI edit. Impeccable's Setup, Modes, Commands and routing rules apply as written.
3. Precedence: the user's brief and the project's PRODUCT.md / DESIGN.md, then impeccable, then the add-ons here. Add-ons supply candidates and checks; they never override a committed design world.

## Intent → impeccable command

| Request | Command (impeccable `reference/…`) | Add-on |
|---|---|---|
| New page, screen or feature; redesign; new look | general design work → `new-work.md` (+ `new-work-world.md` / `new-work-comp.md`); `shape` first when the task itself is unclear | design-data for palette/type candidates |
| No PRODUCT.md, or capture product context | `init` | design-data |
| Write DESIGN.md from code / pull out tokens | `document` / `extract` | |
| Review or critique a design | `critique` | quick-diagnostic |
| Accessibility, performance, responsive audit | `audit` (native: `audit.native.md`) | web-checklist |
| Final pass before shipping | `polish` | web-checklist, then quick-diagnostic |
| Too bland / too loud / too busy | `bolder` / `quieter` / `distill` | |
| Errors, i18n, edge cases; empty states, first run | `harden`; `onboard` | |
| Animation, transitions, press/hover states | `animate` | motion-details |
| Colour | `colorize` | design-data |
| Typography, fonts | `typeset` | design-data |
| Spacing, rhythm, hierarchy | `layout` | quick-diagnostic |
| Copy, labels, error messages | `clarify` | |
| Other screen sizes or devices | `adapt` (native: `adapt.native.md`) | |
| UI feels slow or janky | `optimize` | motion-details (performance) |
| Personality, ambitious effects | `delight` / `overdrive` | motion-details |
| Variants to pick from in the browser | `live` / `generate` | |

No clear intent: use impeccable's `reference/routing.md` menu. Two commands fit: ask once.

## Add-ons (`<ui-dir>/references/`)

- [design-data.md](references/design-data.md): offline search over palettes, font pairings, Google Fonts, styles, UX rules and per-stack guidance. Use while choosing colour or type in `init`, `colorize`, `typeset` or a new visual world.
- [motion-details.md](references/motion-details.md): easing curves, durations by element, origin, interruptibility, gestures, CSS-vs-Motion choice. Read with `animate` or any press/hover/popover work.
- [quick-diagnostic.md](references/quick-diagnostic.md): 8-row hierarchy/spacing/contrast check with a 0-10 score. Add its score to a `critique` or `polish` report.
- [web-checklist.md](references/web-checklist.md): last pass over changed web code (a11y, focus, forms, motion, content, performance, theming, i18n) before calling UI work done.

## Verification

Impeccable's playbooks capture and inspect their own evidence where they say so. Verifying the finished change in the running app (viewports, states, console errors, interaction) belongs to the `web-ui-review` skill, the `ui-checker` subagent, or the repository's own browser skill (e.g. agent-browser). Without that runtime check, report typecheck/code review only; do not claim a visual pass.
