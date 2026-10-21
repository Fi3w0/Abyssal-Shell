import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


loader = importlib.machinery.SourceFileLoader("updates_backend", str(Path(__file__).resolve().parents[1] / "scripts/updates"))
spec = importlib.util.spec_from_loader(loader.name, loader)
updates = importlib.util.module_from_spec(spec)
loader.exec_module(updates)


class UpdateSettingsTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        config = patch.object(updates, "CONFIG", str(Path(directory.name) / "updates.json"))
        config.start()
        self.addCleanup(config.stop)

    def test_settings_preserve_existing_rules(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "updates.json"
            path.write_text(json.dumps({"ignore": ["held-*"], "important": ["kernel*"], "custom": 42}))
            with patch.object(updates, "CONFIG", str(path)):
                result = updates.configure({"manager": "pacman", "intervalMinutes": 0, "flatpak": False})
            self.assertEqual(result["custom"], 42)
            self.assertEqual(result["ignore"], ["held-*"])
            self.assertEqual(json.loads(path.read_text())["intervalMinutes"], 0)

    def test_invalid_existing_file_is_not_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "updates.json"
            path.write_text("broken JSON")
            with patch.object(updates, "CONFIG", str(path)):
                with self.assertRaises(ValueError):
                    updates.configure({"manager": "auto"})
            self.assertEqual(path.read_text(), "broken JSON")

    def test_invalid_preferences_are_rejected(self):
        for changes in ({"intervalMinutes": -1}, {"flatpak": "false"}, {"manager": "unknown"}, {"manager": []}, {"dnfRepos": ["--disable-gpg"]}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                updates.configure(changes)

    def test_manual_manager_and_flatpak_selection(self):
        self.assertEqual([s[0] for s in updates.selected_sources({"manager": "yay", "flatpak": False})], ["pacman"])
        self.assertEqual([s[0] for s in updates.selected_sources({"manager": "dnf5"})], ["dnf", "flatpak"])
        self.assertEqual(updates.selected_sources({"manager": "none", "flatpak": False}), [])

    def test_missing_manual_manager_reports_error(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(updates, "CACHE", directory), \
                patch.object(updates, "settings", return_value={"manager": "pacman", "flatpak": False}), \
                patch.object(updates, "have", return_value=False):
            result = updates.check(False)
        self.assertIn("not installed", result["sources"][0]["error"])

    def test_explicit_aur_helper_is_used(self):
        cfg = {"manager": "yay", "includeAur": True}
        def run(command, **kwargs):
            return (0, "linux 1 -> 2\n", "") if command[0] == "checkupdates" else (0, "aur-app 3 -> 4\n", "")
        with patch.object(updates, "settings", return_value=cfg), \
                patch.object(updates, "have", side_effect=lambda name: name in ("checkupdates", "paru", "yay")), \
                patch.object(updates, "run", side_effect=run) as runner:
            result = updates.check_pacman()
        self.assertEqual([i["repo"] for i in result], ["repo", "aur"])
        self.assertIn(unittest.mock.call(["yay", "-Qua"], timeout=600), runner.call_args_list)

    def test_aur_can_be_excluded(self):
        with patch.object(updates, "settings", return_value={"includeAur": False}), \
                patch.object(updates, "have", return_value=True), \
                patch.object(updates, "run", return_value=(0, "linux 1 -> 2\n", "")) as runner:
            result = updates.check_pacman()
        self.assertEqual(len(result), 1)
        self.assertEqual(runner.call_count, 1)

    def test_missing_selected_helper_does_not_fall_back(self):
        with patch.object(updates, "have", side_effect=lambda name: name == "paru"):
            with self.assertRaisesRegex(RuntimeError, "yay"):
                updates.aur_helper({"manager": "yay", "includeAur": True})

    def test_dnf_check_and_upgrade_use_the_same_selection(self):
        cfg = {"manager": "dnf5", "flatpak": False, "dnfRepoMode": "selected", "dnfRepos": ["fedora", "copr:example"], "sudo": "sudo"}
        def run(command, **kwargs):
            return (100, "hello.x86_64 2-1 copr:example\n", "") if command[0] == "dnf5" else (0, "hello 1-1\n", "")
        with patch.object(updates, "settings", return_value=cfg), \
                patch.object(updates, "have", side_effect=lambda name: name == "dnf5"), \
                patch.object(updates, "run", side_effect=run) as runner, \
                patch.object(updates, "sh", return_value=0) as terminal, patch("builtins.input", return_value=""):
            result = updates.check_dnf()
            updates.upgrade([])
        self.assertEqual(result[0]["repo"], "copr:example")
        self.assertIn("--repo=fedora,copr:example", runner.call_args_list[0].args[0])
        terminal.assert_called_once_with(["sudo", "dnf5", "upgrade", "--repo=fedora,copr:example"])

    def test_empty_explicit_repository_selection_is_an_error(self):
        with self.assertRaises(RuntimeError):
            updates.dnf_flags({"dnfRepoMode": "selected", "dnfRepos": []})


if __name__ == "__main__":
    unittest.main()
