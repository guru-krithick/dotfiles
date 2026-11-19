#!/bin/sh
# PostToolUse hook (Edit|Write|MultiEdit): format the edited file. Never blocks.
# Configured by the repo's .agents/flow.json; logic and schema are in flow_hooks.py.
# Fails open: no python3, no flow.json or any error exits 0.
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 -I "$(dirname "$0")/flow_hooks.py" format-on-edit
