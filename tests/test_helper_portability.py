"""Public build helpers must not require an operator-specific scratch root."""

from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[1]


class HelperPortabilityTests(unittest.TestCase):
    def test_family_helpers_have_no_literal_absolute_scratch_path(self):
        for name in ("build-batch.py", "test_api.py"):
            with self.subTest(name=name):
                source = (ROOT / "pkgs/basilica-native-suite" / name).read_text()
                self.assertNotRegex(source, r"['\"]/(?:tmp|home|Users)/")


if __name__ == "__main__":
    unittest.main()
