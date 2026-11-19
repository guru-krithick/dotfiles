---
name: kickoff
description: Start a new product build at stage 0 (scaffold) or resume an existing one at its current stage, using the project-flow stages. Invoke explicitly with /kickoff.
argument-hint: "[product idea]"
disable-model-invocation: true
---

Call the Skill tool with "project-flow" (in Codex, read the `project-flow` skill), then follow it from the right stage:

- **New or empty project** (no `AGENTS.md`, `apps/` or `docs/README.md`): start at stage 0. If no product idea was given, ask for one in a sentence or two first.
- **Existing project**: detect the current stage as project-flow describes, tell the user in one line, and continue that stage, or ask for the pending approval if the handoff says `Gate: awaiting approval`.

Product idea or notes from the user: $ARGUMENTS
