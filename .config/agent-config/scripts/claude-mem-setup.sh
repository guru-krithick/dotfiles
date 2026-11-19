#!/usr/bin/env bash
# One shared claude-mem store (~/.claude-mem) for every Claude home and Codex.
# Claude sessions summarise with the Claude plan, Codex sessions with the
# ChatGPT plan (CLAUDE_MEM_PROVIDER_BY_SOURCE). Safe to re-run.
# See docs/decisions/0003-accounts-memory-and-sudo.md.
set -euo pipefail

readonly VERSION="16.0.0"
readonly HOMES_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/agent-config/config/claude-homes.json"
export CLAUDE_MEM_ONLINE_OPTIN=false

cm() { npx --yes "claude-mem@$VERSION" "$@"; }

# Claude Code: every home listed for agent-config (~/.claude, ~/.claude-alt).
python3 -I -c 'import json,sys,os; [print(os.path.expanduser(h)) for h in json.load(open(sys.argv[1]))]' "$HOMES_FILE" |
while read -r home; do
    mkdir -p "$home"
    CLAUDE_CONFIG_DIR="$home" cm install --ide claude-code --provider claude --runtime worker
done

# Codex CLI: native hooks; approve them once inside Codex with /hooks.
cm install --ide codex-cli --provider claude --runtime worker

python3 -I - <<'EOF'
import json, pathlib
p = pathlib.Path.home() / ".claude-mem/settings.json"
d = json.loads(p.read_text()) if p.exists() else {}
d["CLAUDE_MEM_PROVIDER"] = "claude"
d["CLAUDE_MEM_PROVIDER_BY_SOURCE"] = json.dumps({"codex": "codex", "claude": "claude"})
d["CLAUDE_MEM_SESSION_START_INCLUDE_ALL_SOURCES"] = "true"
d["CLAUDE_MEM_WELCOME_HINT_ENABLED"] = "false"
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text(json.dumps(d, indent=2) + "\n")
EOF

cm telemetry disable
"$HOME/.local/bin/claude-mem" restart || true
cm doctor
