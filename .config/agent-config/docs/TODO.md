# Harness build plan

See [ARCHITECTURE.md](ARCHITECTURE.md) and decisions [0001](decisions/0001-harness-architecture.md), [0002](decisions/0002-autonomy-and-committed-skills.md), [0003](decisions/0003-accounts-memory-and-sudo.md), [0004](decisions/0004-wiki-is-the-memory.md), [0005](decisions/0005-project-flow.md), [0006](decisions/0006-drop-shortcut-skills.md).

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
   - ~~`ship`~~ removed 2026-11-19 with `kickoff` and `grill-me` ([0006](decisions/0006-drop-shortcut-skills.md)).
   - `grilling`: end by offering `SPEC.md` and decision drafts.
   - `find-skills`: drop `-y`; keep one copy only.
10. [x] UI: commit impeccable (pinned upstream revision, LICENSE/NOTICE fetched from upstream) plus the `ui` router with add-on references extracted from ui-ux-pro-max (data + search script with fixed path), emil-design-eng (motion details), refactoring-ui (MIT, quick diagnostic) and web-design-guidelines (final checklist). Record source, revision and license per add-on in `skills/SOURCES.md`. Image-first stays deferred.
11. [x] Claude agents in `agents/claude/`: `reviewer` (read-only, checks diff against spec, skips style), `builder` (Opus, max effort), `quick-worker` (Sonnet), `ui-checker` (drives agent-browser, returns findings, not screenshots). Matching Codex roles where useful.
12. [x] Move the delegation preference from auto-memory into `instructions/common.md`.
13. [x] Remove `~/.agents/skills/{design-taste-frontend,emil-design-eng,refactoring-ui,ui-ux-pro-max}` and the duplicate `find-skills`. Verify: `/skill-doctor` shows no overlapping UI skills.

## Phase 3: `install.sh` and README

14. [x] (in install.sh working tree; live rule pending the user running it) Add packages the harness uses to `PACMAN_PACKAGES` (e.g. `shellcheck`; anything a skill script needs). Drop `@juliusbrussee/caveman-code` from `NPM_GLOBALS` if unused. Add a passwordless sudoers drop-in for the user (`/etc/sudoers.d/agent-nopasswd`, checked with `visudo -cf`), like the powerboost rule.
15. ~~LSP plugins~~ dropped (user, 2026-11-19).
16. ~~Login reminders in `print_next_steps`~~ dropped (user, 2026-11-19).
17. Update README's agent section (autonomy, skill list, how projects install skills).
18. Verify end to end: `./install.sh` re-run on this machine is a no-op for agent config; `deploy.py apply --home <tmp>` from a fresh clone produces a working tree (settings, skills, agents, instructions).

## Phase 4: roll out to projects

19. [x] klyz: replace `ui-taste`, `motion`, `klyz-handoff` with `ui` and `wiki` via `npx skills add guru-krithick/dotfiles --skill … --copy`; update `docs/SKILLS.md` and the manifest; run `pnpm harness:check`. reckon done 2026-11-19 (`dfec0bf` on `training-ui-redesign`, pushed; keeps its single docs/DECISIONS.md). (klyz done 2026-11-19, `5b695a7`, pushed. LUPI excluded by the user: collaborator's repo.)
20. [x] (klyz only; reckon uses docs/DECISIONS.md) Add `docs/decisions/INDEX.md` to each project wiki.
21. [x] Verification hooks built (decision 0005): `contract-sync`, `quality-gate`, `format-on-edit`, configured per project by `.agents/flow.json`. Wired into klyz (`5f5ecde`) and reckon (`94431d9`), both pushed and tested live.
28. Run a full `project-flow` stage 0 scaffold end to end once and fix anything the template misses.

## Phase 5: two Claude accounts and shared memory

22. [x] `deploy.py`: a list of Claude homes (`~/.claude`, `~/.claude-alt`); apply settings, instructions, skills, agents and plugins to each. Unit test with two homes.
23. [~] (link applied 2026-11-19; resume test pending) Link `~/.claude-alt/projects` → `~/.claude/projects` for shared history and auto-memory. Verify: a session started with `cc` resumes under `cc1`.
24. [x] `.zshrc`: `cc` = `claude`; `cc1` = `CLAUDE_CONFIG_DIR=$HOME/.claude-alt claude` (in the working tree; commit with the user's other `.zshrc` edits).
25. ~~claude-mem~~ installed, then removed the same day (decision 0004). The wiki is the memory: SessionStart hook `scripts/wiki-context.sh`, `wiki learn`, rules in `common.md`.
26. ~~Verify claude-mem~~ dropped with 0004. Instead verify: a new Claude session in klyz shows the handoff from the hook.

27. Dotfiles push identity: the active `gh` account is `gurukrithick` but the repo belongs to `guru-krithick`, so pushes return 403 unless the account is switched. Fix with an SSH remote using a host alias and key for `guru-krithick`, or a per-repo token helper. Verify: `git push --dry-run` succeeds without `gh auth switch`.

## Resolved at review (2026-11-19)

- Agents commit and push finished work; `common.md` updated.
- Passwordless sudo: yes (step 14).
- Still to confirm during Phase 4: `npx skills` finds skills under `.config/agent-config/skills/` (may need `--full-depth`).
