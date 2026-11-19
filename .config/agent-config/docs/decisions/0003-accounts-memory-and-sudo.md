# 0003: Two Claude accounts, shared memory, agent commits and sudo

Accepted 2026-11-19. Items 5 and 6 superseded by [0004](0004-wiki-is-the-memory.md): claude-mem removed, the wiki is the memory.

**Context.** Two Claude Pro accounts and one ChatGPT Plus account. Both Claude accounts must share one configuration and one memory, and Codex should share that memory too. The user wants agents to work without approval gates.

**Decisions.**

1. **Agents commit and push** finished, verified work without asking (`instructions/common.md`). Deployments, paid services and messages to people still need the user.
2. **Passwordless sudo** for the user via a sudoers drop-in installed by `install.sh`, next to the existing powerboost rule.
3. **Two Claude accounts, one config.**
   - `cc` runs `claude` with the default `~/.claude`.
   - `cc1` runs `CLAUDE_CONFIG_DIR=~/.claude-alt claude`.
   - `deploy.py` applies the same settings, instructions, skills, agents and plugins to every Claude home listed in its config.
   - Each home keeps its own login.
4. **Shared session history.** `~/.claude-alt/projects` links to `~/.claude/projects`, so `/resume`, transcripts and Claude auto-memory are shared between accounts. This must be verified before rollout.
5. **claude-mem as cross-agent memory.**
   - Installed for both Claude homes and Codex, with one store at `~/.claude-mem` and startup context drawn from all agents (`CLAUDE_MEM_SESSION_START_INCLUDE_ALL_SOURCES=true`).
   - Telemetry off.
   - Portable settings live in dotfiles; the store and any API keys never do, because they contain session content and the repo is public.
   - The observer provider follows the agent (`CLAUDE_MEM_PROVIDER_BY_SOURCE` = codex→codex, claude→claude): Codex sessions summarise with the ChatGPT plan, Claude sessions with the Claude plan. `cc` and `cc1` share one worker, so Claude summaries bill whichever Claude login the worker reads. The `host` provider was rejected: it needs a self-run OpenAI-compatible observer.
6. **Division of memory.**
   - claude-mem holds automatic recall of what happened.
   - Each project's `docs/` wiki holds decisions and current state.
   - `instructions/common.md` holds cross-project preferences.
   - When they disagree, the wiki wins.

**Consequences.** claude-mem adds hooks on every tool call, a local Bun worker and a SQLite store. If it slows sessions or burns quota, disable it with its env switches and fall back to the wiki alone.
