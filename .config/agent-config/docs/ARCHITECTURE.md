# Agent harness architecture

How Claude Code and Codex are set up across all projects. Decisions and their reasons are in [decisions/](decisions/); remaining build work is in [TODO.md](TODO.md).

Work mix: about 70% full-stack web apps (Next.js/React + FastAPI/Python in pnpm/uv monorepos, e.g. klyz), about 30% Linux config, systems and learning projects.

## Design principles (from the agent's side)

1. **One skill per job, with descriptions that don't overlap.** Competing descriptions ("design or polish a UI" five times) make the agent pick inconsistently. Target: 10–12 skills visible to the model in any session.
2. **Router SKILL.md plus references.** A short entry file says which reference to read; large monoliths are split up.
3. **Full autonomy, verified by checks.** No guardrails: Claude runs in `bypassPermissions`, Codex with no approvals ([0002](decisions/0002-autonomy-and-committed-skills.md)). Quality comes from checks: one command the agent can run, and optionally a Stop hook that runs the fast subset.
4. **Knowledge in predictable places.** Every project has the same wiki layout, so decisions persist and are not re-argued.
5. **Protect the main context.** Browser and screenshot checks, broad exploration and review run in subagents that return findings.
6. **Zero extra cost.** Local tools, CLIs and existing subscriptions only. No paid MCP, no cloud browser, no paid design services. Watch token cost: every visible skill description loads every session.
7. **Claude/Codex parity.** `.agents/skills` and `AGENTS.md` are canonical. Claude-only features (hooks, subagents) get Codex equivalents where possible.

## Layers

```
dotfiles/.config/agent-config/      the one canonical source, in git
├── global/      → ~/.claude, ~/.codex     every project, every session
│   ├── instructions/common.md           working rules
│   ├── autonomy                          bypassPermissions / no approvals
│   ├── skills: grilling, wiki, debug, ship, web-ui-review
│   └── agents: reviewer, builder (Opus), quick-worker (Sonnet), ui-checker
├── packs/       → copied into a project on request
│   ├── web-ui/       ui (impeccable core + add-ons), shadcn, react-best-practices, agent-browser
│   ├── python-api/   FastAPI/uv conventions, pytest patterns
│   └── systems/      Linux/dotfiles/C/Rust
└── templates/project/   docs/README.md, decisions/, handoff/, TODO.md, AGENTS.md, harness:check

project/
├── .agents/skills/   vendored packs + project skills (e.g. klyz-feature, klyz-api)
├── .claude/skills/   relative links to .agents/skills
└── docs/             the project wiki
```

Distribution ([0002](decisions/0002-autonomy-and-committed-skills.md)): every skill, own and third-party, is committed in this repo with attribution. `install.sh` → `deploy.py` links the global ones. Projects copy what they need with `npx skills add guru-krithick/dotfiles --skill <name> --copy`, which pins a hash in the project's `skills-lock.json`. Upstream skills are updated deliberately by replacing the committed copy.

## The `ui` skill

The only model-invocable UI skill. Impeccable upstream (4.9.x) is vendored **unchanged** so it keeps taking updates. A thin `ui` router sends work to impeccable's commands and reads these add-on references:

| Add-on | Taken from | Used when |
|---|---|---|
| `image-first.md` (deferred) | ui-taste (Uizze, Apache-2.0, keep attribution) | Later: new screens start from a mockup image. Until then, build from a supplied image or the project's existing system |
| `design-data` + fixed search script | ui-ux-pro-max | Impeccable `init` / `colorize` / `typeset`: palette, font and style lookup |
| `motion-details.md` | emil-design-eng, merged with the project `motion` skill | `animate`, press/hover states, popovers, easing and duration |
| `quick-diagnostic.md` | refactoring-ui (8-row rubric) | `critique` scoring |
| `marketing-assets` (optional) | design-taste-frontend photo library and copy-lint only | Marketing/landing pages only |
| final web checklist | web-design-guidelines | Last pass before declaring UI done |

Dropped: the Uizze paid-MCP upsell, ui-taste's outdated impeccable 4.6 copy, ui-ux-pro-max's `design-system/MASTER.md` workflow, refactoring-ui's affiliate links, the taste-skill house rules, 40 MB of assets and its blocking Stop hook. The other design skills are uninstalled globally.

### Image generation (deferred 2026-11-19)

Out of scope for now. When revisited: Codex CLI 0.170 has `image_generation` as a stable feature and already produces `~/.codex/generated_images/<session>/exec-*.png` from `codex exec` runs, so a wrapper that copies output into the project is the likely route, with an HTML-mockup-plus-screenshot fallback.

## Full-stack loop

| Phase | Mechanism | Enforced by |
|---|---|---|
| Idea / spec | `grilling` ends by writing `SPEC.md` and decision drafts | user approval |
| Plan | plan mode for single PRs; SPEC.md for features | — |
| Build | project feature/API skills; `builder` / `quick-worker` subagents; `ui` for screens | — |
| Verify | project check command; `ui-checker` subagent drives agent-browser and returns findings | optional Stop hook: typecheck + affected tests |
| Debug | `debug` skill: reproduce → isolate → fix → regression test | — |
| Review | `reviewer` subagent checks diff against spec, skips style; `/code-review`, `/security-review` | — |
| Ship | `ship` skill: conventional commit, `gh pr create` | — |
| Remember | `wiki` skill: decide / handoff / lint | monthly drift check |

## Project wiki

Every project follows the klyz `docs/` layout:

- `docs/README.md`: document map and ownership.
- `docs/decisions/NNNN-title.md`: one decision per file, status proposed/accepted/superseded. Never edit an accepted decision; supersede it and link back. `docs/decisions/INDEX.md` has one line per decision.
- `docs/decisions/spec-issues.md`: unresolved conflicts between documents.
- `docs/handoff/current.md`: current state and evidence only; no TODO duplication.
- `docs/TODO.md`: the single active work list.

The `wiki` skill has three actions: `decide` (write a decision and index line), `handoff` (replaces project-handoff and per-project handoff skills), `lint` (decisions whose linked code changed since, broken links, TODOs duplicated in the handoff). Cross-project preferences go in `instructions/common.md`, not Claude auto-memory, which is per folder, machine-local and invisible to Codex.

## Tools

Use (free, local): `gh`, agent-browser, Claude in Chrome, official `typescript-lsp` and `pyright-lsp` plugins, shadcn's local MCP inside the web-ui pack, the built-in Learning output style for learning projects.

Skip: GitHub MCP (`gh` is cheaper), Context7 (rate-limited free tier; fetch docs directly), Graphify and memory/vector plugins, paid design MCPs, large agent packs.
