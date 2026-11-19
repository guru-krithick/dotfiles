# Codex coordination

- Keep implementation decisions, integration, and the final response in the main thread. Keep the display and progress updates concise.
- For substantial tasks, delegate bounded, independent investigation or review to `repo_explorer` and `change_reviewer` when that adds useful evidence. Handle small edits directly. A role's existence is not a reason to spawn it.
- Do not impose a personal maximum worker count. Choose useful parallelism for the task. Give each worker a short task name, a concrete question or review target, relevant context, and an expected result. Keep unrelated work out of its assignment.
- `repo_explorer` gathers evidence and proposes the smallest useful change. `change_reviewer` checks actual changes for correctness and regressions. Both are inspection roles; the main agent applies fixes unless the user requests a different division of work.
- Workers inherit the parent model unless the user or applicable project instructions select another one. Their instructions do not grant different filesystem or tool permissions.
- Review worker findings against the actual code before acting on them. Reuse a worker for a follow-up when appropriate, close it when its assignment is finished, and bring back a concise result with relevant file references.
