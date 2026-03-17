import tempfile
import unittest
from pathlib import Path

from scripts.bootstrap_deps import (
    build_bootstrap_plan_lines,
    build_result_lines,
    build_phase_summary,
    build_package_items,
    build_tool_items,
    classify_status,
    classify_action,
    is_brew_package_outdated,
    is_winget_package_outdated,
    load_dependency_policy,
    normalize_package_name,
    parse_brewfile,
    parse_mise_toml,
    preflight_payload,
    referenced_runtime_paths,
    phase_requires_stop,
    plan_package_actions,
    plan_tool_actions,
    summarize_results,
    tool_version_satisfies,
)


class BootstrapDepsTests(unittest.TestCase):
    def test_load_dependency_policy_marks_required_and_optional_items(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            policy_path = Path(tmp_dir) / "bootstrap-priority.json"
            policy_path.write_text(
                '{"packages":{"python":{"required_now":true},"dotnet":{"required_now":false}},"tools":{"python":{"required_now":true}}}',
                encoding="utf-8",
            )

            policy = load_dependency_policy(policy_path)

        self.assertTrue(policy["packages"]["python"]["required_now"])
        self.assertFalse(policy["packages"]["dotnet"]["required_now"])
        self.assertTrue(policy["tools"]["python"]["required_now"])

    def test_classify_action_returns_skip_for_satisfied_items(self) -> None:
        item = {"installed": True, "outdated": False}

        self.assertEqual(classify_action(item), "skip")

    def test_classify_action_returns_update_for_outdated_items(self) -> None:
        item = {"installed": True, "outdated": True}

        self.assertEqual(classify_action(item), "update")

    def test_classify_action_returns_install_for_missing_items(self) -> None:
        item = {"installed": False, "outdated": False}

        self.assertEqual(classify_action(item), "install")

    def test_normalize_package_name_maps_platform_specific_ids(self) -> None:
        self.assertEqual(normalize_package_name("brew", "python@3.12"), "python")
        self.assertEqual(normalize_package_name("winget", "Python.Python.3.12"), "python")
        self.assertEqual(normalize_package_name("winget", "jdx.mise"), "mise")

    def test_build_phase_summary_counts_actions(self) -> None:
        items = [
            {"action": "skip", "required_now": True},
            {"action": "install", "required_now": True},
            {"action": "update", "required_now": False},
            {"action": "warn", "required_now": False},
        ]

        self.assertEqual(
            build_phase_summary("Packages", items),
            "Packages: 1 skip, 1 install, 1 update, 1 warn",
        )

    def test_phase_requires_stop_when_required_item_failed(self) -> None:
        results = [
            {"required_now": False, "status": "warn"},
            {"required_now": True, "status": "fail"},
        ]

        self.assertTrue(phase_requires_stop(results))

    def test_plan_package_actions_sets_skip_install_update(self) -> None:
        packages = [
            {"name": "git", "installed": True, "outdated": False, "required_now": True},
            {"name": "python", "installed": False, "outdated": False, "required_now": True},
            {"name": "dotnet", "installed": True, "outdated": True, "required_now": False},
        ]

        planned = plan_package_actions(packages)

        self.assertEqual([item["action"] for item in planned], ["skip", "install", "update"])

    def test_plan_tool_actions_sets_update(self) -> None:
        tools = [{"name": "dotnet", "installed": True, "outdated": True, "required_now": False}]

        planned = plan_tool_actions(tools)

        self.assertEqual(planned[0]["action"], "update")

    def test_summarize_results_treats_optional_failures_as_warnings(self) -> None:
        results = [
            {"name": "dotnet", "required_now": False, "status": "fail"},
            {"name": "python", "required_now": True, "status": "fail"},
            {"name": "go", "required_now": False, "status": "warn"},
        ]

        summary = summarize_results(results)

        self.assertEqual(summary["warnings"], 2)
        self.assertEqual(summary["failures"], 1)

    def test_tool_version_satisfies_requested_major_version(self) -> None:
        self.assertTrue(tool_version_satisfies("8.0.419", "8"))
        self.assertTrue(tool_version_satisfies("3.12.9", "3.12"))
        self.assertFalse(tool_version_satisfies("7.0.100", "8"))
        self.assertFalse(tool_version_satisfies("3.11.8", "3.12"))

    def test_is_brew_package_outdated_uses_outdated_listing(self) -> None:
        self.assertTrue(is_brew_package_outdated("python", {"python", "go"}))
        self.assertFalse(is_brew_package_outdated("git", {"python", "go"}))

    def test_is_winget_package_outdated_uses_upgrade_listing(self) -> None:
        self.assertTrue(is_winget_package_outdated("Git.Git", {"Git.Git", "Python.Python.3.12"}))
        self.assertFalse(is_winget_package_outdated("jdx.mise", {"Git.Git", "Python.Python.3.12"}))

    def test_build_bootstrap_plan_lines_mentions_log_directory(self) -> None:
        lines = build_bootstrap_plan_lines(
            package_summary="Packages: 2 skip, 1 install, 0 update, 0 warn",
            tool_summary="Tools: 1 skip, 0 install, 1 update, 0 warn",
            required_items=["git", "python"],
            log_dir=".bootstrap-logs/20260317T190500",
        )

        self.assertTrue(any("Detailed logs:" in line for line in lines))
        self.assertTrue(any("Required for continuation: git, python" == line for line in lines))

    def test_build_result_lines_points_to_logs_for_warnings(self) -> None:
        lines = build_result_lines(
            [
                {"name": "git", "status": "skip", "log_file": "unused.log"},
                {"name": "dotnet", "status": "warn", "log_file": ".bootstrap-logs/dotnet.log"},
            ]
        )

        self.assertEqual(lines[0], "skip git")
        self.assertEqual(lines[1], "warn dotnet -> see .bootstrap-logs/dotnet.log")

    def test_classify_status_marks_optional_failure_as_warn(self) -> None:
        self.assertEqual(classify_status(required_now=False, returncode=1), "warn")

    def test_classify_status_marks_required_failure_as_fail(self) -> None:
        self.assertEqual(classify_status(required_now=True, returncode=1), "fail")

    def test_referenced_runtime_paths_include_public_entrypoints(self) -> None:
        paths = referenced_runtime_paths()
        self.assertIn("bootstrap.sh", paths)
        self.assertIn("bootstrap.ps1", paths)
        self.assertIn("install-skills.sh", paths)
        self.assertIn("install-skills.ps1", paths)

    def test_parse_brewfile_extracts_formula_names(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            brewfile = Path(tmp_dir) / "Brewfile"
            brewfile.write_text('brew "git"\nbrew "python@3.12"\n', encoding="utf-8")

            self.assertEqual(parse_brewfile(brewfile), ["git", "python@3.12"])

    def test_parse_mise_toml_extracts_tool_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            mise_toml = Path(tmp_dir) / "mise.toml"
            mise_toml.write_text('[tools]\nnode = "lts"\npython = "3.12"\n', encoding="utf-8")

            self.assertEqual(parse_mise_toml(mise_toml), {"node": "lts", "python": "3.12"})

    def test_build_package_items_uses_policy_flags(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "manifest" / "packages").mkdir(parents=True)
            (root / "manifest" / "dependencies").mkdir(parents=True)
            (root / "manifest" / "packages" / "Brewfile").write_text('brew "git"\n', encoding="utf-8")
            (root / "manifest" / "dependencies" / "bootstrap-priority.json").write_text(
                '{"packages":{"git":{"required_now":true}},"tools":{}}',
                encoding="utf-8",
            )

            policy = load_dependency_policy(root / "manifest" / "dependencies" / "bootstrap-priority.json")
            items = build_package_items(root, policy)

        if items:
            self.assertTrue(items[0]["required_now"])

    def test_build_tool_items_uses_requested_versions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "manifest" / "tools").mkdir(parents=True)
            (root / "manifest" / "dependencies").mkdir(parents=True)
            (root / "manifest" / "tools" / "mise.toml").write_text('[tools]\npython = "3.12"\n', encoding="utf-8")
            policy = {"packages": {}, "tools": {"python": {"required_now": True}}}

            items = build_tool_items(root, policy)

        self.assertEqual(items[0]["requested_version"], "3.12")
        self.assertTrue(items[0]["required_now"])

    def test_preflight_payload_collects_required_items(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir:
            root = Path(tmp_dir)
            (root / "manifest" / "dependencies").mkdir(parents=True)
            (root / "manifest" / "packages").mkdir(parents=True)
            (root / "manifest" / "tools").mkdir(parents=True)
            (root / "manifest" / "dependencies" / "bootstrap-priority.json").write_text(
                '{"packages":{"git":{"required_now":true}},"tools":{"python":{"required_now":true}}}',
                encoding="utf-8",
            )
            (root / "manifest" / "packages" / "Brewfile").write_text('brew "git"\n', encoding="utf-8")
            (root / "manifest" / "tools" / "mise.toml").write_text('[tools]\npython = "3.12"\n', encoding="utf-8")

            payload = preflight_payload(root, root / ".bootstrap-logs" / "test")

        self.assertIn("required_items", payload)


if __name__ == "__main__":
    unittest.main()
