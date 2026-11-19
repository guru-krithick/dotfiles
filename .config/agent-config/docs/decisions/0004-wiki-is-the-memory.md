# 0004: The project wiki is the only memory; claude-mem removed

Accepted 2026-11-19. Supersedes items 5 and 6 of [0003](0003-accounts-memory-and-sudo.md) (claude-mem and the division of memory); its account, history and sudo decisions stand.

**Context.** claude-mem worked, but its summaries spend Claude Pro and ChatGPT Plus limits, it runs hooks on every tool call, injects tokens at every session start and now advertises a paid hosted observer. The user decided it is not needed.

**Decisions.**

1. **claude-mem is uninstalled** from both Claude homes and Codex, with its store, caches, Codex hooks and setup script.
2. **The `docs/` wiki is the memory** shared by every session, account and agent: decisions, handoff, TODO and learned rules, in git.
3. **Reading is automatic and free.** A Claude `SessionStart` hook (`scripts/wiki-context.sh`, on startup, clear and compact) prints the current handoff and decision index, capped at 60 and 40 lines; it only reads files. Codex gets the same through the rule in `instructions/common.md`.
4. **Writing is a habit, not a plugin.** `common.md` asks agents to update the wiki before finishing substantial work. The `wiki` skill gains `learn` (a mistake or correction becomes a one-line rule in the repo's AGENTS.md), a 40-line handoff limit and respect for each repo's existing layout.
5. Cross-project preferences stay in `instructions/common.md`; Claude auto-memory stays on but is secondary.

**Consequences.** No quota is spent on memory. Recall depends on agents keeping the handoff current; `wiki lint` flags a stale or oversized handoff. klyz and reckon carry the previous `wiki` copy until they are updated with `npx skills update`.
