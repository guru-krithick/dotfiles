# API agent guide

Read the [root guide](../../AGENTS.md), the [TRD](../../docs/architecture/TRD.md) (envelopes, auth, pagination, IDs, errors, data model) and the contract for the phase you are building ([index](../../docs/api/README.md)). The contract is the source of truth: if code and contract must differ, change the contract first and say so.

FastAPI, Pydantic v2, Python 3.12, async I/O. Layout: `app/main.py` creates the app; `app/domains/<domain>/{router,service,repository,schemas}.py`; `app/shared/` holds envelopes, errors, auth and middleware; `app/core/config.py` owns settings. Routers call services, services call repositories and integrations. Every route returns the TRD's success or error envelope.

Tests are pytest under `tests/`. Every endpoint gets a test for its success response and for each error the contract lists. Mock external services.

Run tools through uv in this directory (`uv run pytest -q`, `uv run ruff check .`, `uv run pyright`) or the root `pnpm` scripts.
