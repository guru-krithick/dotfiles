---
name: project-flow
description: Run a product build contract-first and backend before UI - scaffold, product requirements (PRD), technical requirements (TRD) and decisions, API contracts, then backend and UI phase by phase, pausing for the user's approval after every stage. Says which stage or phase comes next, what it must produce and which skills and agents it uses; detects the current stage from the handoff or from the docs that exist. Use when starting a new product or full-stack app, when asked to continue, resume or plan what to build next, when moving to the next stage or phase, or when a feature request in an existing project needs a contract change before code. Not for designing a screen (ui), recording decisions or handoffs (wiki), interviewing about a plan (grilling) or fixing a bug (debug).
---

The user builds products contract-first, backend before UI. Each stage has one job and an output the user approves before the next stage starts. This file routes; read only the reference for the stage at hand (in `references/`, next to this file).

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
   Stage: 4 — Backend, phase 2
   Gate: in progress | awaiting approval
   ```

   Check it against the files below; if they disagree, trust the files and say so.
2. **Otherwise infer it**; the first rule that matches wins:
   - No `AGENTS.md`, `apps/` or `docs/README.md`: stage 0. In an existing repo that was not built this way, ask before adopting the flow, and never scaffold over existing code.
   - `docs/product/PRD.md` missing or its header not `**Status:** Approved`: stage 1.
   - `docs/architecture/TRD.md` missing or its header not `**Status:** Approved`: stage 2.
   - No `docs/api/endpoints/phase-*.md` or no `docs/architecture/build-order.md`: stage 3.
   - In `build-order.md`, the first phase with an unticked backend exit criterion: stage 4 for that phase; else the first with an unticked UI exit criterion: stage 5 for that phase.
   - Everything ticked: the planned build is complete; new work enters through the feature rule below.
3. Tell the user the stage in one line ("Stage 4, backend for phase 2: …") before working.

## Pause after every stage

At the end of each stage, and after each phase's backend and each phase's UI:

1. Run the stage's exit checks and tick what passed (doc status, build-order checkboxes).
2. Refresh the handoff with the `wiki` skill (`handoff`), including the `Stage:` line and `Gate: awaiting approval`, plus any decisions made (`decide`).
3. Commit the stage's work if the user's instructions say to commit finished work.
4. Give the user a short review list: what was produced (paths), what to check, open questions and the next stage. Then **stop**. Never start the next stage in the same turn.

Only an explicit user approval opens the gate. On approval: mark the document `Status: Approved` (PRD, TRD) or tick the approval line, set the handoff to the next stage with `Gate: in progress`, and continue. A requested change means revise and pause again. A session that starts on `Gate: awaiting approval` asks for that approval first.

## Feature requests in an existing project

The contract in `docs/api` is the source of truth, so behaviour changes go contract → backend → UI:

1. Find the affected phase file. Write the change there first: new or changed endpoint entries, error codes, envelope fields. Update the PRD when product scope changes, `PAGES.md` when pages change, and record a decision when a real choice was made.
2. Add the work to `build-order.md`: new exit criteria under the phase it extends, or a new phase.
3. Pause for approval of the contract change (a small change can be confirmed in one line).
4. Build the backend against it, then the UI, each with the stage 4/5 checks.

No contract change is needed for a UI-only change that uses existing endpoints as contracted, or for a bug fix that restores contracted behaviour (use `debug`); say which applies. The project's `contract-sync` Stop hook flags API code changed without a contract change; answer it with the contract update or the reason.

## Skills and agents per stage

| Stage | Use |
|---|---|
| 0 | `wiki` (`init` for anything the template lacks); `quick-worker` for mechanical setup |
| 1 | `grilling` to interview the user before writing; `wiki decide` for settled product choices |
| 2 | `grilling` for open technical choices; `wiki decide`, one decision per choice; `Explore` for facts about existing code |
| 3 | `reviewer` subagent: every PRD feature has endpoints, every page's data has an endpoint, every error code is in the catalog |
| 4 | `builder` subagents per endpoint group; `reviewer` against the contract; `debug` for failures |
| 5 | `ui` for every screen (first UI phase sets up PRODUCT.md/DESIGN.md); `builder` for data wiring; `ui-checker` for the running pages |
| Every pause | `wiki handoff` |

## Project hooks

The template wires three Claude hooks in `.claude/settings.json`, configured by `.agents/flow.json` (`api_paths`, `contract_paths`, `code_paths`, `check`, `check_timeout`, `format`): format on edit, the contract reminder and a typecheck gate when the agent stops. Keep `flow.json` accurate when the layout or checks change. They live in agent-config and do nothing where it is not installed.

## Stack

Default: pnpm monorepo, `apps/web` Next.js + React + TypeScript (Biome, Vitest), `apps/api` FastAPI + Python 3.12 + uv (Ruff, Pyright, pytest), `docs/` as the wiki, root `pnpm` scripts as the shared interface. Ask only when the product clearly needs something else (no web UI, native mobile, an existing stack); record the change as a decision and update `flow.json`, AGENTS.md and the root scripts to match.
