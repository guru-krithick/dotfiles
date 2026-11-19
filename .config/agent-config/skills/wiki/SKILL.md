---
name: wiki
description: Create and maintain a repository's docs wiki (docs/README.md map, decisions, handoff, TODO). Actions - init missing docs, decide (record a numbered decision), handoff (refresh docs/handoff/current.md with state and evidence), lint (stale decisions, broken links, duplicated TODO items, missing index lines). Use when asked to write a decision, hand off or summarize a session for the next one, set up project docs, or check the docs for drift.
---

Pick the action from the request. Read `docs/README.md` first when it exists; it owns the map. Paths are relative to the repo root. Create only what is missing and keep existing notes that still apply.

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

## handoff

Refresh `docs/handoff/current.md`: date, current branch and working-tree state, what changed this session, exact verification commands and results, open blockers or decisions, and the next bounded task. Check git state rather than recalling it. Keep local edits, commits, pushes and deploys as separate facts. Link to `docs/TODO.md` for remaining work instead of copying it; put spec conflicts in `spec-issues.md`. No credentials or full logs.

## lint

Report findings as `file: problem`:

- Decisions whose referenced paths changed after their date (`git log --since=<date> -- <path>`).
- Broken relative links in `docs/`.
- TODO items repeated in `handoff/current.md`.
- Decision files missing from `INDEX.md` (and index lines with no file).

Fix mechanical problems (index lines, links); list the rest.
