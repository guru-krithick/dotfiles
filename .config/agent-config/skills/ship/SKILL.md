---
name: ship
description: Finish and ship the current work - run the repo's checks, make a conventional commit, push, and open a PR when on a non-default branch. Invoke explicitly with /ship.
disable-model-invocation: true
---

1. Find the repo's checks (AGENTS.md/CLAUDE.md, package scripts, Makefile, CI config) and run them. Fix failures that come from this work; stop and report ones that do not.
2. Review `git status` and `git diff`; stage only this work's files.
3. Commit with a conventional message (`type(scope): summary`, imperative, body for the why). Follow the repo's attribution rules.
4. Push the current branch (`git push -u origin HEAD`).
5. If the branch is not the default branch, run `gh pr create` with a title matching the commit and a short body: summary and verification. On the default branch, skip the PR.
6. Report: commit hash, PR URL if any, and which checks ran with their results and which did not.
