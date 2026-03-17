import unittest

from scripts.bootstrap_deps import referenced_runtime_paths


class CleanupAuditTests(unittest.TestCase):
    def test_public_entrypoints_remain_in_runtime_paths(self) -> None:
        paths = referenced_runtime_paths()
        self.assertIn("bootstrap.sh", paths)
        self.assertIn("bootstrap.ps1", paths)
        self.assertIn("install-skills.sh", paths)
        self.assertIn("install-skills.ps1", paths)


if __name__ == "__main__":
    unittest.main()
