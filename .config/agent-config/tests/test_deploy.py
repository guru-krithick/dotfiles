"""Exercise migration and portability using disposable homes and checkouts."""
import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import tomllib
import unittest
from unittest.mock import patch

SOURCE = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("agent_deploy", SOURCE / "deploy.py")
deploy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(deploy)


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="agent-portability-")
        self.root = Path(self.temp.name)
        self.checkout = self.root / "checkout with spaces"
        self.source = self.checkout / ".config/agent-config"
        shutil.copytree(SOURCE, self.source, ignore=shutil.ignore_patterns("__pycache__"))
        launcher = self.checkout / ".local/bin/agent-config"
        launcher.parent.mkdir(parents=True)
        shutil.copy2(SOURCE.parents[1] / ".local/bin/agent-config", launcher)
        self.home = self.root / "a different user"
        self.deployment = deploy.Deployment(self.home, self.source, use_environment=False)

    def tearDown(self):
        self.temp.cleanup()

    def runtime(self):
        package = self.deployment.runtime / "package"
        (package / "dist").mkdir(parents=True)
        (package / "dist/index.mjs").write_text("// test fixture\n")
        (package / "package.json").write_text(json.dumps({"version": self.deployment.lock["version"]}))

    def apply(self):
        with contextlib.redirect_stdout(io.StringIO()):
            self.deployment.apply()

    def test_plan_is_nonmutating(self):
        self.assertTrue(self.deployment.plan())
        self.assertFalse(self.home.exists())

    def test_fresh_home_relative_links_and_repeat_apply(self):
        self.runtime()
        self.apply()
        self.assertEqual(self.deployment.plan(), [])
        for path in (self.home / ".config/agent-config", self.home / ".claude/CLAUDE.md", self.home / ".codex/agents/repo_explorer.toml"):
            self.assertTrue(path.exists())
            self.assertFalse(os.readlink(path).startswith("/"))
        self.assertEqual((self.home / ".local/bin/agent-config").resolve(), self.checkout / ".local/bin/agent-config")
        # A different username and checkout path should not enter portable preferences.
        for path in (self.home / ".claude/settings.json", self.home / ".codex/config.toml"):
            self.assertNotIn(str(self.root), path.read_text())
        self.apply()
        self.assertEqual(len(list((self.home / ".local/state/agent-config/backups").iterdir())), 1)

    def test_existing_machine_settings_survive_and_caps_are_removed(self):
        self.runtime()
        codex = self.home / ".codex/config.toml"
        codex.parent.mkdir(parents=True)
        codex.write_text('provider_note = "LOCAL_ONLY"\n[projects."/private/project"]\ntrust_level = "trusted"\n[agents]\nmax_threads = 2\n[agents.custom]\ndescription = "existing role"\n[tui]\nanimations = false\n')
        claude = self.home / ".claude/settings.json"
        claude.parent.mkdir(parents=True)
        local = {"env": {"PRIVATE_TOKEN": "TEST_SECRET"}, "permissions": {"allow": ["Bash(local-check)"]}, "hooks": {"Stop": [{"hooks": [{"type": "command", "command": "python3 /old-user/.config/agent-setup/scripts/notify.py"}, {"type": "command", "command": "local-hook"}]}]}}
        claude.write_text(json.dumps(local))
        self.apply()
        result = tomllib.loads(codex.read_text())
        self.assertEqual(result["provider_note"], "LOCAL_ONLY")
        self.assertIn("/private/project", result["projects"])
        self.assertEqual(result["agents"]["custom"]["description"], "existing role")
        self.assertNotIn("max_threads", result["agents"])
        self.assertNotIn("max_concurrent_threads_per_session", result["agents"])
        self.assertFalse(result["tui"]["animations"])
        current = json.loads(claude.read_text())
        self.assertEqual(current["env"], local["env"])
        self.assertEqual(current["permissions"], local["permissions"])
        commands = [handler["command"] for group in current["hooks"]["Stop"] for handler in group["hooks"]]
        self.assertIn("local-hook", commands)
        self.assertEqual(len(commands), 2)
        self.assertFalse(any("agent-setup" in command for command in commands))
        self.assertEqual(self.deployment.plan(), [])

    def test_multiline_notify_and_current_cap_are_migrated(self):
        source = 'notify = [\n "python3",\n "/old/path.py",\n]\n[agents]\nmax_concurrent_threads_per_session = 100\n'
        desired = tomllib.loads((self.source / "config/codex.toml").read_text())
        result = deploy.merge_codex(source, desired)
        self.assertEqual(deploy.merge_codex(result, desired), result)
        self.assertEqual(tomllib.loads(result)["agents"], {"enabled": True})

    def test_capture_excludes_secrets_trust_and_worker_limits(self):
        self.runtime()
        self.apply()
        path = self.home / ".claude/settings.json"
        live = json.loads(path.read_text())
        live["model"] = "test-preference"
        live["env"] = {"API_KEY": "TEST_SECRET_DO_NOT_EXPORT"}
        live["mcpServers"] = {"private": {"token": "TEST_SECRET_DO_NOT_EXPORT"}}
        path.write_text(json.dumps(live))
        path = self.home / ".codex/config.toml"
        path.write_text(path.read_text() + '\n[projects."/private/unique"]\ntrust_level = "trusted"\n')
        with contextlib.redirect_stdout(io.StringIO()):
            self.deployment.capture()
        exported = (self.source / "config/claude.json").read_text() + (self.source / "config/codex.toml").read_text()
        self.assertIn("test-preference", exported)
        self.assertNotIn("TEST_SECRET", exported)
        self.assertNotIn("/private/unique", exported)
        self.assertNotIn("max_concurrent_threads_per_session", exported)
        self.assertNotIn(str(self.root), exported)

    def test_readonly_preflight_changes_nothing(self):
        self.runtime()
        with patch.object(self.deployment, "readonly", return_value=True):
            with self.assertRaisesRegex(ValueError, "Read-only targets"):
                self.apply()
        self.assertFalse((self.home / ".claude").exists())
        self.assertFalse((self.home / ".codex").exists())
        self.assertFalse((self.home / ".local/state").exists())

    def test_identical_skill_directory_is_backed_up_before_linking(self):
        self.runtime()
        existing = self.home / ".codex/skills/grilling"
        shutil.copytree(self.source / "skills/grilling", existing)
        original = (existing / "SKILL.md").read_bytes()
        self.apply()
        self.assertTrue(existing.is_symlink())
        manifest = next((self.home / ".local/state/agent-config/backups").glob("*/manifest.json"))
        records = json.loads(manifest.read_text())
        record = next(record for record in records if record["path"] == str(existing))
        self.assertEqual((manifest.parent / record["backup"] / "SKILL.md").read_bytes(), original)

    def test_different_skill_directory_is_preserved(self):
        self.runtime()
        existing = self.home / ".codex/skills/grilling"
        existing.mkdir(parents=True)
        (existing / "SKILL.md").write_text("Different local work")
        with self.assertRaisesRegex(ValueError, "manual merge"):
            self.apply()
        self.assertEqual((existing / "SKILL.md").read_text(), "Different local work")
        self.assertFalse((self.home / ".claude").exists())

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow unavailable")
    def test_stow_accepts_deployment_links(self):
        self.runtime()
        self.apply()
        result = subprocess.run(["stow", "--simulate", "--restow", "--dir", str(self.checkout), "--target", str(self.home), "."], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
