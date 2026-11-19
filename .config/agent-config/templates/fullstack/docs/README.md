# Document map and ownership

Documents marked "stage N" are created at that stage of the `project-flow` skill; link them here once they exist.

| Location | Owner / purpose |
| --- | --- |
| `product/PRD.md` (stage 1) | Product intent: users, journeys, features by phase, scope, metrics |
| `architecture/TRD.md` (stage 2) | Architecture, stack and API conventions (envelopes, auth, pagination, IDs, errors, data model) |
| [API contracts](api/README.md) (stage 3) | The source of truth for HTTP behaviour, one file per phase in `api/endpoints/` |
| `architecture/build-order.md` (stage 3) | Phase sequence with backend and UI exit criteria |
| `web/PAGES.md` (stage 3) | Page map: route, access, endpoints, states |
| [Decisions](decisions/INDEX.md) and [spec issues](decisions/spec-issues.md) | Settled choices; unresolved conflicts between documents |
| [Current handoff](handoff/current.md) | Current stage, state and evidence |
| [TODO](TODO.md) | Single active work list |

Update the owned document when behaviour changes. A change to API behaviour updates the contract before the code.
