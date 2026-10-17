"""Exercise the offline renderer's public CLI and immutable identity boundary."""

import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts/render-acceleration-matrix.py"


class RenderAccelerationMatrixTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.output = Path(self.temp.name) / "matrix.md"

    def run_cli(self, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPT), "--output", str(self.output), *args],
            cwd=self.temp.name, capture_output=True, text=True,
        )

    def write_matrix(self):
        result = self.run_cli("--write")
        self.assertEqual(result.returncode, 0, result.stderr)
        return self.output.read_text()

    def test_all_104_rows_preserve_independent_canonical_identity_order(self):
        text = self.write_matrix()
        rows = [line.split(" | ") for line in text.splitlines() if line.startswith("| AUDIO-")]
        identities = json.loads((ROOT / "tests/audio-catalog-identities.json").read_text())
        self.assertEqual(len(rows), 104)
        self.assertEqual([(r[0][2:], r[1].strip("`")) for r in rows], list(identities.items()))

    def test_summary_counts_and_published_cpu_packages(self):
        text = self.write_matrix()
        for count in ("**104** canonical repositories", "**99** complete", "**5** blocked-evidence",
                      "**98** backend records", "**4** packaged", "**100** catalog-only"):
            self.assertIn(count, text)
        for attribute in ("audio-restoration-vst", "intersect", "peakeater", "toneshifteq"):
            self.assertIn(f"`packages.x86_64-linux.{attribute}`", text)
        self.assertIn("`null`", text)

    def test_backend_records_and_source_rights_evidence_are_visible(self):
        text = self.write_matrix()
        rows = [line for line in text.splitlines() if line.startswith("| [AUDIO-")]
        self.assertEqual(len(rows), 98)
        self.assertIn("model_execution / provider_execution / host", text)
        self.assertIn("not-run-policy", text)
        self.assertIn("onnxruntime-migraphx", text)
        for number in range(1, 105):
            self.assertIn(f"acceleration/AUDIO-{number:03}.md", text)
        self.assertIn("License evidence:", text)
        self.assertIn("Next action:", text)

    def test_fresh_check_does_not_rewrite(self):
        self.write_matrix()
        before = (self.output.read_bytes(), self.output.stat().st_mtime_ns)
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.output.read_bytes(), self.output.stat().st_mtime_ns), before)

    def test_stale_check_fails_without_modifying_output(self):
        self.write_matrix()
        self.output.write_text("stale matrix\n")
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn("stale", result.stderr)
        self.assertEqual(self.output.read_text(), "stale matrix\n")

    def test_missing_check_fails_without_creating_output(self):
        result = self.run_cli("--check")
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertFalse(self.output.exists())

    def test_identity_drift_rejected_before_overwriting_output(self):
        catalog = json.loads((ROOT / "catalog/audio-104.json").read_text())
        catalog["entries"][0]["repository"] = "wrong/identity"
        changed = Path(self.temp.name) / "catalog.json"
        changed.write_text(json.dumps(catalog))
        self.output.write_text("preserve me\n")
        result = self.run_cli("--catalog", str(changed))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("identity", result.stderr)
        self.assertEqual(self.output.read_text(), "preserve me\n")


if __name__ == "__main__":
    unittest.main()
