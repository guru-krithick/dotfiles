#!/bin/sh
set -eu
agent_data="${XDG_DATA_HOME:-$HOME/.local/share}/agent-config"
agent_config="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
exec node "$agent_data/powerline/1.32.8/package/dist/index.mjs" \
    --config="$agent_config/claude-powerline.json"
