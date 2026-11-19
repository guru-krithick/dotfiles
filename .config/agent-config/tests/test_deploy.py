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
        self.assertEqual(current["permissions"], {**local["permissions"], "defaultMode": "bypassPermissions"})
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

    def test_default_mode_is_owned_and_other_permissions_are_kept(self):
        desired = json.loads((self.source / "config/claude.json").read_text())
        local = {"allow": ["Bash(local-check)"], "deny": ["Read(./.env)"], "additionalDirectories": ["../shared"], "defaultMode": "plan"}
        result = deploy.merge_claude({"permissions": local}, desired)
        self.assertEqual(result["permissions"], {**local, "defaultMode": "bypassPermissions"})
        self.assertIs(result["skipDangerousModePermissionPrompt"], True)
        self.assertEqual(deploy.merge_claude({}, desired)["permissions"], {"defaultMode": "bypassPermissions"})

    def test_owned_hooks_are_replaced_once_and_foreign_hooks_kept(self):
        self.runtime()
        stale = 'python3 "$HOME/.config/agent-config/scripts/retired.py"'
        lookalike = 'python3 "$HOME/my-agent-config/hook.py"'
        settings = self.home / ".claude/settings.json"
        settings.parent.mkdir(parents=True)
        settings.write_text(json.dumps({"hooks": {
            "Stop": [{"hooks": [{"type": "command", "command": "local-hook"}, {"type": "command", "command": stale}]}],
            "SessionStart": [{"hooks": [{"type": "command", "command": stale}]}],
            "PostToolUse": [{"matcher": "Edit", "hooks": [{"type": "command", "command": lookalike}, {"type": "command", "command": "plugin-formatter"}]}],
        }}))
        self.apply()
        first = settings.read_text()
        self.assertEqual(self.deployment.plan(), [])
        self.apply()
        self.assertEqual(settings.read_text(), first)
        hooks = json.loads(first)["hooks"]
        commands = {event: [handler["command"] for group in groups for handler in group["hooks"]] for event, groups in hooks.items()}
        notify = json.loads((self.source / "config/claude.json").read_text())["hooks"]["Stop"][0]["hooks"][0]["command"]
        self.assertEqual(commands["Stop"], ["local-hook", notify])
        self.assertEqual(commands["Notification"], [notify])
        self.assertEqual(commands["PostToolUse"], [lookalike, "plugin-formatter"])
        self.assertEqual(hooks["PostToolUse"][0]["matcher"], "Edit")
        self.assertNotIn("SessionStart", hooks)

    def test_claude_agents_link_into_every_home(self):
        self.runtime()
        agents = self.source / "agents/claude"
        agents.mkdir(exist_ok=True)
        (agents / "reviewer.md").write_text("---\nname: reviewer\ndescription: Review a diff against its spec.\n---\n\nReview only.\n")
        planned = [path for kind, path, _ in self.deployment.plan() if kind == "link"]
        homes = [self.home / ".claude", self.home / ".claude-alt"]
        for home in homes:
            self.assertIn(home / "agents/reviewer.md", planned)
        self.apply()
        for home in homes:
            link = home / "agents/reviewer.md"
            self.assertFalse(os.readlink(link).startswith("/"))
            self.assertEqual(link.resolve(), (agents / "reviewer.md").resolve())
        self.assertTrue((self.home / ".codex/agents/repo_explorer.toml").is_symlink())
        self.assertFalse((self.home / ".codex/agents/claude").exists())
        (agents / "builder.md").write_text("---\nname: someone-else\ndescription: Mismatched name.\n---\n")
        with self.assertRaisesRegex(ValueError, "Invalid agent definition: builder.md"):
            self.deployment.plan()

    def test_every_claude_home_is_configured_and_shares_projects(self):
        self.runtime()
        primary, alt = self.home / ".claude", self.home / ".claude-alt"
        primary.mkdir(parents=True)
        (primary / "settings.json").write_text(json.dumps({"env": {"LOCAL_ONLY": "1"}}))
        self.apply()
        for home in (primary, alt):
            settings = json.loads((home / "settings.json").read_text())
            self.assertEqual(settings["permissions"], {"defaultMode": "bypassPermissions"})
            self.assertIn("Stop", settings["hooks"])
            for name in ("CLAUDE.md", "claude-powerline.json", "skills/grilling"):
                self.assertTrue((home / name).is_symlink(), home / name)
        self.assertEqual(json.loads((primary / "settings.json").read_text())["env"], {"LOCAL_ONLY": "1"})
        self.assertNotIn("env", json.loads((alt / "settings.json").read_text()))
        self.assertTrue((primary / "projects").is_dir() and not (primary / "projects").is_symlink())
        self.assertEqual(os.readlink(alt / "projects"), "../.claude/projects")
        self.assertEqual(self.deployment.plan(), [])
        for home, model in ((primary, "primary-choice"), (alt, "alt-choice")):
            settings = json.loads((home / "settings.json").read_text())
            settings["model"] = model
            (home / "settings.json").write_text(json.dumps(settings))
        with contextlib.redirect_stdout(io.StringIO()):
            self.deployment.capture()
        self.assertEqual(json.loads((self.source / "config/claude.json").read_text())["model"], "primary-choice")

    def test_shared_projects_never_replace_existing_history(self):
        self.runtime()
        projects = self.home / ".claude-alt/projects"
        (projects / "-work").mkdir(parents=True)
        (projects / "-work/session.jsonl").write_text("history\n")
        with self.assertRaisesRegex(ValueError, "manual merge"):
            self.apply()
        self.assertEqual((projects / "-work/session.jsonl").read_text(), "history\n")
        self.assertFalse((self.home / ".claude").exists())
        shutil.rmtree(projects / "-work")
        self.apply()  # An empty directory is moved into the backup and replaced by the link.
        self.assertTrue(projects.is_symlink())
        (self.home / ".claude/projects").rmdir()
        (self.home / ".claude/projects").symlink_to(self.root / "unmounted-disk")
        with self.assertRaisesRegex(ValueError, "must be a directory"):
            self.deployment.plan()

    def test_codex_autonomy_survives_merge_and_capture(self):
        desired = tomllib.loads((self.source / "config/codex.toml").read_text())
        live = 'approval_policy = "on-request"\nsandbox_mode = "workspace-write"\n[profiles.careful]\napproval_policy = "on-request"\n'
        merged = deploy.merge_codex(live, desired)
        self.assertEqual(deploy.merge_codex(merged, desired), merged)
        result = tomllib.loads(merged)
        self.assertEqual((result["approval_policy"], result["sandbox_mode"]), ("never", "danger-full-access"))
        self.assertEqual(result["profiles"]["careful"]["approval_policy"], "on-request")
        self.runtime()
        self.apply()
        config = self.home / ".codex/config.toml"
        config.write_text(config.read_text().replace('approval_policy = "never"', 'approval_policy = "on-request"'))
        with contextlib.redirect_stdout(io.StringIO()):
            self.deployment.capture()
        source = tomllib.loads((self.source / "config/codex.toml").read_text())
        self.assertEqual((source["approval_policy"], source["sandbox_mode"]), ("never", "danger-full-access"))
        claude = json.loads((self.source / "config/claude.json").read_text())
        self.assertEqual(claude["permissions"], {"defaultMode": "bypassPermissions"})
        self.assertIs(claude["skipDangerousModePermissionPrompt"], True)

    def test_claude_config_dir_replaces_only_an_unlisted_primary(self):
        home = self.deployment.home

        def homes(value):
            with patch.dict(os.environ, {"CLAUDE_CONFIG_DIR": str(value)}, clear=True):
                return deploy.Deployment(self.home, self.source).claude_homes
        self.assertEqual(homes(home / ".claude-alt"), [home / ".claude", home / ".claude-alt"])
        self.assertEqual(homes(home / "custom"), [home / "custom", home / ".claude-alt"])
        (self.source / "config/claude-homes.json").write_text('["~/.claude", "~/.claude/"]')
        with self.assertRaisesRegex(ValueError, "distinct"):
            deploy.Deployment(self.home, self.source, use_environment=False)

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow unavailable")
    def test_stow_accepts_deployment_links(self):
        self.runtime()
        self.apply()
        result = subprocess.run(["stow", "--simulate", "--restow", "--dir", str(self.checkout), "--target", str(self.home), "."], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == "__main__":
    unittest.main()
