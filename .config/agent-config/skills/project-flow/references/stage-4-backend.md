# Stage 4: Backend, phase K

Goal: every endpoint in `docs/api/endpoints/phase-K-*.md` implemented exactly as contracted, with tests. No pages in this stage.

Read first: the phase K contract, the TRD (envelopes, auth, pagination, IDs, errors, data model, conventions), `apps/api/AGENTS.md`, the phase K section of `build-order.md` and the code from earlier phases.

## Steps

1. **Plan** the implementation order from build-order.md: shared pieces (config, envelope and error helpers, auth dependency, repositories, schemas) before endpoints, endpoints in dependency order. Phase 1 also builds the shared layer every later phase uses.
2. **Build** with `builder` subagents, one endpoint group per task. Give each the contract section, the TRD sections it touches and the files to follow. Run independent groups in parallel only when they touch different files.
3. **Test** each endpoint: the success response matches the contract example's shape and status; each error in its table is produced under its condition; auth and ownership are enforced; idempotent writes replay correctly; side effects happen (or are mocked and asserted). External services are mocked.
4. **Contract drift.** If the contract turns out wrong or incomplete, stop that endpoint, change the contract file first (and the TRD or PAGES.md if affected), then the code. List every such change for the user at the pause. Never let code silently disagree with the contract.
5. **Review** with a `reviewer` subagent: the diff against the phase contract and TRD, for missing endpoints, wrong status codes or fields, unlisted errors and missing tests.
6. **Verify:** `pnpm check` passes; start the API (`pnpm dev:api`) and exercise the phase's journey with `curl` (for example, register → log in → `GET /users/me` with the cookie jar). Fix what fails; use the `debug` skill when the cause is unclear.
7. Tick the phase K backend exit criteria that are now true (all but the approval line).

## Output

Phase K routers, services, repositories, schemas and tests in `apps/api`; any contract corrections in `docs/api`; `docs/TODO.md` updated.

## Pause

Handoff `Stage: 4 — Backend, phase K`, `Gate: awaiting approval`, with the check results and curl evidence. Tell the user what to try, which contract changes were made, and that UI for phase K comes next. On approval tick the approval line and move to `Stage: 5 — UI, phase K`.
