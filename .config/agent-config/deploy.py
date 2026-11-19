#!/usr/bin/env python3
"""Portable, selective deployment of Claude Code and Codex preferences."""
import argparse
import base64
import copy
from datetime import datetime
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import tomllib

SOURCE = Path(__file__).resolve().parent
CLAUDE_PREFS = ("attribution", "model", "modelSettings", "theme", "effortLevel", "outputStyle", "editorMode", "alwaysThinkingEnabled")
CAPS = {"max_threads", "max_concurrent_threads_per_session"}


def json_text(value):
    return json.dumps(value, indent=2, ensure_ascii=False) + "\n"


def toml_value(value):
    if isinstance(value, (str, bool, int, float, list)):
        return json.dumps(value, ensure_ascii=False)
    raise ValueError(f"Unsupported portable TOML value: {type(value).__name__}")


def portable_toml(data):
    lines = []
    for key, value in data.items():
        if not isinstance(value, dict):
            lines.append(f"{key} = {toml_value(value)}\n")
    for section, values in data.items():
        if isinstance(values, dict):
            lines.append(f"\n[{section}]\n")
            for key, value in values.items():
                lines.append(f"{key} = {toml_value(value)}\n")
    return "".join(lines)


def merge_codex(source, desired):
    """Preserve unrelated TOML, including local project trust and provider settings."""
    before = tomllib.loads(source)
    sections = {key: value for key, value in desired.items() if isinstance(value, dict)}
    roots = {key: value for key, value in desired.items() if not isinstance(value, dict)}
    if any(re.match(r"^\s*(?:tui|agents)\s*[.=]", line) for line in source.splitlines()):
        raise ValueError("Inline/dotted tui or agents settings need a manual merge.")
    lines = source.splitlines(keepends=True)
    out, seen = [], set()
    written = {section: set() for section in sections}
    table = ""

    def finish(section):
        if section in sections:
            for key, value in sections[section].items():
                if key not in written[section]:
                    out.append(f"{key} = {toml_value(value)}\n")
                    written[section].add(key)

    i = 0
    while i < len(lines):
        line = lines[i]
        section = re.fullmatch(r"\s*\[([^\[\]]+)\]\s*(?:#.*)?", line.rstrip())
        if line.lstrip().startswith("["):
            finish(table)
            table = section.group(1).strip() if section else "<array-table>"
            seen.add(table)
        assignment = re.match(r"^\s*([A-Za-z0-9_-]+)\s*=", line)
        key = assignment.group(1) if assignment else None
        replace = (table == "" and key in roots) or (table in sections and key in sections[table])
        remove = table == "agents" and key in CAPS
        if replace or remove:
            value = line.split("=", 1)[1]
            while True:
                try:
                    tomllib.loads("value = " + value)
                    break
                except tomllib.TOMLDecodeError:
                    i += 1
                    if i >= len(lines):
                        raise ValueError(f"Could not safely replace {table}.{key}")
                    value += lines[i]
            if replace and table:
                out.append(f"{key} = {toml_value(sections[table][key])}\n")
                written[table].add(key)
        else:
            out.append(line)
        i += 1
    if out and not out[-1].endswith("\n"):
        out[-1] += "\n"
    finish(table)
    for section in sections:
        if section not in seen:
            out.append(f"\n[{section}]\n")
            finish(section)
    candidate = "".join(f"{key} = {toml_value(value)}\n" for key, value in roots.items()) + "".join(out)
    expected = copy.deepcopy(before)
    expected.update(roots)
    for section, values in sections.items():
        expected[section] = {**before.get(section, {}), **values}
    for key in CAPS:
        expected.get("agents", {}).pop(key, None)
    if tomllib.loads(candidate) != expected:
        raise ValueError("Codex preservation check failed; no settings changed.")
    return candidate


def merge_claude(current, desired):
    """Deploy owns the keys it ships (inside permissions, only the keys it ships) and owned hooks in every event."""
    result = copy.deepcopy(current)
    for key, value in desired.items():
        if key == "hooks":
            hooks = {}
            for event, groups in result.get("hooks", {}).items():
                hooks[event] = []
                for group in groups:
                    handlers = [handler for handler in group.get("hooks", []) if not owned_hook(handler)]
                    if handlers:
                        hooks[event].append({**group, "hooks": handlers})
            for event, entries in value.items():
                hooks[event] = hooks.get(event, []) + copy.deepcopy(entries)
            result[key] = {event: groups for event, groups in hooks.items() if groups}
        elif key == "permissions":
            result[key] = {**result.get(key, {}), **copy.deepcopy(value)}
        elif key == "modelSettings":
            result[key] = copy.deepcopy(result.get(key, {}))
            for model, settings in value.items():
                result[key][model] = {**result[key].get(model, {}), **settings}
        else:
            result[key] = copy.deepcopy(value)
    return result


def owned_hook(handler):
    """Hooks that run something under agent-config/ belong to deploy, as does the legacy agent-setup notifier."""
    command = handler.get("command", "")
    return ("/agent-config/" in command or
            (command.startswith("python3 ") and command.endswith("/.config/agent-setup/scripts/notify.py")))


def claude_agent(path):
    """Return a Claude subagent file after checking that its frontmatter names it like the file."""
    front = re.match(r"---\n(.*?)\n---(?:\n|$)", path.read_text(), re.S)
    name = front and re.search(r"^name:\s*[\"']?([\w-]+)", front.group(1), re.M)
    if not name or name.group(1) != path.stem or not re.search(r"^description:\s*\S", front.group(1), re.M):
        raise ValueError(f"Invalid agent definition: {path.name}")
    return path


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=".agent-config-", dir=path.parent)
    try:
        with os.fdopen(fd, "w") as stream:
            stream.write(content)
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def same_tree(left, right):
    def inventory(root):
        result = {}
        for path in root.rglob("*"):
            relative = path.relative_to(root)
            if "__pycache__" in relative.parts:
                continue
            if path.is_symlink():
                result[str(relative)] = ("link", os.readlink(path))
            elif path.is_file():
                result[str(relative)] = ("file", hashlib.sha256(path.read_bytes()).hexdigest())
        return result
    return inventory(left) == inventory(right)


class Deployment:
    def __init__(self, home, source=SOURCE, only="both", use_environment=True):
        self.home, self.source, self.only = Path(home).resolve(), Path(source).resolve(), only
        env = os.environ if use_environment else {}
        self.config_root = Path(env.get("XDG_CONFIG_HOME", self.home / ".config"))
        self.data_root = Path(env.get("XDG_DATA_HOME", self.home / ".local/share"))
        self.state_root = Path(env.get("XDG_STATE_HOME", self.home / ".local/state"))
        self.codex = Path(env.get("CODEX_HOME", self.home / ".codex"))
        self.claude_homes = self.read_claude_homes(env)
        self.claude = self.claude_homes[0]
        self.lock = json.loads((self.source / "powerline.lock.json").read_text())
        self.runtime = self.data_root / "agent-config/powerline" / self.lock["version"]

    def read_claude_homes(self, env):
        """Listed Claude homes, primary first. CLAUDE_CONFIG_DIR replaces the primary unless it names a listed
        home, so an apply started inside a session of another listed home (e.g. cc1) acts as from a plain shell."""
        entries = json.loads((self.source / "config/claude-homes.json").read_text())
        if not entries or not all(isinstance(entry, str) and entry.startswith("~/") for entry in entries):
            raise ValueError('config/claude-homes.json must be a list of "~/..." paths.')
        homes = [self.home / entry[2:] for entry in entries]
        override = env.get("CLAUDE_CONFIG_DIR")
        if override and Path(override).resolve() not in [home.resolve() for home in homes]:
            homes[0] = Path(override)
        if len({home.resolve() for home in homes}) < len(homes):
            raise ValueError("Claude homes must be distinct directories.")
        return homes

    def bootstrap(self):
        entry = self.runtime / "package/dist/index.mjs"
        if entry.is_file():
            package = json.loads((self.runtime / "package/package.json").read_text())
            if package["version"] == self.lock["version"]:
                print(f"Powerline {self.lock['version']} is already installed.")
                return
        self.runtime.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix=".powerline-", dir=self.runtime.parent) as temp:
            root = Path(temp)
            archive = root / "package.tgz"
            subprocess.run(["curl", "--fail", "--silent", "--show-error", "--location", "--proto", "=https", "--connect-timeout", "10", "--max-time", "60", self.lock["url"], "--output", str(archive)], check=True)
            actual = "sha512-" + base64.b64encode(hashlib.sha512(archive.read_bytes()).digest()).decode()
            if actual != self.lock["integrity"]:
                raise ValueError("Powerline archive integrity mismatch.")
            extracted = root / "verified"
            extracted.mkdir()
            with tarfile.open(archive) as package:
                package.extractall(extracted, filter="data")
            if not (extracted / "package/dist/index.mjs").is_file():
                raise ValueError("Powerline archive is missing its entrypoint.")
            if self.runtime.exists():
                raise ValueError(f"Unexpected incomplete runtime at {self.runtime}; preserve or move it before retrying.")
            os.replace(extracted, self.runtime)
        print(f"Installed verified Powerline {self.lock['version']} outside dotfiles.")

    def plan(self):
        files, directories, links = [], [], []
        links.append((self.config_root / "agent-config", self.source))
        links.append((self.home / ".local/bin/agent-config", self.source.parents[1] / ".local/bin/agent-config"))
        personal = (self.source / "instructions/common.md").read_text()
        skills = sorted((self.source / "skills").iterdir())
        if self.only in ("both", "claude"):
            desired = json.loads((self.source / "config/claude.json").read_text())
            agents = [claude_agent(path) for path in sorted((self.source / "agents/claude").glob("*.md"))]
            for home in self.claude_homes:
                current = json.loads((home / "settings.json").read_text()) if (home / "settings.json").exists() else {}
                files.append((home / "settings.json", json_text(merge_claude(current, desired))))
                links.extend([(home / "CLAUDE.md", self.source / "instructions/common.md"), (home / "claude-powerline.json", self.source / "config/powerline.json")])
                links.extend((home / "skills" / skill.name, skill) for skill in skills)
                links.extend((home / "agents" / agent.name, agent) for agent in agents)
            if len(self.claude_homes) > 1:
                # Other homes share the primary's history, /resume and auto-memory; never link to a missing target.
                directories.append(self.claude / "projects")
                links.extend((home / "projects", self.claude / "projects") for home in self.claude_homes[1:])
        if self.only in ("both", "codex"):
            config = self.codex / "config.toml"
            desired = tomllib.loads((self.source / "config/codex.toml").read_text())
            files.append((config, merge_codex(config.read_text() if config.exists() else "", desired)))
            generated = self.data_root / "agent-config/AGENTS.md"
            files.append((generated, personal.rstrip() + "\n\n" + (self.source / "instructions/codex.md").read_text()))
            links.append((self.codex / "AGENTS.md", generated))
            for role in sorted((self.source / "agents").glob("*.toml")):
                data = tomllib.loads(role.read_text())
                if data.get("name") != role.stem or not all(data.get(k) for k in ("description", "developer_instructions")):
                    raise ValueError(f"Invalid agent definition: {role.name}")
                links.append((self.codex / "agents" / role.name, role))
            for skill in skills:
                existing = self.home / ".agents/skills" / skill.name
                target = existing if existing.exists() or existing.is_symlink() else self.codex / "skills" / skill.name
                links.append((target, skill))
        changes = []
        for path, content in files:
            if not path.is_file() or path.is_symlink() or path.read_text() != content:
                changes.append(("write", path, content))
        for path in directories:
            if not path.is_dir():
                if path.exists() or path.is_symlink():
                    raise ValueError(f"{path} must be a directory; it will not be replaced.")
                changes.append(("mkdir", path, None))
        for path, source in links:
            if not path.is_symlink() or path.resolve() != source.resolve():
                # An empty directory holds nothing to merge; apply moves it into the backup like any other.
                if path.is_dir() and not path.is_symlink() and any(path.iterdir()):
                    if not source.is_dir() or not same_tree(path, source):
                        raise ValueError(f"Existing directory {path} needs a manual merge; it will not be replaced.")
                changes.append(("link", path, source))
        return changes

    @staticmethod
    def readonly(path):
        parent = path.parent
        while not parent.exists():
            parent = parent.parent
        return bool(os.statvfs(parent).f_flag & os.ST_RDONLY)

    def apply(self):
        changes = self.plan()
        blocked = [str(path) for _, path, _ in changes if self.readonly(path)]
        if blocked:
            raise ValueError("Read-only targets; run in a normal terminal: " + ", ".join(blocked))
        if self.only in ("both", "claude"):
            if not shutil.which("node"):
                raise ValueError("Node.js is required for Powerline.")
            if not (self.runtime / "package/dist/index.mjs").is_file():
                raise ValueError("Powerline is not installed; run apply --bootstrap or bootstrap first.")
        if not changes:
            print("Agent configuration is already up to date.")
            return
        backup = self.state_root / "agent-config/backups" / datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        backup.mkdir(parents=True, mode=0o700)
        manifest = []
        for index, (kind, path, value) in enumerate(changes):
            record = {"path": str(path), "operation": kind, "existed": path.exists() or path.is_symlink()}
            if record["existed"]:
                saved = backup / str(index)
                if path.is_symlink():
                    record["previous_link"] = os.readlink(path)
                elif path.is_dir():
                    record["backup"] = saved.name
                    record["directory"] = True
                else:
                    shutil.copy2(path, saved)
                    os.chmod(saved, 0o600)
                    record["backup"] = saved.name
            manifest.append(record)
        atomic_write(backup / "manifest.json", json_text(manifest))
        for index, (kind, path, value) in enumerate(changes):
            if kind == "write":
                atomic_write(path, value)
            elif kind == "mkdir":
                path.mkdir(mode=0o700, parents=True)
            else:
                path.parent.mkdir(parents=True, exist_ok=True)
                temporary = path.with_name(path.name + ".agent-config-link")
                if temporary.exists() or temporary.is_symlink():
                    raise ValueError(f"Temporary link already exists: {temporary}")
                temporary.symlink_to(os.path.relpath(value, path.parent), target_is_directory=value.is_dir())
                if path.is_dir() and not path.is_symlink():
                    shutil.move(str(path), str(backup / str(index)))
                os.replace(temporary, path)
            print(f"{kind}: {path}")
        print(f"Backup: {backup}")
        print("No personal worker cap configured. Restart the affected clients to load instructions and roles.")

    def capture(self):
        """Capture only known portable preferences; never copy whole runtime files."""
        if self.only in ("both", "claude"):
            live = json.loads((self.claude / "settings.json").read_text())
            path = self.source / "config/claude.json"
            desired = json.loads(path.read_text())
            for key in CLAUDE_PREFS:
                if key in live:
                    desired[key] = live[key]
            atomic_write(path, json_text(desired))
            print("Captured Claude model and interface preferences; hooks and portable paths retained.")
        if self.only in ("both", "codex"):
            live = tomllib.loads((self.codex / "config.toml").read_text())
            path = self.source / "config/codex.toml"
            desired = tomllib.loads(path.read_text())
            for key in ("model", "model_reasoning_effort"):
                if key in live:
                    desired[key] = live[key]
            for key in ("status_line", "terminal_title", "notifications", "notification_method", "notification_condition", "theme", "animations", "vim_mode_default"):
                if key in live.get("tui", {}):
                    desired["tui"][key] = live["tui"][key]
            atomic_write(path, portable_toml(desired))
            print("Captured Codex model and display preferences; local trust, providers and credentials excluded.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", nargs="?", choices=("plan", "apply", "check", "bootstrap", "capture"), default="plan")
    parser.add_argument("--home", type=Path, help="Alternate home for a migration preview or isolated validation; ignores environment-specific config roots")
    parser.add_argument("--only", choices=("both", "claude", "codex"), default="both")
    parser.add_argument("--bootstrap", action="store_true", help="Download the pinned Powerline package before applying")
    args = parser.parse_args()
    deployment = Deployment(args.home or Path.home(), only=args.only, use_environment=args.home is None)
    if args.command == "bootstrap" or (args.command == "apply" and args.bootstrap):
        deployment.bootstrap()
    if args.command == "apply":
        deployment.apply()
    elif args.command == "capture":
        deployment.capture()
    elif args.command in ("plan", "check"):
        changes = deployment.plan()
        for kind, path, _ in changes:
            print(f"{kind}{' (read-only here)' if deployment.readonly(path) else ''}: {path}")
        if not changes:
            print("Agent configuration is up to date.")
        if args.command == "check":
            return int(bool(changes))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"Agent setup stopped: {error}", file=sys.stderr)
        raise SystemExit(1)
