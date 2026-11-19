# API contract

The phase files in `endpoints/` are the source of truth for HTTP behaviour; conventions (base URL, envelopes, auth, pagination, IDs, error codes) are in the TRD. A change to API behaviour updates the contract first, in the same change as the code; backend and web follow it.

Phases (add a line per file at stage 3):
