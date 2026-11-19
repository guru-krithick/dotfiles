# 0002: Full autonomy, all skills committed in dotfiles

Accepted 2026-11-19. Supersedes the guardrail items and the distribution mechanism of [0001](0001-harness-architecture.md); its UI-base and parity decisions stand.

**Context.** Goal: on a new machine, `git clone` + `./install.sh` + logins leaves the agent setup ready. The dotfiles repo is public and that is fine. The user does not want guardrails and prefers maximum agent autonomy.

**Decisions.**

1. **No guardrails.** No permission deny/ask rules, no bash-guard hook, no sandbox. Claude defaults to `bypassPermissions`; Codex runs with no approvals and full access. Verification hooks (formatter, Stop-time typecheck/tests) are quality tools, not guardrails, and stay optional per project.
2. **Every skill lives in the dotfiles repo.** Own skills and the kept third-party skills (impeccable, plus add-ons extracted from the other design skills) are committed under `agent-config/skills/` with upstream attribution and license notes. No install-time downloads for skills.
3. **Projects install from the public repo.** A project copies the skills it needs with `npx skills add guru-krithick/dotfiles --skill <name> --copy`, which records a pinned hash in the project's `skills-lock.json`. This replaces the planned custom `vendor`/`doctor` commands.
4. **`deploy.py` stays the merge tool.** It remains the only custom piece: it merges portable settings into `~/.claude/settings.json` and `~/.codex/config.toml` and links skills, agents and instructions.

**Consequences.** `deploy.py` learns to carry `permissions.defaultMode`, all hooks that point into `agent-config`, and `~/.claude/agents`. `install.sh` gains plugin installs and login reminders. Design skills in `~/.agents/skills` are removed after extraction.
