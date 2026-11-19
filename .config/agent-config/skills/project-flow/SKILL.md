---
name: project-flow
description: Run a product build in stages - by default contract-first and backend before UI (scaffold, product requirements (PRD), technical requirements (TRD) and decisions, API contracts, then backend and UI phase by phase), with a frontend-only track and a light track for small jobs, and any stage skippable on request; pauses for the user's approval after every stage. Says which stage or phase comes next, what it must produce and which skills and agents it uses; detects the current stage from the handoff or from the docs that exist. Use when starting a new product, app or frontend, when asked to continue, resume or plan what to build next, when moving to the next stage or phase, or when a feature request in an existing project needs a contract change before code. Not for designing a screen (ui), recording decisions or handoffs (wiki), exploring an idea (brainstorming), interviewing about a plan (grilling) or fixing a bug (debug).
---

The user builds products contract-first, backend before UI. Each stage has one job and an output the user approves before the next stage starts. This file routes; read only the reference for the stage at hand (in `references/`, next to this file).

This is the default, not a rule. Fit the process to the job: pick a track, and drop any stage the user does not want.

## Tracks

| Track | When | Stages |
|---|---|---|
| **full** (default) | The user's own product with a backend they build | 0 → 1 → 2 → 3 → 4/5 per phase, as below |
| **frontend** | UI only: someone else owns the backend, or there is none (e.g. jaggs) | 0 (web app only) → 1 → 2 light → 5 per phase. No contracts (3) or backend (4) |
| **light** | A small, low-stakes or low-paid job | One short brief (goal, scope, done-when) in the handoff or `docs/`, one approval, build, one review at the end. No PRD, TRD, contracts or per-stage pauses |

- **Choose it at the start.** New project: recommend a track from the idea in one line and let the user confirm. Existing project: read the `Track:` line in the handoff; without one, infer it (no backend in the repo or the user owns only the UI → frontend) and say so in one line.
- **Frontend track rules.** Stage 2 covers the web architecture, state and the data shapes the UI expects; it has no API envelopes or endpoints. Build against labelled demo data or the payloads the backend owner has published. Never write or invent an API contract, and never mark an assumed payload as confirmed. Leave `api_paths` out of `.agents/flow.json` so the contract-sync hook stays quiet.
- **Skip on request.** The user can skip, merge or reorder any stage at any time ("no PRD", "skip the contract", "just build it"). Do it without arguing, write `Skipped: <stage> (user, <date>)` in the handoff, and do not raise it again. The checks for a skipped stage (doc status, exit criteria) no longer apply.
- **Respect existing projects.** In a repo not built with this flow, keep its own doc layout and names (jaggs keeps its PRD, TRD and UI spec in `frontend/docs/`) and map the stages onto them instead of adding new files.

## Stages

| # | Stage | Produces | Done when | Reference |
|---|---|---|---|---|
| 0 | Scaffold | Repo from the `templates/fullstack` template, generated web and API apps, wiki docs, hooks | `pnpm check` passes; user approves | [stage-0-scaffold.md](references/stage-0-scaffold.md) |
| 1 | Product | `docs/product/PRD.md`: users, journeys, features grouped into phases, scope, metrics | PRD `Status: Approved` | [stage-1-product.md](references/stage-1-product.md) |
| 2 | Technical | `docs/architecture/TRD.md` (incl. envelopes, auth, pagination, IDs, errors, data model, web architecture); one decision per real choice | TRD `Status: Approved` | [stage-2-technical.md](references/stage-2-technical.md) |
| 3 | Contracts | `docs/api/endpoints/phase-N-<name>.md` per phase, `docs/architecture/build-order.md`, `docs/web/PAGES.md` | user approves; build order lists every phase | [stage-3-contracts.md](references/stage-3-contracts.md) |
| 4 | Backend, phase K | Phase K endpoints exactly as contracted, with tests | phase K backend exit criteria ticked | [stage-4-backend.md](references/stage-4-backend.md) |
| 5 | UI, phase K | Phase K pages from the page map, wired to phase K endpoints | phase K UI exit criteria ticked | [stage-5-ui.md](references/stage-5-ui.md) |

Stages 4 and 5 alternate per phase: backend 1 → UI 1 → backend 2 → UI 2 … A phase's pages are built only after its endpoints exist and pass their tests.

## Find the current stage

1. **Handoff first.** `docs/handoff/current.md` (loaded at session start) carries two lines:

   ```
   Track: full | frontend | light
   Stage: 4 — Backend, phase 2
   Gate: in progress | awaiting approval
   ```

   A missing `Track:` line means full.

   Check it against the files below; if they disagree, trust the files and say so.
2. **Otherwise infer it**; the first rule that matches wins (skip rules for stages the track or the user dropped):
   - No `AGENTS.md`, `apps/` or `docs/README.md`: stage 0. In an existing repo that was not built this way, ask before adopting the flow, and never scaffold over existing code.
   - `docs/product/PRD.md` missing or its header not `**Status:** Approved`: stage 1.
   - `docs/architecture/TRD.md` missing or its header not `**Status:** Approved`: stage 2.
   - No `docs/api/endpoints/phase-*.md` or no `docs/architecture/build-order.md`: stage 3.
   - In `build-order.md`, the first phase with an unticked backend exit criterion: stage 4 for that phase; else the first with an unticked UI exit criterion: stage 5 for that phase.
   - Everything ticked: the planned build is complete; new work enters through the feature rule below.
3. Tell the user the stage in one line ("Stage 4, backend for phase 2: …") before working.

## Pause after every stage

At the end of each stage the track keeps, and after each phase's backend and each phase's UI (the light track pauses only after the brief and at the end):

1. Run the stage's exit checks and tick what passed (doc status, build-order checkboxes).
2. Refresh the handoff with the `wiki` skill (`handoff`), including the `Stage:` line and `Gate: awaiting approval`, plus any decisions made (`decide`).
3. Commit the stage's work if the user's instructions say to commit finished work.
4. Give the user a short review list: what was produced (paths), what to check, open questions and the next stage. Then **stop**. Never start the next stage in the same turn.

Only an explicit user approval opens the gate. On approval: mark the document `Status: Approved` (PRD, TRD) or tick the approval line, set the handoff to the next stage with `Gate: in progress`, and continue. A requested change means revise and pause again. A session that starts on `Gate: awaiting approval` asks for that approval first.

## Feature requests in an existing project

On the full track the contract in `docs/api` is the source of truth, so behaviour changes go contract → backend → UI (frontend track: update the UI spec and data shapes, then the UI; light track: just build it):

1. Find the affected phase file. Write the change there first: new or changed endpoint entries, error codes, envelope fields. Update the PRD when product scope changes, `PAGES.md` when pages change, and record a decision when a real choice was made.
2. Add the work to `build-order.md`: new exit criteria under the phase it extends, or a new phase.
3. Pause for approval of the contract change (a small change can be confirmed in one line).
4. Build the backend against it, then the UI, each with the stage 4/5 checks.

No contract change is needed for a UI-only change that uses existing endpoints as contracted, or for a bug fix that restores contracted behaviour (use `debug`); say which applies. The project's `contract-sync` Stop hook flags API code changed without a contract change; answer it with the contract update or the reason.

## Skills and agents per stage

| Stage | Use |
|---|---|
| 0 | `wiki` (`init` for anything the template lacks); `quick-worker` for mechanical setup |
| 1 | `brainstorming` to work out what to build (its design doc feeds the PRD); `wiki decide` for settled product choices |
| 2 | `grilling` to settle open technical choices in rounds; `wiki decide`, one decision per choice; `Explore` for facts about existing code |
| 3 | `reviewer` subagent: every PRD feature has endpoints, every page's data has an endpoint, every error code is in the catalog |
| 4 | `builder` subagents per endpoint group; `reviewer` against the contract; `debug` for failures |
| 5 | `ui` for every screen (first UI phase sets up PRODUCT.md/DESIGN.md); `builder` for data wiring; `ui-checker` for the running pages |
| Every pause | `wiki handoff` |

## Project hooks

The template wires three Claude hooks in `.claude/settings.json`, configured by `.agents/flow.json` (`api_paths`, `contract_paths`, `code_paths`, `check`, `check_timeout`, `format`): format on edit, the contract reminder and a typecheck gate when the agent stops. Keep `flow.json` accurate when the layout or checks change. They live in agent-config and do nothing where it is not installed.

## Stack

Default: pnpm monorepo, `apps/web` Next.js + React + TypeScript (Biome, Vitest), `apps/api` FastAPI + Python 3.12 + uv (Ruff, Pyright, pytest), `docs/` as the wiki, root `pnpm` scripts as the shared interface. Ask only when the product clearly needs something else (no web UI, native mobile, an existing stack); record the change as a decision and update `flow.json`, AGENTS.md and the root scripts to match.
