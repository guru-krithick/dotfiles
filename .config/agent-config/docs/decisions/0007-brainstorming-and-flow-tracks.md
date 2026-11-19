# 0007: Brainstorming from Superpowers; project-flow tracks

Accepted 2026-11-19. Amends [0005](0005-project-flow.md): the contract-first flow becomes the default track, not a rule. Extends [0002](0002-autonomy-and-committed-skills.md) (skills committed in dotfiles).

**Context.** The user wanted Superpowers' brainstorming. The full Superpowers plugin brings its own flow (writing-plans, subagent-driven development, a hook on every session) that competes with project-flow, grilling, debug and the builder/reviewer agents, and would reverse 0002. Separately, the user often owns only the frontend (jaggs) and takes small, low-stakes jobs where PRD, TRD and API contracts are overhead.

**Decisions.**

1. **Brainstorming only, vendored and adapted** in `skills/brainstorming/` (obra/superpowers `22f0b46`, MIT). It hands off to project-flow or a short build plan instead of `superpowers:writing-plans`, writes design docs to `docs/specs/`, and its visual companion never loads remote assets. Changes are listed in `skills/SOURCES.md`.
2. **Keep grilling.** Brainstorming works out what to build (one question at a time, approaches, design doc); grilling settles decisions in numbered rounds. project-flow uses brainstorming in stage 1 and grilling in stage 2.
3. **project-flow tracks**, recorded as a `Track:` line in the handoff: `full` (default, stages 0-5), `frontend` (no contracts or backend stages; demo data or published payloads, never invented contracts), `light` (one brief, one approval, build, one review).
4. **Any stage can be skipped on request**, recorded as `Skipped: <stage> (user, <date>)` in the handoff and not re-raised. Existing repos keep their own doc layout.
5. `instructions/common.md` "How I build" says the same.

**Consequences.** Projects that want brainstorming copy it with `npx skills add guru-krithick/dotfiles --skill brainstorming --copy`. Using the visual companion with `--project-dir` writes `.superpowers/` into the project, which should be gitignored. Other Superpowers skills are not adopted; revisit individually if wanted.

Paths: `skills/brainstorming/`, `skills/project-flow/`, `skills/SOURCES.md`, `instructions/common.md`, `docs/ARCHITECTURE.md`.
