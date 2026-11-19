# Stage 2: Technical (TRD and decisions)

Goal: `docs/architecture/TRD.md`, the rules every endpoint and page follows, plus a decision record for each real choice. Read the approved PRD first; every NFR and feature constraint must land somewhere here.

## Process

1. List the open technical choices the PRD forces: database and data model style, auth method and session storage, file storage, payments, email, background jobs, search, real-time delivery, hosting. The stack itself is the default unless stage 0 recorded otherwise.
2. Settle them with the user, a round at a time (`grilling` format: numbered questions, each with your recommended answer). Research versions and limits yourself.
3. Record each settled choice with `wiki decide` (context, options, decision, consequences).
4. Write the TRD. Where the user has no preference, use the defaults below and say so.

## TRD outline

```markdown
# <Product> — Technical Requirements Document

**Version:** 0.1 | **Status:** Draft | **Date:** YYYY-MM-DD

## 1. System architecture     diagram (browser → web → API → stores and integrations); principles
## 2. Tech stack              table | Layer | Choice | Why (link decision) |
## 3. Project structure       tree of apps/web/src and apps/api/app with each folder's role
## 4. API conventions
###  Base URL                 /api/v1
###  Response envelopes       success and error JSON (below)
###  Authentication           mechanism, cookie or header, TTL, refresh or not, how the API resolves the user, roles
###  Pagination               cursor or page mode per kind of list, with the exact fields
###  Errors                   catalog table | Code | HTTP | Condition |
###  Idempotency              which writes take an Idempotency-Key, how replays respond; webhooks
###  Rate limits              per route group
###  Conventions              money, timestamps, enums, null vs absent fields, naming
## 5. ID system               prefix table | Prefix | Entity | Phase |
## 6. Data model              store rules; table | Entity | Key fields | Owner |; denormalized fields and when they update; indexes
## 7. Files and storage       buckets, upload strategy, ownership checks (if any)
## 8. Security                auth flow, password and token handling, CORS/Origin, secrets, PII in logs
## 9. Integrations            each external service: purpose, failure handling, webhooks
## 10. State machines         per stateful entity: states, transitions, who may trigger them
## 11. Background work        jobs, schedules, retries, idempotency
## 12. Web architecture       rendering, routing groups and guards, data layer (typed API modules, cache), state ownership, forms and validation, error display
## 13. Code conventions       required and forbidden patterns, layering rules
## 14. Testing strategy       what each level covers; no real external calls in unit tests
## 15. Local development      commands, services, env vars table | Variable | Used by | Example |
## 16. Gotchas and open questions
```

Defaults, generalised from the reference project (change them only through a decision):

```json
{ "success": true, "message": "optional", "data": {}, "pagination": {} }
{ "success": false, "message": "Human-readable", "error": { "code": "VALIDATION_ERROR", "details": {} } }
```

- Field errors go in `error.details.errors` as `[{ "field": "email", "message": "…" }]`.
- Error codes: `VALIDATION_ERROR` 400, `UNAUTHORIZED` 401, `FORBIDDEN` 403, `NOT_FOUND` 404, `CONFLICT` 409, `UNPROCESSABLE` 422 (business rule or illegal state transition), `TOO_MANY_REQUESTS` 429, `EXTERNAL_SERVICE_ERROR` 502, `INTERNAL_ERROR` 500.
- Auth: httpOnly, `SameSite=Lax` (or Strict) session cookie set by the API; the web never reads it and learns the user from `GET /users/me`.
- Pagination: cursor mode (`cursor`, `limit` in; `next_cursor`, `has_more` out) for feeds and chats; page mode (`page`, `limit` in; `total`, `total_pages`, `has_next`, `has_prev` out) for browsable lists.
- IDs: opaque prefixed ULIDs (`usr_01H…`); the ID is the primary key, never a second field.
- Money as integers in the smallest unit the product uses; timestamps RFC 3339 UTC.

If the web architecture is large, put section 12 in `docs/web/TRD-FRONTEND.md` and link it.

## Output and exit

- `docs/architecture/TRD.md` (`Status: Draft`), decisions under `docs/decisions/` with index lines, both linked from `docs/README.md`.
- A stack change from the default also updates `AGENTS.md`, the root scripts and `.agents/flow.json`.
- Pause: handoff `Stage: 2 — Technical`, `Gate: awaiting approval`. Ask the user to review the stack table, envelopes, auth and data model. On approval set `Status: Approved`.
