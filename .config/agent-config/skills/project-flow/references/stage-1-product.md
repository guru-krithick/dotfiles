# Stage 1: Product (PRD)

Goal: `docs/product/PRD.md`, the product intent every later stage derives from. It says what and why, never how: no endpoints, tables or libraries.

## Interview first

Use the `brainstorming` skill before writing; its approved design doc is the raw material for the PRD (write the PRD instead of a separate spec, or link the spec from it). The conversation usually covers: the problem and who has it; user roles and what each wants; the core journeys end to end; features, and which depend on which; what is explicitly out of scope for v0; how it makes money (if it does); how success is measured; constraints (performance, security, money, data retention, locale, devices). Look up facts yourself; put every decision to the user. On the frontend track, the PRD covers screens, journeys and what the client approves; backend features belong to whoever owns the backend.

## Phases

Group features into 3 to 7 phases in build order. Phase 1 is the foundation the rest depends on (accounts, auth, profiles, shared catalogs). Each later phase is a vertical slice a user can exercise once its backend and UI exist, and depends only on earlier phases. These phases become the contract files, build-order sprints and page groups of stage 3.

## PRD outline

```markdown
# <Product> — Product Requirements Document

**Version:** 0.1 | **Status:** Draft | **Date:** YYYY-MM-DD

## 1. Executive summary      what it is, for whom, the one differentiator, how it earns
## 2. Problem statement      who hurts, how they cope today, why that fails
## 3. Vision                 what success looks like in a sentence or two
## 4. Target users           one subsection per role: goals, context, constraints
## 5. User journeys          one numbered journey per role, end to end
## 6. Core features          ### Phase N — <name>: table | Feature | Description |
## 7. Business model         revenue, pricing or fees, payment flow (omit if none)
## 8. Success metrics (v0)   table | Metric | Definition |
## 9. Out of scope (v0)      bullet list; anything a reader might assume is included
## 10. Non-functional requirements   table | Area | Requirement | (latency, security, money, privacy, reliability)
## 11. Open questions        only what the user chose to leave open
```

Feature descriptions are specific enough to derive endpoints from: limits, TTLs, roles allowed, state changes ("Password reset: token-based, 1h TTL, logs the user in"). Keep it short: a table row per feature, not prose.

## Output and exit

- `docs/product/PRD.md` with `Status: Draft`; add it to `docs/README.md`.
- A decision (`wiki decide`) for each settled product choice an agent might re-argue (who the users are, what is out of scope, the business model).
- Pause: handoff `Stage: 1 — Product`, `Gate: awaiting approval`. Ask the user to review the phases and out-of-scope list in particular. On approval set `Status: Approved`.
