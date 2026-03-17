import unittest

from scripts.bootstrap_deps import overwrite_usage_examples, resolve_overwrite_mode


class InstallSkillsCliTests(unittest.TestCase):
    def test_explicit_overwrite_flag_wins(self) -> None:
        mode = resolve_overwrite_mode(explicit_overwrite=True, env_value="0", noninteractive=True)
        self.assertEqual(mode, "overwrite")

    def test_noninteractive_without_flag_skips(self) -> None:
        mode = resolve_overwrite_mode(explicit_overwrite=False, env_value="", noninteractive=True)
        self.assertEqual(mode, "skip")

    def test_env_override_still_works_when_flag_absent(self) -> None:
        mode = resolve_overwrite_mode(explicit_overwrite=False, env_value="true", noninteractive=True)
        self.assertEqual(mode, "overwrite")

    def test_interactive_without_flag_prompts(self) -> None:
        mode = resolve_overwrite_mode(explicit_overwrite=False, env_value="", noninteractive=False)
        self.assertEqual(mode, "prompt")

    def test_overwrite_usage_examples_include_shell_and_powershell(self) -> None:
        examples = overwrite_usage_examples()
        self.assertIn("bash bootstrap.sh --overwrite-skills", examples)
        self.assertIn("powershell -ExecutionPolicy Bypass -File bootstrap.ps1 -OverwriteSkills", examples)


if __name__ == "__main__":
    unittest.main()
