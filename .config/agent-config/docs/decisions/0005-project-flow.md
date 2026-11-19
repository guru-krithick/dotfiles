# 0005: The user's build flow as a skill, template and hooks

Accepted 2026-11-19.

**Context.** The user builds contract-first and backend before UI: scaffold → PRD → TRD → API contracts in markdown → backend → UI derived from the endpoints. Agents should follow this without being told each time, and learn the user's style over time.

**Decisions.**

1. **Philosophy in `instructions/common.md`** ("How I build"), so every project and both agents follow it.
2. **`project-flow` skill** owns the stages: 0 Scaffold, 1 PRD, 2 TRD + decisions, 3 contracts (`docs/api/endpoints/phase-N.md`, `build-order.md`, `docs/web/PAGES.md`), 4 backend, 5 UI. Stages 4 and 5 alternate **per phase**. The agent **pauses for approval after every stage** and each phase's backend and UI. The handoff records `Stage:` and `Gate:` lines so the next session resumes there. `/kickoff` starts it.
3. **Default stack is the klyz stack** (pnpm monorepo, Next.js + TypeScript, FastAPI + uv); the agent asks only when the PRD clearly needs something else. `templates/fullstack/` is the stage-0 scaffold.
4. **Per-project hooks** configured by `.agents/flow.json` and wired in the project's `.claude/settings.json`: `contract-sync` (Stop; blocks once when API code changed without a `docs/api` change), `quality-gate` (Stop; runs the project's fast check once per change set, continues on failure), `format-on-edit` (PostToolUse; never blocks). All fail open and do nothing for collaborators without these dotfiles. Codex follows the same rules by instruction.
5. **Learning the user's style.** `wiki learn` writes repo lessons to the repo's AGENTS.md and general lessons to `common.md`.

**Consequences.** Claude-only enforcement for hooks; Codex relies on instructions and the same check commands. The full stage-0 scaffold has not yet been run end to end.
