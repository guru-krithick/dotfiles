# Stage 0: Scaffold

Goal: an empty repository becomes a working monorepo whose checks pass, with the wiki and hooks in place. No product code yet.

Before starting, ask for the product idea in a sentence or two if the user has not given it. Use the default stack unless that idea clearly needs something else (see the stack rule in SKILL.md).

Never scaffold over an existing project. In a repo that already has code, add only what is missing (wiki files with `wiki init`, `.agents/flow.json`, `.claude/settings.json`) after asking.

## Steps

Run from the new project's root. `<name>` is a short kebab-case project name.

1. **Copy the template** without overwriting anything:

   ```sh
   T="${XDG_CONFIG_HOME:-$HOME/.config}/agent-config/templates/fullstack"
   cp -an "$T"/. .
   git init -b main   # if not already a repo
   grep -rl __PROJECT__ . --exclude-dir=.git | xargs -r sed -i 's/__PROJECT__/<name>/g'
   ```

2. **Web app.** create-next-app refuses a directory with an AGENTS.md, so move the stub aside and merge it back:

   ```sh
   mv apps/web/AGENTS.md apps/web.AGENTS.md
   pnpm dlx create-next-app@latest apps/web --ts --tailwind --biome --app --src-dir \
     --import-alias "@/*" --use-pnpm --skip-install --disable-git --yes
   { cat apps/web.AGENTS.md; echo; cat apps/web/AGENTS.md; } > apps/web/AGENTS.md.new
   mv apps/web/AGENTS.md.new apps/web/AGENTS.md && rm apps/web.AGENTS.md
   rm apps/web/pnpm-workspace.yaml apps/web/README.md
   ```

   Keep the generated `nextjs-agent-rules` block in `apps/web/AGENTS.md`: `next dev` re-adds it. Merge any `allowBuilds` entries from the removed `apps/web/pnpm-workspace.yaml` into the root one (as `true` for packages that need install scripts, such as `sharp`). In `apps/web/package.json`: set `"name": "@<name>/web"`, delete `packageManager` (the root owns it), and make the scripts:

   ```json
   "lint": "biome lint .",
   "format": "biome format --write",
   "format:check": "biome format .",
   "typecheck": "tsc --noEmit",
   "test": "vitest run --passWithNoTests"
   ```

   ```sh
   pnpm --filter ./apps/web add -D vitest @vitejs/plugin-react jsdom \
     @testing-library/react @testing-library/jest-dom @testing-library/user-event
   ```

   Add `apps/web/vitest.config.ts` (React plugin, `environment: "jsdom"`, the `@` alias to `./src`).

3. **API app:**

   ```sh
   uv init --bare --python 3.12 --vcs none --name api apps/api
   uv --directory apps/api add "fastapi[standard]" pydantic-settings
   uv --directory apps/api add --dev ruff pyright pytest
   ```

   Then write, by hand:
   - `app/__init__.py` (empty) and `app/main.py`: a FastAPI app with `GET /api/v1/health` returning `{"success": true, "data": {"status": "ok"}}`.
   - `tests/test_health.py`: the health route through `fastapi.testclient.TestClient`, asserting status 200 and the envelope.
   - In `pyproject.toml`:

     ```toml
     [tool.ruff]
     line-length = 100
     target-version = "py312"

     [tool.ruff.lint]
     select = ["E", "F", "I", "UP", "B"]

     [tool.pyright]
     include = ["app", "tests"]
     venvPath = "."
     venv = ".venv"
     pythonVersion = "3.12"

     [tool.pytest.ini_options]
     pythonpath = ["."]
     testpaths = ["tests"]
     ```

4. **Pin the package manager and install:** set the root `"packageManager": "pnpm@<pnpm --version>"`, then `pnpm install` and `uv --directory apps/api sync`.

5. **Verify:** `pnpm format`, then `pnpm check` passes. `pnpm dev` serves the web app on :3000 and `curl -s localhost:8000/api/v1/health` returns the envelope. Run `git status` to confirm no generated caches or `.env` files are tracked.

## Output

- Root: `package.json` (`dev`, `dev:web`, `dev:api`, `lint`, `format`, `format:check`, `typecheck`, `test:web`, `test:api`, `build:web`, `check`), `pnpm-workspace.yaml`, `AGENTS.md`, `CLAUDE.md` (`@AGENTS.md`), `.gitignore`, `.editorconfig`.
- `.agents/flow.json` and `.claude/settings.json`: the flow hooks. Check `flow.json` paths match the generated layout.
- `apps/web` (Next.js, Biome, Vitest) and `apps/api` (FastAPI, Ruff, Pyright, pytest), each with its AGENTS.md.
- `docs/`: README map, TODO, handoff, decisions index, spec issues, `api/README.md`, empty `product/`, `architecture/`, `api/endpoints/`, `web/`.

## Pause

Handoff `Stage: 0 — Scaffold`, `Gate: awaiting approval`, with the check results. Show the user the tree and results, and ask to start stage 1 (the product interview).
