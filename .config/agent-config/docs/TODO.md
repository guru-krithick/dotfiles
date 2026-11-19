# Harness build plan

See [ARCHITECTURE.md](ARCHITECTURE.md) and decisions [0001](decisions/0001-harness-architecture.md), [0002](decisions/0002-autonomy-and-committed-skills.md), [0003](decisions/0003-accounts-memory-and-sudo.md).

**Goal:** a new Arch machine runs `git clone` → `./install.sh` → `claude` / `codex login` / `gh auth login`, and the full agent setup is ready. Re-running `install.sh` on this machine changes nothing unexpected.

Each step lists how it is verified. Build steps go to subagents; the main session reviews.

## Phase 0: make the source safe to commit

1. [x] `agent-config capture`, so the source says `opus`, not `fable`. Verify: `agent-config check` exits 0.
2. [x] Remove legacy references: drop `claude-hud` from `enabledPlugins` and `extraKnownMarketplaces` in live settings; point Codex `notify` at `~/.config/agent-config/scripts/notify.py`. Verify: `grep -r agent-setup ~/.claude/settings.json ~/.codex/config.toml` is empty.
3. [x] Commit `.config/agent-config/` and `.local/bin/agent-config` only (other dirty dotfiles stay untouched). Verify: a fresh clone into a temp dir contains them.

## Phase 1: make `deploy.py` carry the whole setup

4. [x] Portable autonomy: add `permissions.defaultMode: "bypassPermissions"` to `config/claude.json` (plus the key that skips the startup confirmation, name to be confirmed in the settings reference); Codex `approval_policy = "never"`, `sandbox_mode = "danger-full-access"` in `config/codex.toml`. Extend `merge_claude` to own `permissions.defaultMode`.
5. [x] Hooks: generalise `owned_notification` so `deploy.py` owns any hook whose command points into `agent-config/`, not only `notify.py`. Verify: unit test that a second `apply` does not duplicate hooks and keeps foreign hooks.
6. [x] Claude agents: add `agents/claude/*.md` and link them into `~/.claude/agents/`. Codex roles stay in `agents/*.toml`. Verify: `plan` lists the links; unit test.
7. [x] Fix the Codex re-apply drift (worker cap, legacy `AGENTS.md`). Verify: `agent-config check` exits 0 after `apply`.
8. [x] Tests: extend `tests/test_deploy.py` for 4–7 with an isolated `--home`. Verify: `python3 -m unittest discover -s tests` passes.

## Phase 2: skills and agents (all committed)

9. [x] Global workflow skills in `skills/`:
   - `wiki` (decide / handoff / lint); replaces `project-handoff`.
   - `debug` (reproduce → isolate → fix → regression test), adapted from Superpowers' systematic-debugging (MIT, attributed).
   - `ship` (conventional commit, `gh pr create`; user-invoked only).
   - `grilling`: end by offering `SPEC.md` and decision drafts.
   - `find-skills`: drop `-y`; keep one copy only.
10. [x] UI: commit impeccable (pinned upstream revision, LICENSE/NOTICE fetched from upstream) plus the `ui` router with add-on references extracted from ui-ux-pro-max (data + search script with fixed path), emil-design-eng (motion details), refactoring-ui (MIT, quick diagnostic) and web-design-guidelines (final checklist). Record source, revision and license per add-on in `skills/SOURCES.md`. Image-first stays deferred.
11. [x] Claude agents in `agents/claude/`: `reviewer` (read-only, checks diff against spec, skips style), `builder` (Opus, max effort), `quick-worker` (Sonnet), `ui-checker` (drives agent-browser, returns findings, not screenshots). Matching Codex roles where useful.
12. [x] Move the delegation preference from auto-memory into `instructions/common.md`.
13. [x] Remove `~/.agents/skills/{design-taste-frontend,emil-design-eng,refactoring-ui,ui-ux-pro-max}` and the duplicate `find-skills`. Verify: `/skill-doctor` shows no overlapping UI skills.

## Phase 3: `install.sh` and README

14. Add packages the harness uses to `PACMAN_PACKAGES` (e.g. `shellcheck`; anything a skill script needs). Drop `@juliusbrussee/caveman-code` from `NPM_GLOBALS` if unused. Add a passwordless sudoers drop-in for the user (`/etc/sudoers.d/agent-nopasswd`, checked with `visudo -cf`), like the powerboost rule.
15. After `configure_agents`: install free plugins (`typescript-lsp`, `pyright-lsp` from `claude-plugins-official`) when `claude` is logged in; otherwise print the command.
16. `print_next_steps`: list `claude` login, `codex login`, `gh auth login`.
17. Update README's agent section (autonomy, skill list, how projects install skills).
18. Verify end to end: `./install.sh` re-run on this machine is a no-op for agent config; `deploy.py apply --home <tmp>` from a fresh clone produces a working tree (settings, skills, agents, instructions).

## Phase 4: roll out to projects

19. klyz: replace `ui-taste`, `motion`, `klyz-handoff` with `ui` and `wiki` via `npx skills add guru-krithick/dotfiles --skill … --copy`; update `docs/SKILLS.md` and the manifest; run `pnpm harness:check`. Then LUPI and reckon.
20. Add `docs/decisions/INDEX.md` to each project wiki.
21. Optional per project: verification hooks (formatter on edit, Stop-time typecheck + affected tests) in `.claude/settings.json`.

## Phase 5: two Claude accounts and shared memory

22. [x] `deploy.py`: a list of Claude homes (`~/.claude`, `~/.claude-alt`); apply settings, instructions, skills, agents and plugins to each. Unit test with two homes.
23. [~] (link applied 2026-11-19; resume test pending) Link `~/.claude-alt/projects` → `~/.claude/projects` for shared history and auto-memory. Verify: a session started with `cc` resumes under `cc1`.
24. `.zshrc`: `cc` = `claude`; `cc1` = `CLAUDE_CONFIG_DIR=$HOME/.claude-alt claude`. `print_next_steps` lists both logins.
25. claude-mem: install from its marketplace for both Claude homes and for Codex; one store `~/.claude-mem`; `CLAUDE_MEM_SESSION_START_INCLUDE_ALL_SOURCES=true`; telemetry disabled. Observer provider follows the session (user decision 2026-11-19): `CLAUDE_MEM_PROVIDER_BY_SOURCE` maps Claude Code → `claude` and Codex → `codex`, so each harness spends its own plan. Verify which Claude account the shared worker bills (it likely inherits `CLAUDE_CONFIG_DIR` from whichever session started it); if it mixes accounts, run one worker per Claude home on fixed ports (`CLAUDE_MEM_WORKER_PORT`) with `CLAUDE_MEM_CLAUDE_CONFIG_DIR` set per alias, still sharing the store. Keep `~/.claude-mem/settings.json`'s portable keys in `config/claude-mem.json`, merged by `deploy.py`. Never commit the store or `.env`.
26. Verify claude-mem: `npx claude-mem doctor`, worker health endpoint, an observation from Codex appears in a Claude session start and vice versa.

27. Dotfiles push identity: the active `gh` account is `gurukrithick` but the repo belongs to `guru-krithick`, so pushes return 403 unless the account is switched. Fix with an SSH remote using a host alias and key for `guru-krithick`, or a per-repo token helper. Verify: `git push --dry-run` succeeds without `gh auth switch`.

## Resolved at review (2026-11-19)

- Agents commit and push finished work; `common.md` updated.
- Passwordless sudo: yes (step 14).
- Still to confirm during Phase 4: `npx skills` finds skills under `.config/agent-config/skills/` (may need `--full-depth`).
