# __PROJECT__ agent guide

Read [docs/README.md](docs/README.md) for document ownership and [the current handoff](docs/handoff/current.md) before starting. Before editing an app, read its guide: [web](apps/web/AGENTS.md) or [API](apps/api/AGENTS.md).

## Repository

- `apps/web`: Next.js / React / TypeScript, in the pnpm workspace.
- `apps/api`: FastAPI / Python 3.12, dependencies and tools managed by uv.
- `docs`: the project wiki: product (PRD), architecture (TRD, build order), API contracts, web page map, decisions, handoff, TODO.

## Workflow

The project is built contract-first, backend before UI, with the `project-flow` skill: 0 Scaffold → 1 Product → 2 Technical → 3 Contracts → 4 Backend → 5 UI, where 4 and 5 run phase by phase. The `Stage:` line in the handoff says where work stands. Pause for the owner's approval after every stage and after each phase's backend and UI.

The API contract in [docs/api](docs/api/README.md) is the source of truth. A change to API behaviour updates the contract first, then the backend, then the UI; backend and UI follow the contract, never the other way round. Record discrepancies between documents in [spec issues](docs/decisions/spec-issues.md).

Keep one active work list at [docs/TODO.md](docs/TODO.md). Use the `wiki` skill for decisions, handoffs and learned rules.

## Commands

Setup: `pnpm install` and `uv --directory apps/api sync`. `pnpm dev` runs both apps; `pnpm dev:web` and `pnpm dev:api` run one. Checks: `pnpm lint`, `pnpm format:check`, `pnpm typecheck`, `pnpm test:web`, `pnpm test:api`, `pnpm build:web`; `pnpm check` runs all but the build. `pnpm format` rewrites files. Report the checks you actually ran and their results.

`.claude/settings.json` wires the agent-config flow hooks, configured in `.agents/flow.json`: format on edit, a contract reminder and a typecheck gate when the agent stops. Without agent-config installed they do nothing.

## Learned rules
