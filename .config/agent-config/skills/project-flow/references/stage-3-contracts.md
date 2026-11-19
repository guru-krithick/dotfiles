# Stage 3: Contracts

Goal: the HTTP contract for every PRD phase, the build order, and the page map. From here on the contract is the source of truth: backend and UI implement it, and changes to behaviour change it first.

Read the approved PRD and TRD. Write one phase file at a time in PRD phase order; each may only use entities and endpoints from its own or earlier phases.

## Outputs

1. `docs/api/endpoints/phase-N-<name>.md` per phase, each linked from `docs/api/README.md`.
2. `docs/architecture/build-order.md`: one sprint per phase with backend and UI exit criteria.
3. `docs/web/PAGES.md`: every route, the endpoints it calls and its states.
4. Add the TRD's error catalog entries for any new error code; add new ID prefixes to the TRD.

## Phase file

```markdown
# Phase N — <Name>

**Endpoints:** <count>
**Depends on:** Phase <M> (<what it uses>) | None
**Entities:** `users`, `tags`
**Key outputs:** what later phases rely on (cookie, IDs, catalogs)

# <Resource group>

**Base:** `/users/*`   **Rate limit:** <if any>
> Group-wide rules (auth, ownership, cross-cutting behaviour).

## METHOD /path/{id}

**Auth:** Public | Session | Role `<role>` (+ ownership rule)
**Idempotency:** Idempotent | `Idempotency-Key` header required; replay returns the first response | Not idempotent (why acceptable)

### Request
Path and query parameters: | Name | Type | Required | Notes |
Body: | Field | Type | Required | Validation |
<example JSON>

### Response — 200 OK   (or 201 Created, 204 No Content)
<full success envelope example, every field with a realistic value; pagination block if paged>
Field notes only where a type or nullability is not obvious.

### Errors
| Status | Code | Condition |
(every case the endpoint can produce; codes come from the TRD catalog)

### Side effects
Writes, emails, jobs, counters, cookies, state transitions.

### Notes
Edge cases, limits, ordering, caching, anything the UI must know.

---
```

Write examples a frontend could type from: concrete IDs with the right prefixes, every field present, `null` where nullable. A field that differs between endpoints for the same entity is a bug in the contract; define one shape per entity and reuse it.

## build-order.md

```markdown
# Build order

## At a glance
| Phase | Focus | Endpoints | Pages | Depends on |

## Dependency graph
Phase 1 → Phase 2 → … with one line per edge saying what is used.

## Phase N — <Name>
Contract: [phase-N-<name>.md](../api/endpoints/phase-N-<name>.md) · Pages: [PAGES.md#phase-n](../web/PAGES.md#phase-n)

### Backend: implementation order
1. Shared pieces first (schemas, repositories), then endpoints in dependency order.

### Backend exit criteria
- [ ] Every endpoint in the phase file implemented with the contracted envelope and errors
- [ ] Tests: success shape and each listed error per endpoint; `pnpm test:api` passes
- [ ] `pnpm check` passes
- [ ] <journey-level criterion, e.g. "a new user can register, verify and log in via curl">
- [ ] Approved by the user

### UI exit criteria
- [ ] Every phase-N page in PAGES.md built with all listed states
- [ ] Typed API modules match the contract; no direct fetch in pages
- [ ] `ui-checker` pass at desktop and narrow widths, no console errors
- [ ] `pnpm check` passes
- [ ] Approved by the user
```

Stage 4 and 5 detection reads these checkboxes, so keep exactly two criteria lists per phase with these headings, and tick them only when true.

## PAGES.md

```markdown
# Page map

Access: public | public-only (redirects signed-in users) | session | role <role>.

## Phase N — <Name>

| Route | Access | Endpoints | States | Notes |
|---|---|---|---|---|
| /login | public-only | POST /auth/login | idle, submitting, field errors, invalid credentials, rate limited | success → /dashboard |
| /projects | session | GET /projects (page mode) | loading, empty (first-run CTA), error + retry, list, next page | filters in URL |
```

States name what the user sees for each response: loading, empty, every error code the endpoint can return that the user can hit, success. A page belongs to the earliest phase whose endpoints it needs.

## Coverage review

Before pausing, have a `reviewer` subagent check and report gaps:

- every PRD feature maps to one or more endpoints, and every PRD phase has a phase file;
- every page's data comes from a listed endpoint, and every endpoint with a UI consumer appears in PAGES.md;
- every error code used is in the TRD catalog; auth, pagination and IDs follow the TRD;
- no phase uses an entity from a later phase.

Fix the gaps, or list them as open questions.

## Exit

Pause: handoff `Stage: 3 — Contracts`, `Gate: awaiting approval`. Ask the user to review phase 1's contract closely and the build order. On approval, tick nothing yet (the exit criteria belong to stages 4 and 5) and move to `Stage: 4 — Backend, phase 1`.
