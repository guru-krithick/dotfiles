# 0006: Drop the shortcut skills grill-me, kickoff and ship

Accepted 2026-11-19. Amends [0005](0005-project-flow.md): `/kickoff` no longer exists; `project-flow` itself starts stage 0. The rest of 0005 stands.

**Context.** `grill-me` and `kickoff` were one-line, user-only aliases for `grilling` and `project-flow`, which are already invocable by name (`/grilling`, `/project-flow`, `$name` in Codex). `ship` duplicated the rule in `instructions/common.md` that agents commit and push finished work. The user does not use them.

**Decisions.**

1. Remove `skills/grill-me`, `skills/kickoff` and `skills/ship`, and their links in `~/.claude/skills`, `~/.claude-alt/skills` and `~/.codex/skills` (`deploy.py` does not prune links to deleted skills).
2. Start a product build by asking for `project-flow` (it detects stage 0 in an empty repo). Open PRs by asking; agents use `gh pr create`.
3. Hide `impeccable` from implicit invocation in Codex too, via `policy.allow_implicit_invocation: false` in its `agents/openai.yaml`, matching Claude's `skillOverrides: user-invocable-only`. This is the one local change to the upstream copy; see `skills/SOURCES.md`.

**Consequences.** Eight global skills remain: debug, find-skills, grilling, impeccable, project-flow, ui, web-ui-review, wiki. Project copies of `impeccable` (klyz, reckon) keep the upstream `openai.yaml` until refreshed; that only matters for Codex in those repos.

Paths: `skills/`, `skills/SOURCES.md`, `skills/project-flow/SKILL.md`, `docs/ARCHITECTURE.md`.
