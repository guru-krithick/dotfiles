# Web agent guide

Read the [root guide](../../AGENTS.md), the [page map](../../docs/web/PAGES.md), the web section of the [TRD](../../docs/architecture/TRD.md) and the API contract for the phase you are building ([index](../../docs/api/README.md)).

Pages are derived from the contract: every request goes through a typed module per API resource in `src/api/`, whose types mirror the contract's response `data`. Unwrap the envelope there; pages never call `fetch` directly. Each page implements the loading, empty, error and success states listed in the page map. Use the `ui` skill for interface work and the `ui-checker` agent to verify routes in a browser.

Tests are Vitest and Testing Library beside the code as `*.test.ts(x)`; assert what a user can see and do.

From the root: `pnpm dev:web`, `pnpm test:web`, `pnpm --filter ./apps/web lint`, `pnpm --filter ./apps/web typecheck`, `pnpm build:web`.
