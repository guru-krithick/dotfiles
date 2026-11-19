#!/usr/bin/env python3
"""Generic local desktop notifications for Claude hooks and Codex completion."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


def notification(data):
    event = data.get("hook_event_name", data.get("type", ""))
    if event == "Stop" and data.get("stop_hook_active"):
        return None
    if event in ("Stop", "agent-turn-complete"):
        agent = "Codex" if event == "agent-turn-complete" else "Claude Code"
        title = f"{agent}: ready"
        body = "Finished the current response."
    elif event == "Notification":
        kind = data.get("notification_type", "")
        if kind not in ("permission_prompt", "idle_prompt"):
            return None
        title = "Claude Code: input needed"
        body = "Review the terminal to continue."
    else:
        return None
    project = Path(str(data.get("cwd", ""))).name
    return title, f"{project} — {body}" if project else body


def main():
    try:
        payload = sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read(1048576)
        data = json.loads(payload or "{}")
        if not isinstance(data, dict):
            return 0
        result = notification(data)
        if result is None:
            return 0
        title, body = result
        if os.environ.get("AGENT_NOTIFY_DRY_RUN") == "1":
            print(json.dumps({"title": title, "body": body}))
            return 0
        binary = shutil.which("notify-send")
        if binary is None:
            return 0
        identity = str(data.get("session_id", data.get("thread-id", data.get("cwd", ""))))
        cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "agent-setup"
        cache.mkdir(mode=0o700, parents=True, exist_ok=True)
        stamp = cache / (hashlib.sha256((identity + title).encode()).hexdigest() + ".stamp")
        if stamp.exists() and time.time() - stamp.stat().st_mtime < 8:
            return 0
        completed = subprocess.run(
            [binary, "--app-name=Agent tools", "--urgency=normal", "--expire-time=6000", title, body],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            timeout=3, check=False,
        )
        if completed.returncode == 0:
            stamp.touch(mode=0o600)
    except (OSError, ValueError, TypeError, subprocess.SubprocessError):
        # A notification must not interrupt an agent's work.
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
