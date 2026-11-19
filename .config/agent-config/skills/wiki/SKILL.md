---
name: wiki
description: Create and maintain a repository's docs wiki, the memory shared by every session and agent (docs/README.md map, decisions, handoff, TODO, learned rules). Actions - init missing docs, decide (record a numbered decision), handoff (refresh docs/handoff/current.md with state and evidence), learn (turn a mistake or correction into a one-line rule in AGENTS.md), lint (stale decisions, broken links, duplicated TODO items, missing index lines). Use when asked to write a decision, hand off or summarize a session for the next one, remember a lesson, set up project docs, or check the docs for drift.
---

Pick the action from the request. Read `docs/README.md` first when it exists; it owns the map. Paths are relative to the repo root. Create only what is missing and keep existing notes that still apply.

**Respect the existing layout.** If the repo already keeps decisions or handoffs elsewhere (for example one `docs/DECISIONS.md`, or a handoff named in AGENTS.md), use that and adapt the actions below to it. Never migrate a repo to this layout unless the user asks.

The handoff and decision index are loaded into new sessions automatically, so keep them short and current: they are what the next agent sees first.

## init

Create any of these that are absent, each short:

- `docs/README.md`: table of location, owner/purpose, linking every doc below.
- `docs/decisions/INDEX.md`: one line per decision: `- [0001 title](0001-title.md) - status - date`.
- `docs/decisions/spec-issues.md`: table of Topic, Evidence, Resolution/decision trigger. Records discrepancies, not tasks.
- `docs/handoff/current.md`: short state and evidence.
- `docs/TODO.md`: the single active work list.

Add the new files to the README map.

## decide

Write `docs/decisions/NNNN-title.md` (next free number, kebab-case title) with: `Status: proposed | accepted | superseded`, date, context, decision, consequences, and the repo paths it concerns. Add a line to `INDEX.md`.

An accepted decision is never edited. To change one, write a new decision, mark the old one `superseded by NNNN` (status line only) and link back to the old one from the new.

Record a decision when a choice was made between real alternatives, or the user settled something an agent might otherwise re-argue. Routine implementation details are not decisions.

## handoff

Refresh `docs/handoff/current.md` in at most about 40 lines: date, a `Stage: N — <name>[, phase K]` line when the project follows the `project-flow` stages, current branch and working-tree state, what changed this session, exact verification commands and results, open blockers or decisions, and the next bounded task. Check git state rather than recalling it. Keep local edits, commits, pushes and deploys as separate facts. Link to `docs/TODO.md` for remaining work instead of copying it; put spec conflicts in `spec-issues.md`. Replace stale content rather than appending history; git keeps the history. No credentials or full logs.

## learn

When an agent made a mistake the user corrected, or found a non-obvious fact about the repo (a misleading command, a trap in the code, a convention), add one line to a `## Learned rules` section at the end of the repo's root `AGENTS.md` (create the section if missing; use `CLAUDE.md` only if there is no AGENTS.md). One imperative sentence, specific enough to act on, with the reason if it is not obvious. Skip it if an existing line already covers it; merge or delete lines that have gone stale. If the rule belongs in a hook or a test instead (it must never be broken), say so. If the lesson is about how the user works in general rather than this repo (a preference, a workflow habit, a recurring correction across projects), add it instead to the user's global instructions at `~/.config/agent-config/instructions/common.md` (a dotfiles checkout; commit and push it there) so every project and agent learns it.

## lint

Report findings as `file: problem`:

- Decisions whose referenced paths changed after their date (`git log --since=<date> -- <path>`).
- Broken relative links in `docs/`.
- TODO items repeated in `handoff/current.md`.
- Decision files missing from `INDEX.md` (and index lines with no file).
- A handoff older than the latest commits, or longer than about 40 lines.
- Learned rules that contradict the code or each other.

Fix mechanical problems (index lines, links); list the rest.
