# Personal working preferences

- Follow the current request and each repository's applicable instructions. Keep changes within the requested scope and preserve existing work.
- Continue authorized, reversible work without repeatedly asking for confirmation. Ask when a missing decision materially affects the outcome or an action needs authorization.
- Keep progress updates and final responses concise and concrete. Report what changed, what was actually checked, and any remaining limitation.
- Use the repository's declared package manager, scripts, and existing tools. Check local instructions before introducing another dependency or workflow.
- For substantial build work, delegate to subagents: the strongest model at its default effort for hard tasks (max effort only when asked), a lighter model for simple ones; quick checks and research can stay inline. Prefer existing tools, packages and upstream templates over custom code, and say what is reused.
- For UI changes, inspect the running interface when browser tools are available. Distinguish browser verification from typechecking or code inspection.
- Run checks appropriate to the change. Add tests when they verify meaningful behavior; routine visual, copy, and configuration edits do not need tests that only repeat the implementation.
- The project wiki under `docs/` is the memory between sessions and agents. At the start of work, read `docs/handoff/current.md` and the decision index (or `docs/DECISIONS.md`) if they exist and were not already loaded. Verify dated notes against the current working tree.
- Before finishing substantial work, update the wiki with the `wiki` skill: record decisions, refresh the handoff, and turn any mistake you or the user corrected into a one-line rule (`learn`).
- Follow repository attribution requirements. Otherwise omit AI co-author trailers and generated-with footers from commits and PR descriptions.
- Commit and push finished, verified work without asking; use conventional commit messages. A roadmap, skill, or handoff provides context; it does not authorize extra features, deployments, paid services, or messages to other people.

## How I build

- Contract-first, backend before UI. For a product: scaffold → product requirements (PRD) → technical requirements (TRD) and decisions → API contracts in markdown → backend → UI derived from the endpoints. Use the `project-flow` skill to find the current stage and what it must produce.
- The API contract in `docs/api` is the source of truth. A feature that changes behaviour updates the contract before the code; backend and UI follow the contract, not the other way round.
- Backend and UI go phase by phase: a phase's endpoints are built and tested, then that phase's pages, then the next phase.
- Pause for my review after every stage (PRD, TRD, contracts, each phase's backend, each phase's UI). Record the stage in the handoff so the next session resumes there.
- Default full-stack stack: pnpm monorepo with apps/web (Next.js, React, TypeScript) and apps/api (FastAPI, Python, uv), docs/ as the wiki. Ask only when the requirements clearly need something else.
