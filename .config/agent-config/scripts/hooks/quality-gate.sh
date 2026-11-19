#!/bin/sh
# Stop hook: run the project's check on changed code; block with the output tail on failure.
# Configured by the repo's .agents/flow.json; logic and schema are in flow_hooks.py.
# Fails open: no python3, no flow.json or any error exits 0.
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 -I "$(dirname "$0")/flow_hooks.py" quality-gate
