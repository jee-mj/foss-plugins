"""Exercise the offline renderer's public CLI and immutable identity boundary."""

import json
import re
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
                      "**98** backend records", "**16** packaged", "**88** catalog-only",
                      "**12** native-plugin", "**4** windows-artifacts"):
            self.assertIn(count, text)
        for attribute in ("basilica-miserere", "basilica-seraph", "basilica-silentium",
                          "gunk-windows", "0xfx-windows", "toneshifteq-windows",
                          "audio-restoration-vst", "intersect", "peakeater", "toneshifteq",
                          "instawidth", "sub-orbit", "reevr", "wolf-shaper", "vaporizer2",
                          "drumcloud-windows", "tonetwist-windows", "wolf-shaper-windows"):
            self.assertIn(f"`packages.x86_64-linux.{attribute}`", text)
        self.assertIn("`null`", text)
        packaged = int(re.search(r"\*\*(\d+)\*\* packaged", text)[1])
        native = int(re.search(r"\*\*(\d+)\*\* native-plugin", text)[1])
        windows = int(re.search(r"\*\*(\d+)\*\* windows-artifacts", text)[1])
        self.assertEqual(native + windows, packaged)

    def test_invalid_packaged_scope_rejected_before_overwriting_output(self):
        for scope in (None, "typo-windows", "", ["windows-artifacts"]):
            with self.subTest(scope=scope):
                catalog = json.loads((ROOT / "catalog/audio-104.json").read_text())
                distribution = catalog["entries"][0]["distribution"]
                if scope is None:
                    distribution.pop("delivery_scope")
                else:
                    distribution["delivery_scope"] = scope
                changed = Path(self.temp.name) / "catalog.json"
                changed.write_text(json.dumps(catalog))
                self.output.write_text("preserve me\n")
                result = self.run_cli("--catalog", str(changed))
                self.assertEqual(result.returncode, 2, result.stderr)
                self.assertIn("AUDIO-001", result.stderr)
                self.assertIn("delivery_scope", result.stderr)
                self.assertEqual(self.output.read_text(), "preserve me\n")

    def test_root_validator_rejects_invalid_schema2_packaged_scope(self):
        for scope in (None, "typo-windows", "", ["windows-artifacts"]):
            with self.subTest(scope=scope):
                catalog = json.loads((ROOT / "catalog/audio-104.json").read_text())
                distribution = catalog["entries"][0]["distribution"]
                if scope is None:
                    distribution.pop("delivery_scope")
                else:
                    distribution["delivery_scope"] = scope
                changed = Path(self.temp.name) / "catalog.json"
                changed.write_text(json.dumps(catalog))
                result = subprocess.run(
                    [sys.executable, str(ROOT / "tests/audio-catalog.py"), str(changed),
                     "--require-assessed"], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("delivery_scope", result.stderr)

    def test_ordinary_schema1_validation_allows_legacy_missing_scopes(self):
        catalog = json.loads((ROOT / "catalog/audio-104.json").read_text())
        catalog["schema_version"] = 1
        for entry in catalog["entries"]:
            entry["distribution"].pop("delivery_scope", None)
        changed = Path(self.temp.name) / "catalog.json"
        changed.write_text(json.dumps(catalog))
        result = subprocess.run(
            [sys.executable, str(ROOT / "tests/audio-catalog.py"), str(changed)],
            capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_windows_delivery_is_visible_without_duplicate_repository(self):
        text = self.write_matrix()
        rows = [line for line in text.splitlines() if line.startswith("| AUDIO-")]
        for identity in ("AUDIO-001", "AUDIO-020", "AUDIO-040", "AUDIO-072"):
            row, = [r for r in rows if r.startswith(f"| {identity} |")]
            self.assertIn("packaged / windows-artifacts", row)
        wolf, = [r for r in rows if r.startswith("| AUDIO-067 |")]
        self.assertIn("packaged / native-plugin", wolf)
        self.assertIn("packages.x86_64-linux.wolf-shaper-windows", wolf)
        toneshift, = [r for r in rows if r.startswith("| AUDIO-097 |")]
        self.assertIn("packaged / native-plugin", toneshift)
        self.assertIn("packages.x86_64-linux.toneshifteq-windows", toneshift)

    def test_scope_counts_follow_input_instead_of_fixed_catalog_totals(self):
        catalog = json.loads((ROOT / "catalog/audio-104.json").read_text())
        for entry in catalog["entries"]:
            entry["distribution"].update(status="catalog-only", nix_attribute=None)
            entry["distribution"].pop("delivery_scope", None)
            entry["distribution"].pop("additional_attributes", None)
        catalog["entries"][0]["distribution"].update(
            status="packaged", nix_attribute="example-windows", delivery_scope="windows-artifacts")
        changed = Path(self.temp.name) / "catalog.json"
        changed.write_text(json.dumps(catalog))
        result = self.run_cli("--catalog", str(changed))
        self.assertEqual(result.returncode, 0, result.stderr)
        text = self.output.read_text()
        for count in ("**1** packaged", "**103** catalog-only", "**0** native-plugin",
                      "**1** windows-artifacts"):
            self.assertIn(count, text)

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
