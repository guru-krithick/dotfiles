#!/usr/bin/env python3
"""Claude Code hooks for projects built with the project-flow skill.

Run through the sibling .sh wrappers as `python3 -I flow_hooks.py <hook>`, with the
hook's JSON input on stdin. Configuration is the repo's `.agents/flow.json`:

    {
      "api_paths": ["apps/api/app"],      # API code (contract-sync)
      "contract_paths": ["docs/api"],     # the contract (contract-sync)
      "code_paths": ["apps"],             # optional; what counts as code (quality-gate)
      "check": "pnpm typecheck",          # quality-gate command, run with sh -c at the root
      "check_timeout": 300,               # seconds, optional
      "format": {                         # format-on-edit, by file extension
        ".ts,.tsx": {"command": "pnpm exec biome format --write", "cwd": "apps/web", "paths": ["apps/web"]},
        ".py": "uv run ruff format"       # a plain string runs at the repo root
      }
    }

No flow.json, no git repo, bad input or any internal error means exit 0 (fail open).
Only a deliberate block exits 2, with the reason on stderr. Standard library only.
"""
import hashlib
import json
import os
from pathlib import Path
import shlex
import signal
import subprocess
import sys

TAIL_LINES = 40


def read_input():
    """The hook's JSON object, or None when stdin is not one (then the hook does nothing)."""
    try:
        data = json.load(sys.stdin)
    except (ValueError, OSError):
        return None
    return data if isinstance(data, dict) else None


def git(root, *args):
    result = subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True,
                            stdin=subprocess.DEVNULL, timeout=30)
    return result.stdout if result.returncode == 0 else None


def repo_root(start):
    out = git(start, "rev-parse", "--show-toplevel")
    return Path(out.strip()) if out and out.strip() else None


def load_flow(root):
    try:
        flow = json.loads((root / ".agents/flow.json").read_text())
    except (OSError, ValueError):
        return None
    return flow if isinstance(flow, dict) else None


def prefixes(value):
    """A list of repo-relative path prefixes; ignores anything that is not a non-empty string."""
    if isinstance(value, str):
        value = [value]
    if not isinstance(value, list):
        return []
    cleaned = []
    for item in value:
        if isinstance(item, str):
            item = item.strip().removeprefix("./").strip("/")
            if item:
                cleaned.append(item)
    return cleaned


def under(path, roots):
    return any(path == root or path.startswith(root + "/") for root in roots)


def changed_files(root):
    """Files that differ from HEAD (staged or not) plus untracked, unignored files."""
    if git(root, "rev-parse", "--verify", "--quiet", "HEAD") is not None:
        tracked = git(root, "diff", "--name-only", "-z", "HEAD")
    else:  # no commits yet: everything in the index is new
        tracked = git(root, "ls-files", "-z")
    untracked = git(root, "ls-files", "--others", "--exclude-standard", "-z")
    names = set()
    for chunk in (tracked, untracked):
        names.update(name for name in (chunk or "").split("\0") if name)
    return sorted(names)


def state_file(root, name):
    """Per-clone hook memory inside the git dir, so it is never committed."""
    out = git(root, "rev-parse", "--git-path", f"agent-flow/{name}")
    if not out or not out.strip():
        return None
    path = Path(out.strip())
    return path if path.is_absolute() else root / path


def read_state(path):
    try:
        return path.read_text() if path else None
    except OSError:
        return None


def write_state(path, value):
    if not path:
        return
    try:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value)
    except OSError:
        pass


def head(root):
    return (git(root, "rev-parse", "--verify", "--quiet", "HEAD") or "").strip()


def project(data):
    start = data.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
    root = repo_root(start) if os.path.isdir(start) else None
    flow = load_flow(root) if root else None
    return root, flow


def contract_sync(data):
    """Stop: block once when API code changed but nothing under the contract paths did."""
    if data.get("stop_hook_active"):
        return 0
    root, flow = project(data)
    if not flow:
        return 0
    api = prefixes(flow.get("api_paths"))
    contracts = prefixes(flow.get("contract_paths", ["docs/api"]))
    if not api or not contracts:
        return 0
    changed = changed_files(root)
    api_changed = [name for name in changed if under(name, api)]
    if not api_changed or any(under(name, contracts) for name in changed):
        return 0
    # Remember what was flagged: the same set of changed API files is not flagged again
    # until HEAD moves or another API file changes, so one explanation per change is enough.
    key = hashlib.sha256("\n".join([head(root), *api_changed]).encode()).hexdigest()
    memo = state_file(root, "contract-sync")
    if read_state(memo) == key:
        return 0
    write_state(memo, key)
    shown = ", ".join(api_changed[:8]) + (f" and {len(api_changed) - 8} more" if len(api_changed) > 8 else "")
    print(f"API code changed without a contract update ({shown}): update {contracts[0]}/... first if "
          "API behaviour changed (the contract is the source of truth), or state why no contract change "
          "is needed, for example which existing contract entry this implements.", file=sys.stderr)
    return 2


def is_code(name, flow):
    code = prefixes(flow.get("code_paths"))
    if code:
        return under(name, code)
    return not under(name, ["docs"]) and not name.lower().endswith(".md")


def fingerprint(root, names):
    digest = hashlib.sha256(head(root).encode())
    for name in names:
        digest.update(b"\0" + name.encode() + b"\0")
        try:
            digest.update(hashlib.sha256((root / name).read_bytes()).digest())
        except OSError:
            digest.update(b"<missing>")
    return digest.hexdigest()


def run_check(command, root, timeout):
    """Run the check in its own process group so a timeout kills everything it started."""
    process = subprocess.Popen(["sh", "-c", command], cwd=root, stdin=subprocess.DEVNULL,
                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT, start_new_session=True)
    try:
        output, _ = process.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except OSError:
            pass
        process.communicate()
        return None, ""
    return process.returncode, output.decode(errors="replace")


def quality_gate(data):
    """Stop: run the flow.json check once per distinct state of changed code; block on failure."""
    if data.get("stop_hook_active"):
        return 0
    root, flow = project(data)
    command = flow.get("check") if flow else None
    if not isinstance(command, str) or not command.strip():
        return 0
    code = [name for name in changed_files(root) if is_code(name, flow)]
    if not code:
        return 0
    key = fingerprint(root, code)
    memo = state_file(root, "quality-gate")
    if read_state(memo) == key:
        return 0  # this exact state was already checked (and reported if it failed)
    timeout = flow.get("check_timeout", 300)
    if not isinstance(timeout, (int, float)) or timeout <= 0:
        timeout = 300
    returncode, output = run_check(command, root, timeout)
    write_state(memo, key)
    if returncode in (None, 0):  # passed, or timed out: fail open
        return 0
    tail = "\n".join(output.rstrip().splitlines()[-TAIL_LINES:])
    print(f"Quality gate failed: `{command}` exited {returncode}. Fix the failures this change caused, "
          f"or state why they are unrelated. Last {TAIL_LINES} lines:\n{tail}", file=sys.stderr)
    return 2


def format_on_edit(data):
    """PostToolUse (Edit|Write|MultiEdit): format the edited file by extension. Never blocks."""
    tool_input = data.get("tool_input") if isinstance(data.get("tool_input"), dict) else {}
    target = tool_input.get("file_path")
    if not isinstance(target, str) or not target:
        return 0
    path = Path(target)
    if not path.is_absolute():
        path = Path(data.get("cwd") or os.getcwd()) / path
    if not path.is_file():
        return 0
    root = repo_root(path.parent)
    flow = load_flow(root) if root else None
    formats = flow.get("format") if flow else None
    if not isinstance(formats, dict):
        return 0
    try:
        relative = path.resolve().relative_to(root.resolve()).as_posix()
    except ValueError:
        return 0
    suffix = path.suffix.lower()
    for extensions, spec in formats.items():
        if suffix not in [ext.strip().lower() for ext in str(extensions).split(",")]:
            continue
        spec = {"command": spec} if isinstance(spec, str) else spec
        if not isinstance(spec, dict) or not isinstance(spec.get("command"), str):
            continue
        scope = prefixes(spec.get("paths"))
        if scope and not under(relative, scope):
            continue
        cwd = root / spec.get("cwd", ".") if isinstance(spec.get("cwd", "."), str) else root
        subprocess.run([*shlex.split(spec["command"]), str(path)], cwd=cwd, stdin=subprocess.DEVNULL,
                       capture_output=True, timeout=60)
        break
    return 0


HOOKS = {"contract-sync": contract_sync, "quality-gate": quality_gate, "format-on-edit": format_on_edit}


def main():
    hook = HOOKS.get(sys.argv[1] if len(sys.argv) > 1 else "")
    data = read_input() if hook else None
    if data is None:
        return 0
    try:
        return hook(data)
    except Exception:  # fail open: a broken hook must never trap the session
        return 0


if __name__ == "__main__":
    sys.exit(main())
