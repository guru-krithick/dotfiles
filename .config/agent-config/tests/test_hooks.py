"""Exercise the project-flow hooks (scripts/hooks) against disposable git repositories."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

SOURCE = Path(__file__).resolve().parents[1]
HOOKS = SOURCE / "scripts/hooks"
TEMPLATE = SOURCE / "templates/fullstack"
# Isolate git from the user's configuration (signing, hooks, identity).
GIT_ENV = {
    "GIT_CONFIG_GLOBAL": os.devnull, "GIT_CONFIG_NOSYSTEM": "1",
    "GIT_AUTHOR_NAME": "Test", "GIT_AUTHOR_EMAIL": "test@example.invalid",
    "GIT_COMMITTER_NAME": "Test", "GIT_COMMITTER_EMAIL": "test@example.invalid",
}


class HookTestCase(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="agent-hooks-")
        self.repo = Path(self.temp.name) / "project with spaces"
        self.repo.mkdir()
        self.env = {**os.environ, **GIT_ENV}
        self.env.pop("CLAUDE_PROJECT_DIR", None)
        self.git("init", "-q", "-b", "main")
        self.write("apps/api/app/main.py", "app = None\n")
        self.write("docs/api/README.md", "# Contract\n")
        self.write("README.md", "# Project\n")

    def tearDown(self):
        self.temp.cleanup()

    def git(self, *args):
        subprocess.run(["git", *args], cwd=self.repo, env=self.env, check=True, capture_output=True)

    def write(self, relative, text):
        path = self.repo / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def flow(self, **config):
        self.write(".agents/flow.json", json.dumps(config))

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "base")

    def hook(self, name, payload=None, raw=None):
        stdin = raw if raw is not None else json.dumps({"cwd": str(self.repo), **(payload or {})})
        return subprocess.run(["sh", str(HOOKS / f"{name}.sh")], cwd=self.repo, env=self.env, input=stdin,
                              capture_output=True, text=True, timeout=60)


class ContractSyncTests(HookTestCase):
    def setUp(self):
        super().setUp()
        self.flow(api_paths=["apps/api/app"], contract_paths=["docs/api"])
        self.commit()

    def test_blocks_once_then_respects_stop_hook_active_and_memory(self):
        self.write("apps/api/app/main.py", "app = 'changed'\n")
        first = self.hook("contract-sync")
        self.assertEqual(first.returncode, 2)
        self.assertIn("API code changed without a contract update", first.stderr)
        self.assertIn("apps/api/app/main.py", first.stderr)
        # The re-stop after a block carries stop_hook_active and must never block again.
        self.assertEqual(self.hook("contract-sync", {"stop_hook_active": True}).returncode, 0)
        # A later stop with the same changed API files has already been answered.
        self.assertEqual(self.hook("contract-sync").returncode, 0)
        # A newly changed API file is a new question.
        self.write("apps/api/app/routes.py", "routes = []\n")
        self.assertEqual(self.hook("contract-sync").returncode, 2)

    def test_staged_change_counts(self):
        self.write("apps/api/app/main.py", "app = 'staged'\n")
        self.git("add", "-A")
        self.assertEqual(self.hook("contract-sync").returncode, 2)

    def test_passes_when_contract_changed_too(self):
        self.write("apps/api/app/main.py", "app = 'changed'\n")
        self.write("docs/api/endpoints/phase-1-foundation.md", "## GET /health\n")
        result = self.hook("contract-sync")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_passes_when_only_other_code_changed(self):
        self.write("apps/web/page.tsx", "export {}\n")
        self.assertEqual(self.hook("contract-sync").returncode, 0)

    def test_passes_without_flow_json(self):
        (self.repo / ".agents/flow.json").unlink()
        self.git("add", "-A")
        self.git("commit", "-q", "-m", "drop flow")
        self.write("apps/api/app/main.py", "app = 'changed'\n")
        self.assertEqual(self.hook("contract-sync").returncode, 0)

    def test_fails_open_on_bad_input_and_outside_git(self):
        self.write("apps/api/app/main.py", "app = 'changed'\n")
        self.assertEqual(self.hook("contract-sync", raw="not json").returncode, 0)
        outside = Path(self.temp.name) / "plain"
        outside.mkdir()
        self.assertEqual(self.hook("contract-sync", {"cwd": str(outside)}).returncode, 0)

    def test_malformed_flow_json_fails_open(self):
        self.write(".agents/flow.json", "{ not json")
        self.write("apps/api/app/main.py", "app = 'changed'\n")
        self.assertEqual(self.hook("contract-sync").returncode, 0)


class QualityGateTests(HookTestCase):
    def setUp(self):
        super().setUp()
        self.marker = Path(self.temp.name) / "check-runs"

    def configure(self, script, **extra):
        check = f'echo run >> "{self.marker}"; {script}'
        self.flow(api_paths=["apps/api/app"], code_paths=["apps"], check=check, **extra)
        self.commit()

    def runs(self):
        return len(self.marker.read_text().splitlines()) if self.marker.exists() else 0

    def test_skips_without_code_changes(self):
        self.configure("exit 1")
        self.write("docs/notes.md", "docs only\n")
        self.assertEqual(self.hook("quality-gate").returncode, 0)
        self.assertEqual(self.runs(), 0)

    def test_passing_check_passes_and_is_not_rerun_for_the_same_state(self):
        self.configure("exit 0")
        self.write("apps/api/app/main.py", "app = 1\n")
        self.assertEqual(self.hook("quality-gate").returncode, 0)
        self.assertEqual(self.hook("quality-gate").returncode, 0)
        self.assertEqual(self.runs(), 1)
        self.write("apps/api/app/main.py", "app = 2\n")
        self.assertEqual(self.hook("quality-gate").returncode, 0)
        self.assertEqual(self.runs(), 2)

    def test_failing_check_blocks_with_output_tail(self):
        self.configure("for i in $(seq 1 100); do echo line-$i; done; exit 3")
        self.write("apps/web/page.tsx", "export {}\n")
        result = self.hook("quality-gate")
        self.assertEqual(result.returncode, 2)
        self.assertIn("exited 3", result.stderr)
        self.assertIn("line-100", result.stderr)
        self.assertIn("line-61", result.stderr)
        self.assertNotIn("line-60\n", result.stderr)

    def test_stop_hook_active_skips(self):
        self.configure("exit 1")
        self.write("apps/api/app/main.py", "app = 1\n")
        self.assertEqual(self.hook("quality-gate", {"stop_hook_active": True}).returncode, 0)
        self.assertEqual(self.runs(), 0)

    def test_no_check_or_no_flow_skips(self):
        self.flow(api_paths=["apps/api/app"])
        self.commit()
        self.write("apps/api/app/main.py", "app = 1\n")
        self.assertEqual(self.hook("quality-gate").returncode, 0)
        (self.repo / ".agents/flow.json").unlink()
        self.assertEqual(self.hook("quality-gate").returncode, 0)

    def test_timeout_fails_open(self):
        self.configure("sleep 30; exit 1", check_timeout=1)
        self.write("apps/api/app/main.py", "app = 1\n")
        result = self.hook("quality-gate")
        self.assertEqual(result.returncode, 0, result.stderr)


class FormatOnEditTests(HookTestCase):
    def edit(self, path, **extra):
        return self.hook("format-on-edit", {"tool_name": "Edit", "tool_input": {"file_path": str(path)}, **extra})

    def test_formats_by_extension_and_path_scope(self):
        formatter = Path(self.temp.name) / "fmt.sh"
        formatter.write_text('#!/bin/sh\necho "$PWD" > "$1.formatted"\n')
        formatter.chmod(0o755)
        self.flow(format={".py,.pyi": {"command": f"sh '{formatter}'", "cwd": "apps/api", "paths": ["apps/api"]}})
        target = self.write("apps/api/app/main.py", "x=1\n")
        self.assertEqual(self.edit(target).returncode, 0)
        self.assertEqual(Path(str(target) + ".formatted").read_text().strip(), str(self.repo / "apps/api"))
        # Outside the scoped paths, or another extension: untouched.
        other = self.write("scripts/tool.py", "x=1\n")
        note = self.write("apps/api/notes.txt", "x\n")
        self.assertEqual(self.edit(other).returncode, 0)
        self.assertEqual(self.edit(note).returncode, 0)
        self.assertFalse(Path(str(other) + ".formatted").exists())
        self.assertFalse(Path(str(note) + ".formatted").exists())

    def test_never_blocks(self):
        failing = Path(self.temp.name) / "fail.sh"
        failing.write_text("#!/bin/sh\necho broken >&2\nexit 2\n")
        self.flow(format={".py": f"sh '{failing}'", ".ts": "definitely-not-a-command --write"})
        py = self.write("apps/api/app/main.py", "x=1\n")
        ts = self.write("apps/web/page.ts", "export {}\n")
        for result in (self.edit(py), self.edit(ts), self.edit(self.repo / "missing.py"),
                       self.hook("format-on-edit", raw="garbage"), self.hook("format-on-edit", {"tool_input": {}})):
            self.assertEqual(result.returncode, 0, result.stderr)


class TemplateTests(unittest.TestCase):
    def test_template_json_is_valid_and_matches_hook_schema(self):
        flow = json.loads((TEMPLATE / ".agents/flow.json").read_text())
        for key in ("api_paths", "contract_paths", "check", "format"):
            self.assertIn(key, flow)
        for root in flow["api_paths"] + flow["contract_paths"]:
            self.assertTrue(root.startswith(("apps/", "docs/")), root)
        settings = json.loads((TEMPLATE / ".claude/settings.json").read_text())
        commands = [hook["command"] for groups in settings["hooks"].values() for group in groups for hook in group["hooks"]]
        self.assertEqual(len(commands), 3)
        for command in commands:
            self.assertIn("/agent-config/scripts/hooks/", command)
            script = command.split("/agent-config/")[1].split('"')[0]
            self.assertTrue((SOURCE / script).is_file(), script)

    def test_settings_commands_exit_zero_without_agent_config(self):
        settings = json.loads((TEMPLATE / ".claude/settings.json").read_text())
        with tempfile.TemporaryDirectory(prefix="agent-hooks-") as empty:
            env = {**os.environ, "XDG_CONFIG_HOME": empty, "HOME": empty}
            for groups in settings["hooks"].values():
                for group in groups:
                    for hook in group["hooks"]:
                        result = subprocess.run(["sh", "-c", hook["command"]], input="{}", text=True,
                                                capture_output=True, env=env, cwd=empty, timeout=30)
                        self.assertEqual(result.returncode, 0, hook["command"])

    def test_settings_commands_reach_the_hooks_when_installed(self):
        settings = json.loads((TEMPLATE / ".claude/settings.json").read_text())
        stop = settings["hooks"]["Stop"][0]["hooks"][0]["command"]
        with tempfile.TemporaryDirectory(prefix="agent-hooks-") as temp:
            config = Path(temp) / "config"
            config.mkdir()
            (config / "agent-config").symlink_to(SOURCE)
            repo = Path(temp) / "repo"
            shutil.copytree(TEMPLATE, repo)
            env = {**os.environ, **GIT_ENV, "XDG_CONFIG_HOME": str(config)}
            subprocess.run(["git", "init", "-q", "-b", "main"], cwd=repo, env=env, check=True)
            subprocess.run(["git", "add", "-A"], cwd=repo, env=env, check=True)
            subprocess.run(["git", "commit", "-q", "-m", "scaffold"], cwd=repo, env=env, check=True)
            (repo / "apps/api/app").mkdir(parents=True)
            (repo / "apps/api/app/main.py").write_text("app = None\n")
            result = subprocess.run(["sh", "-c", stop], input=json.dumps({"cwd": str(repo)}), text=True,
                                    capture_output=True, env=env, cwd=repo, timeout=30)
            self.assertEqual(result.returncode, 2, result.stderr)
            self.assertIn("contract", result.stderr)


if __name__ == "__main__":
    unittest.main()
