# Third-party skill sources

Every third-party file or folder under `skills/`, where it came from and what changed. Update an upstream copy by replacing it wholesale from the recorded source, then update its row. Checked 2026-11-19.

## impeccable

| | |
|---|---|
| Path | `impeccable/` |
| Upstream | https://github.com/pbakaus/impeccable, path `.agents/skills/impeccable` |
| Revision | commit `f492a1af25a89bd6b957d535b44ab2be0d483a29` (skill 4.9.1 metadata, engine `scripts/VERSION` 0.1.24); folder tree `fe639b0caf362c40fc069a0675c1bc15e53e4fa4`, the `skillFolderHash` in `~/.agents/.skill-lock.json` |
| Licence | Apache-2.0 (`impeccable/LICENSE`); upstream third-party notices in `impeccable/NOTICE.md` (its `ios.md`/`android.md` derive from ehmo/platform-design-skills, MIT) |
| Modifications | One: `agents/openai.yaml` gains `policy: allow_implicit_invocation: false` (2026-11-19, decision 0006) so Codex does not pick impeccable on its own; re-add it after replacing the folder from upstream. Added `LICENSE` and `NOTICE.md` from the upstream repo root at the same time. `scripts/impeccable.cmd` is stored with CRLF line endings as installed (upstream blob differs only by line ending). No engine binaries or caches: the `scripts/impeccable` launcher downloads the checksum-verified engine on first run into its cache. |

### How impeccable is reached

`ui` is the only intended entry point. Its SKILL.md locates impeccable as the sibling folder (`<ui-dir>/../impeccable`, falling back to `.agents/skills/impeccable` or `~/.agents/skills/impeccable`), reads impeccable's SKILL.md and follows it with impeccable's folder as the base directory. Projects that copy `ui` must also copy `impeccable` (`npx skills add guru-krithick/dotfiles --skill ui --skill impeccable --copy`).

Impeccable's SKILL.md frontmatter is unchanged, so its description would otherwise load as a second UI skill. It is hidden from implicit invocation in both clients:

- Claude Code: `"skillOverrides": {"impeccable": "user-invocable-only"}` in `config/claude.json`, merged into every Claude home. The model does not see it; `/impeccable` still works, and ui reads its files directly.
- Codex: `policy.allow_implicit_invocation: false` in `impeccable/agents/openai.yaml` (the one local change above). `$impeccable` still works explicitly.

## brainstorming

| | |
|---|---|
| Path | `brainstorming/` |
| Upstream | https://github.com/obra/superpowers, path `skills/brainstorming` |
| Revision | commit `22f0b463e7a5e579904dd6211a520321035526f7` |
| Licence | MIT (`brainstorming/LICENSE`, copied from the repo root) |
| Modifications | `SKILL.md`: description rewritten to stop over-triggering and to point to debug, grilling and project-flow; the three `superpowers:writing-plans` handoffs now go to a new "After Approval" section (feed project-flow's current stage, otherwise a short build plan and the `builder`/`reviewer` agents); design docs go to `docs/specs/` instead of `docs/superpowers/specs/`, with an offer of `wiki decide`; attribution line added. `visual-companion.md`: script paths resolve from the skill folder. `scripts/server.cjs`: telemetry forced off, so pages never load the remote primeradiant.com logo, and the version string is fixed instead of read from `../../../package.json`. `builder-check-prompt.md` and the other scripts are unchanged. Added `agents/openai.yaml`. Decision 0007. |

## find-skills

| | |
|---|---|
| Path | `find-skills/` |
| Upstream | https://github.com/vercel-labs/skills, path `skills/find-skills` |
| Revision | folder tree `76a98a285cb0434f3d39e1a873823556330e398b` as installed 2026-10-29 (the `skillFolderHash` in `~/.agents/.skill-lock.json`; first committed here in `f3f3078`) |
| Licence | MIT (vercel-labs/skills); no LICENSE file in the skill folder |
| Modifications | Step 6 install command drops `-y` (keep the confirmation prompt) and first reviews the skill's files before installing (`bf96898`). |

## ui add-ons

| Path | Upstream | Revision | Licence | Modifications |
|---|---|---|---|---|
| `ui/references/design-data/scripts/` (`search.py`, `core.py`, `design_system.py`, `reasoning_contract.py`, `preview.py`) | https://github.com/nextlevelbuilder/ui-ux-pro-max-skill, `.claude/skills/ui-ux-pro-max/scripts` | commit `e59ff376a41f7ca47b7541ad5c116495cbade3ee` (folder tree `b6f08c13f95a4854694f41113e0b4935c741deb1`) | MIT, `ui/references/design-data/LICENSE` | Files unchanged. Upstream SKILL.md invoked them as `${CLAUDE_PLUGIN_ROOT}/.claude/skills/ui-ux-pro-max/scripts/search.py`; `ui/references/design-data.md` uses the skill-relative path with `python3 -I -B`. Dropped `tests/`, `validate_data.py`, `__pycache__/`. |
| `ui/references/design-data/data/` (`*.csv`, `stacks/*.csv`) | same repo, `.claude/skills/ui-ux-pro-max/data` | same | MIT | CSVs unchanged. Dropped maintenance-only files the search never reads: `phosphor-icons-upstream.json`, `google-font-licenses.json`, `data-provenance.json`, `catalog-summary.json`. |
| `ui/references/design-data.md` | same repo, `SKILL.md` (usage sections) | same | MIT | Rewritten usage guide. Dropped the 10-category rule table, `references/quick-reference.md`, `references/pro-rules.md` (impeccable covers them) and the `design-system/MASTER.md` persistence workflow. |
| `ui/references/motion-details.md` | https://github.com/emilkowalski/skills, `skills/emil-design-eng/SKILL.md` | commit `0f2e23b32bb1265e84cff8d3e75785fec953fb1b` (folder tree `8086a08e5ebde316c4b9226764f1f2196e1869fa`) | MIT | Condensed to the details impeccable's `animate.md` lacks; dropped persona, review-format rules, Sonner essay, code samples. |
| (same file) | Motion AI kit `motion` skill (`best-practices/`), https://github.com/motiondivision/ai-kit `plugins/motion/skills/motion`; copy read from klyz `.agents/skills/motion` (2026-11-03) | ai-kit HEAD `1e424943582cbbdb6e3f410687e39f96451447bb` at check time | None published (no LICENSE file or package licence) | API facts restated in new wording; no text copied. Motion+/MCP tiers dropped. |
| `ui/references/quick-diagnostic.md` | https://github.com/wondelai/skills, `refactoring-ui/SKILL.md` (Quick Diagnostic, Scoring) | commit `c5265583b1a9740f06831e1d3e89b35bba3eb430` (folder tree `55e561c9693156491e53bd93c5392188ba310a5d`) | MIT | 8-row rubric and score bands only, lightly reworded; affiliate "Further Reading" links and the rest of the skill dropped. |
| `ui/references/web-checklist.md` | https://github.com/vercel-labs/web-interface-guidelines, `command.md` (fetched at runtime by vercel-labs/agent-skills `web-design-guidelines`, as vendored in klyz) | commit `434b7f91364665f2f733b310ec54809bf8f37937` | MIT | Condensed into an offline final checklist; no runtime fetch; anti-pattern list folded into the sections; Title Case rule dropped in favour of project conventions. |

MIT copyright lines for all of the above are reproduced in `ui/NOTICE.md`.
