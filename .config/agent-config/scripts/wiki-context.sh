#!/bin/sh
# SessionStart hook: give a new session the project's wiki state, the free
# replacement for a memory plugin. Prints the current handoff and the decision
# index when the repo has them; prints nothing otherwise. Reads files only.
# Capped so the injected context stays small.
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=$(pwd)
docs="$root/docs"
[ -d "$docs" ] || exit 0

show() { # file, max lines, label
    [ -f "$1" ] || return 0
    printf '\n## %s (%s)\n' "$3" "${1#"$root"/}"
    head -n "$2" "$1"
    [ "$(wc -l < "$1")" -gt "$2" ] && printf '... (truncated; read the file for the rest)\n'
    return 0
}

out=$(
    show "$docs/handoff/current.md" 60 "Current handoff"
    if [ -f "$docs/decisions/INDEX.md" ]; then
        show "$docs/decisions/INDEX.md" 40 "Decision index"
    else
        show "$docs/DECISIONS.md" 40 "Decisions"
    fi
)
[ -n "$out" ] || exit 0
printf '# Project wiki (loaded at session start; see the wiki skill)\n%s\n' "$out"
