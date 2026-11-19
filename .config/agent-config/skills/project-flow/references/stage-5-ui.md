# Stage 5: UI, phase K

Goal: every phase K page in `docs/web/PAGES.md`, built on the phase K endpoints as contracted, with all listed states, verified in a browser.

Read first: the phase K section of PAGES.md, the phase K contract, the web section of the TRD, `apps/web/AGENTS.md`, and existing pages and components.

## Steps

1. **Design world (first UI phase only).** Use the `ui` skill to create PRODUCT.md and DESIGN.md (impeccable `init`) before the first screen, so later phases share one visual system. Later phases reuse it.
2. **Data layer.** For each API resource the phase uses, add or extend a typed module in `apps/web/src/api/` whose request and response types mirror the contract (`data`, `pagination`, error `code` and `details`). The shared client unwraps the envelope and normalises errors once. Pages never call `fetch` directly. If a type cannot be written from the contract, the contract is incomplete: fix it first (stage 4 drift rule).
3. **Pages.** Build each route with the `ui` skill, implementing every state listed in the page map: loading, empty, each user-reachable error code (field errors map onto form fields), success. Route guards follow the access column. Delegate data wiring to `builder` subagents where it is mechanical.
4. **Tests.** Vitest and Testing Library for behaviour that matters: forms submit the contracted body, error codes show the right message, empty and error states render. Mock the API module, not the network.
5. **Verify in the browser.** Run both apps (`pnpm dev`) against the real phase K backend, and have a `ui-checker` subagent check each new route at desktop and narrow widths, through the journey's states, with the console clean. Fix the findings. Without a browser check, say so rather than claim a visual pass.
6. `pnpm check` passes; tick the phase K UI exit criteria that are now true (all but the approval line).

## Output

Phase K routes, components and API modules in `apps/web`, tests beside them; PAGES.md updated if states or routes changed (with the contract, if data needs changed).

## Pause

Handoff `Stage: 5 — UI, phase K`, `Gate: awaiting approval`, with the routes checked and the ui-checker results. Tell the user which journey to click through. On approval tick the approval line and move to `Stage: 4 — Backend, phase K+1`, or, after the last phase, record the build as complete; new work then enters through the feature rule in SKILL.md.
