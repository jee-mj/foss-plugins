"""Offline contract tests; set PRODUCT_REPORTS to check a report capture too."""

import copy
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "lib"))
try:
    import product_catalog as catalog
except ModuleNotFoundError:
    catalog = None

IDENTITIES = json.loads((ROOT / "tests/product-catalog-identities.json").read_text())
PIN = "294ed7fb3116f1f16c7430e5df7e1954349405c6"


def report(identity="AUDIO-001"):
    return {
        "identity": identity, "repository": IDENTITIES[identity],
        "alias_ids": {"AUDIO-003": ["BA-013"], "AUDIO-007": ["BA-006"],
                      "AUDIO-058": ["BA-004"]}.get(identity, []),
        "source_revision": PIN, "disposition": "applicable",
        "reason": "Pinned source target; no build demonstrated.",
        "products": [{
            "id": identity + "/source-target", "name": "Source target", "kind": "effect",
            "formats": ["VST3"], "plugin_ids": {},
            "native": {"status": "source-candidate", "attributes": [],
                       "reason": "Source target exists.", "next_action": "Inspect closure."},
            "windows": {"status": "needs-evidence", "architecture": "unknown",
                        "toolchain": "unknown", "artifact_type": "source-only",
                        "installer_source_status": "unverified", "reason": "No builder evidence.",
                        "next_action": "Inspect build definitions."}}],
        "evidence": [{"url": "https://github.com/" + IDENTITIES[identity] + "/blob/" + PIN + "/CMakeLists.txt",
                      "revision": PIN, "summary": "Source target declaration."}],
        "copyright_notes": ["License review informational; no technical gate."],
        "next_action": "Inspect pinned dependency closure.",
    }


class ProductCatalogTests(unittest.TestCase):
    def setUp(self):
        self.assertIsNotNone(catalog, "product_catalog implementation is required")

    def test_identity_mapping_preserves_capture_and_exact_basilica_aliases(self):
        captured = json.loads((ROOT / "tests/audio-catalog-identities.json").read_text())
        self.assertEqual({k: v for k, v in IDENTITIES.items() if k.startswith("AUDIO-")}, captured)
        self.assertEqual(len(IDENTITIES), 114)
        self.assertEqual({k: v for k, v in IDENTITIES.items() if k.startswith("BA-")}, {
            "BA-001": "basilica-audio/Overture", "BA-002": "basilica-audio/Tenebrae",
            "BA-003": "basilica-audio/Nave", "BA-005": "basilica-audio/Requiem",
            "BA-007": "basilica-audio/Aureate", "BA-008": "basilica-audio/Firmament",
            "BA-009": "basilica-audio/Triptych", "BA-010": "basilica-audio/Apotheosis",
            "BA-011": "basilica-audio/Crypta", "BA-012": "basilica-audio/Lancet"})
        self.assertEqual(catalog.validation_errors(report("AUDIO-003")), [])
        for key, value in [("repository", "other/repository"), ("alias_ids", []),
                           ("alias_ids", ["BA-006"]), ("identity", "BA-013")]:
            bad = report("AUDIO-003")
            bad[key] = value
            self.assertTrue(catalog.validation_errors(bad), key)

    def test_typed_required_fields_and_enums_are_total_and_deterministic(self):
        self.assertEqual(catalog.validation_errors(report()), [])
        for value in (None, [], 3, True, "report"):
            self.assertTrue(catalog.validation_errors(value))
        for key in report():
            for value in (None, [], {}, True, 3):
                bad = report()
                bad[key] = value
                # Null source revisions and empty collections have explicit separate tests.
                if (key == "source_revision" and value is None) or (key in
                        ("alias_ids", "products", "evidence", "copyright_notes") and value == []):
                    continue
                errors = catalog.validation_errors(bad)
                self.assertTrue(errors, (key, value))
                self.assertEqual(errors, catalog.validation_errors(bad))
            bad = report()
            del bad[key]
            self.assertTrue(catalog.validation_errors(bad), key)

    def test_product_and_route_contract_rejects_false_ready_labels(self):
        for path, value in [
            (("id",), "AUDIO-002/wrong"), (("id",), "AUDIO-001/../escape"),
            (("kind",), "plugin"), (("formats",), ["VST3", "VST3"]),
            (("formats",), [True]), (("plugin_ids",), []),
            (("plugin_ids",), {"CLAP": "unlisted.format"}),
            (("native", "status"), "ready"), (("native", "attributes"), "pkgs.example"),
            (("windows", "status"), "built"), (("windows", "architecture"), "amd64"),
            (("windows", "artifact_type"), "zip"),
            (("windows", "installer_source_status"), "ready"),
            (("windows", "toolchain"), None),
        ]:
            bad = report()
            node = bad["products"][0]
            for part in path[:-1]:
                node = node[part]
            node[path[-1]] = value
            self.assertTrue(catalog.validation_errors(bad), (path, value))
        bad = report()
        bad["products"] *= 2
        self.assertTrue(catalog.validation_errors(bad))

    def test_nested_source_ids_preserved_without_fabricated_uuid(self):
        good = report()
        good["products"][0]["plugin_ids"] = {"VST3": {
            "processor_fuid_words": ["7A31F4C2", "1D8B4E56", "A0C39B7E", "2F6D8104"],
            "class_id": None, "source_byte_string": "AutokitDrumM001\0"}}
        self.assertEqual(catalog.validation_errors(good), [])
        good["products"][0]["plugin_ids"]["VST3"]["processor_fuid_words"] = [True]
        self.assertTrue(catalog.validation_errors(good))

    def test_merge_encodes_nul_source_values_losslessly_without_mutating_reports(self):
        reports = [report(identity) for identity in IDENTITIES]
        source_id = "AutokitDrumM001\0"
        reports[0]["products"][0]["plugin_ids"] = {"VST3": {
            "source_byte_string": source_id,
            "source_byte_literal": r"GainBrainMpdPlg\0",
            "nested": [{"source": "é\0音"}, "plain-source-id"]}}
        original = copy.deepcopy(reports)
        result = catalog.merge_reports(reports)
        ids = result["repositories"][0]["products"][0]["plugin_ids"]["VST3"]
        self.assertEqual(ids["source_byte_string"], {
            "source_encoding": "utf8-hex", "bytes_hex": "4175746f6b69744472756d4d30303100"})
        restored = bytes.fromhex(ids["source_byte_string"]["bytes_hex"])
        self.assertEqual(len(restored), 16)
        self.assertEqual(restored, source_id.encode("utf-8"))
        self.assertEqual(restored.decode("utf-8"), source_id)
        self.assertEqual(ids["source_byte_literal"], r"GainBrainMpdPlg\0")
        self.assertEqual(ids["nested"], [{"source": {
            "source_encoding": "utf8-hex", "bytes_hex": "c3a900e99fb3"}}, "plain-source-id"])
        self.assertEqual(reports, original)
        self.assertEqual(catalog.merge_reports(result["repositories"]), result)
        self.assertNotIn("\\u0000", json.dumps(result))
        # The whole result is detached, not just the rewritten ID structures.
        result["repositories"][1]["copyright_notes"].append("consumer annotation")
        self.assertEqual(reports, original)

    def test_source_encoding_validates_exact_marker_hex_utf8_and_nul(self):
        for encoded in ({"source_encoding": "utf8-hex", "bytes_hex": "00"},
                        {"source_encoding": "utf8-hex", "bytes_hex": "c3a900"}):
            with self.subTest(encoded=encoded):
                item = report()
                item["products"][0]["plugin_ids"] = {"VST3": encoded}
                self.assertEqual(catalog.validation_errors(item), [])
        for encoded in (
            {"source_encoding": "base64", "bytes_hex": "00"},
            {"source_encoding": None, "bytes_hex": "00"},
            {"source_encoding": "utf8-hex"}, {"bytes_hex": "00"},
            {"source_encoding": "utf8-hex", "bytes_hex": "00", "extra": "value"},
            *({"source_encoding": "utf8-hex", "bytes_hex": value}
              for value in (None, True, 0, [], {}, "", "0", "gg", "00 00", "ff00", "6162", "eda08000")),
        ):
            with self.subTest(encoded=encoded):
                item = report()
                item["products"][0]["plugin_ids"] = {"VST3": {"source": encoded}}
                self.assertTrue(catalog.validation_errors(item))

    def test_raw_nul_remains_allowed_only_in_source_id_values(self):
        item = report()
        item["products"][0]["plugin_ids"] = {"VST3": "AutokitDrumM001\0"}
        self.assertEqual(catalog.validation_errors(item), [])
        item["reason"] += "\0"
        self.assertTrue(catalog.validation_errors(item))
        item = report()
        item["products"][0]["plugin_ids"] = {"VST3": {"source\0": "opaque"}}
        self.assertTrue(catalog.validation_errors(item))

    def test_encoded_source_ids_cannot_hide_private_metadata_or_invalid_utf8(self):
        item = report()
        item["products"][0]["plugin_ids"] = {"VST3": {
            "source_encoding": "utf8-hex", "bytes_hex": ("/root/receipt.json\0").encode().hex()}}
        self.assertTrue(catalog.validation_errors(item))
        item["products"][0]["plugin_ids"] = {"VST3": "\ud800\0"}
        self.assertTrue(catalog.validation_errors(item))

    def test_source_pins_and_public_evidence(self):
        for pin in ("main", "abcd", True, 4):
            bad = report()
            bad["source_revision"] = pin
            self.assertTrue(catalog.validation_errors(bad))
        bad = report()
        bad["evidence"] = []
        self.assertTrue(catalog.validation_errors(bad))
        for url in ("http://github.com/a/b", "https://localhost/a", "https://127.0.0.1/a",
                    "https://user:password@github.com/a/b", "https://github.com/a?token=secret",
                    "https://github.com/a/blob/main/file"):
            bad = report()
            bad["evidence"][0]["url"] = url
            self.assertTrue(catalog.validation_errors(bad), url)
        bad = report()
        bad["evidence"][0]["revision"] = "main"
        self.assertTrue(catalog.validation_errors(bad))

    def test_unresolved_and_skip_records_are_preserved_without_license_gate(self):
        for disposition in ("needs-evidence", "skip"):
            good = report()
            good.update(disposition=disposition, source_revision=None, products=[], evidence=[],
                        reason="Source revision unresolved: upstream source evidence missing.")
            self.assertEqual(catalog.validation_errors(good), [])
        bad = report()
        bad["source_revision"] = None
        self.assertTrue(catalog.validation_errors(bad))

    def test_null_source_with_explicit_gap_does_not_force_disposition(self):
        good = report()
        good.update(source_revision=None, evidence=[],
                    reason="Actual upstream target; exact source revision remains unresolved.")
        self.assertEqual(catalog.validation_errors(good), [])

    def test_source_revision_evidence_must_identify_primary_repository(self):
        bad = report()
        bad["evidence"][0]["url"] = "https://github.com/other/repo/blob/" + PIN + "/file"
        self.assertTrue(catalog.validation_errors(bad))

    def test_github_source_forms_require_matching_immutable_embedded_revision(self):
        repository = IDENTITIES["AUDIO-001"]
        for base in ("https://github.com/" + repository + "/blob/",
                     "https://github.com/" + repository + "/tree/",
                     "https://github.com/" + repository + "/commit/",
                     "https://github.com/" + repository + "/raw/",
                     "https://raw.githubusercontent.com/" + repository + "/"):
            for ref in (PIN, "main", "master", "v1.0.0", "a" * 40):
                with self.subTest(base=base, ref=ref):
                    item = report()
                    item["evidence"][0]["url"] = base + ref + "/README.md"
                    errors = catalog.validation_errors(item)
                    if ref == PIN:
                        self.assertEqual(errors, [])
                    else:
                        self.assertTrue(errors)

    def test_release_and_index_urls_are_supplementary_not_source_pins(self):
        repository = IDENTITIES["AUDIO-001"]
        for url in ("https://github.com/" + repository + "/releases/tag/v1.0.0",
                    "https://github.com/" + repository + "/releases/download/v1.0.0/source.zip",
                    "https://github.com/" + repository,
                    "https://example.org/package-index"):
            with self.subTest(url=url):
                item = report()
                item["evidence"][0]["url"] = url
                self.assertTrue(catalog.validation_errors(item))
                item["evidence"].append(report()["evidence"][0])
                self.assertEqual(catalog.validation_errors(item), [])

    def test_private_markers_credentials_and_paths_rejected_in_keys_and_values(self):
        for text in ("audio-issue999", "site_lab", "audio_issue999",
                     "See https://user:password@example.com/data for evidence.",
                     "/root/catalogue/receipt.json", r"\\studio\share\receipt.json",
                     "https://example.org/%61udio-issue999",
                     "https://user%3Apassword%40example.com/data"):
            for location in ("key", "value"):
                with self.subTest(text=text, location=location):
                    item = report()
                    item["products"][0]["plugin_ids"] = {"VST3": {
                        text if location == "key" else "source_annotation":
                        text if location == "value" else "source"}}
                    self.assertTrue(catalog.validation_errors(item))

    def test_private_word_and_escaped_source_ids_remain_valid(self):
        item = report()
        item["copyright_notes"] = ["Private source availability remains unresolved."]
        item["products"][0]["plugin_ids"] = {"VST3": {
            "source_byte_literal": r"GainBrainMpdPlg\0",
            "source_byte_string": "AutokitDrumM001\0"}}
        self.assertEqual(catalog.validation_errors(item), [])

    def test_public_evidence_rejects_ambiguous_numeric_hosts_and_accepts_strict_ips(self):
        for host, accepted in (("127.1", False), ("192.168.001.001", False),
                               ("0x7f.1", False), ("0177.0.0.1", False),
                               ("2130706433", False), ("999.1.2.3", False),
                               ("127.0.0.1", False), ("[::1]", False),
                               ("[fc00::1]", False), ("8.8.8.8", True),
                               ("[2606:4700:4700::1111]", True),
                               ("cdn123.example.org", True)):
            with self.subTest(host=host):
                item = report()
                item["evidence"].append({"url": "https://" + host + "/data",
                                         "revision": None, "summary": "Supplementary data."})
                errors = catalog.validation_errors(item)
                self.assertEqual(not errors, accepted, errors)

    def test_malformed_nested_objects_and_required_fields_report_errors(self):
        for field in ("native", "windows"):
            for value in (None, [], "route", True):
                bad = report()
                bad["products"][0][field] = value
                self.assertTrue(catalog.validation_errors(bad))
            for required in report()["products"][0][field]:
                bad = report()
                del bad["products"][0][field][required]
                self.assertTrue(catalog.validation_errors(bad))
        for value in (None, [], "evidence", True, {}, {"url": None, "revision": [], "summary": {}}):
            bad = report()
            bad["evidence"] = [value]
            self.assertTrue(catalog.validation_errors(bad))
        for value in (None, [], "product", True, {}):
            bad = report()
            bad["products"] = [value]
            self.assertTrue(catalog.validation_errors(bad))
        bad = report()
        bad["products"][0]["plugin_ids"] = {"VST3": {"class_id": True}}
        self.assertTrue(catalog.validation_errors(bad))
        bad["products"][0]["plugin_ids"] = {"VST3": bad}
        self.assertTrue(catalog.validation_errors(bad))

    def test_private_paths_and_metadata_cannot_escape_through_extensions(self):
        for text in ("/home/example/private", "~/Downloads/media", "/tmp/work/artifact",
                     "C:\\Users\\example\\private", "https://example.org/%2Fhome%2Fexample"):
            bad = report()
            bad["copyright_notes"] = [text]
            self.assertTrue(catalog.validation_errors(bad), text)
        bad = report()
        bad["collection_receipt"] = "local receipt"
        self.assertTrue(catalog.validation_errors(bad))
        bad = report()
        bad["products"][0]["plugin_ids"] = {"VST3": {"/home/example/private": "source"}}
        self.assertTrue(catalog.validation_errors(bad))

    def test_merge_exact_set_canonical_order_and_repository_uniqueness(self):
        reports = [report(k) for k in reversed(IDENTITIES)]
        result = catalog.merge_reports(reports)
        self.assertEqual(result["schema_version"], 1)
        self.assertEqual(result["captured_date"], "2026-10-17")
        self.assertEqual(result["source_catalog"], "catalog/audio-104.json")
        self.assertEqual([r["identity"] for r in result["repositories"]], list(IDENTITIES))
        self.assertEqual(result["product_count"], 114)
        for invalid in (reports[:-1], reports + [report()], reports + [dict(report(), identity="BA-013")]):
            with self.assertRaises(ValueError):
                catalog.merge_reports(invalid)
        invalid = copy.deepcopy(reports)
        invalid[0]["repository"] = invalid[1]["repository"].upper()
        with self.assertRaisesRegex(ValueError, "duplicate canonical repository"):
            catalog.merge_reports(invalid)

    def test_cli_rejects_duplicate_keys_and_preserves_output_on_invalid_input(self):
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            inputs = directory / "reports"
            inputs.mkdir()
            for identity in IDENTITIES:
                (inputs / (identity + ".json")).write_text(json.dumps(report(identity)))
            output = directory / "catalog.json"
            command = [sys.executable, str(ROOT / "scripts/merge-product-reports.py"),
                       "--reports", str(inputs), "--output", str(output)]
            run = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(run.returncode, 0, run.stderr)
            before = output.read_bytes()
            (inputs / "AUDIO-001.json").write_text('{"identity":"AUDIO-001","identity":"AUDIO-002"}')
            run = subprocess.run(command, capture_output=True, text=True)
            self.assertNotEqual(run.returncode, 0)
            self.assertIn("duplicate", run.stderr.lower())
            self.assertEqual(output.read_bytes(), before)
            (inputs / "AUDIO-001.json").write_text(json.dumps(report()))
            (inputs / "AUDIO-002.json").unlink()
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(output.read_bytes(), before)
            (inputs / "AUDIO-002.json").write_text(json.dumps(report()))
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(output.read_bytes(), before)
            (inputs / "AUDIO-002.json").write_text(json.dumps(report("AUDIO-002")))
            (inputs / "extra.json").write_text("{}")
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(output.read_bytes(), before)

    def test_strict_json_rejects_nested_duplicates_and_non_json_constants(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "report.json"
            for content in ('{"nested":{"status":"source-candidate","status":"ready"}}',
                            '{"number":NaN}', '{"number":Infinity}'):
                path.write_text(content)
                with self.assertRaises(ValueError):
                    catalog.load_json(path)

    def test_cli_is_offline_and_byte_deterministic(self):
        # The socket guard observes actual execution, including imported code.
        with tempfile.TemporaryDirectory() as tmp:
            directory = Path(tmp)
            inputs = directory / "reports"
            inputs.mkdir()
            for identity in reversed(IDENTITIES):
                (inputs / (identity + ".json")).write_text(json.dumps(report(identity)))
            output = directory / "catalog.json"
            argv = ["merge-product-reports.py", "--reports", str(inputs), "--output", str(output)]
            with patch("socket.socket", side_effect=AssertionError("network access forbidden")), patch.object(sys, "argv", argv):
                for _ in range(2):
                    with self.assertRaises(SystemExit) as stopped:
                        runpy.run_path(str(ROOT / "scripts/merge-product-reports.py"), run_name="__main__")
                    self.assertEqual(stopped.exception.code, 0)
                    if output.exists() and _ == 0:
                        before = output.read_bytes()
                self.assertEqual(before, output.read_bytes())

    @unittest.skipUnless(os.environ.get("PRODUCT_REPORTS"), "set PRODUCT_REPORTS for capture validation")
    def test_real_capture_validates_and_has_165_source_delivery_records(self):
        paths = sorted(Path(os.environ["PRODUCT_REPORTS"]).glob("*.json"))
        self.assertEqual(len(paths), 114)
        reports = [json.loads(path.read_text()) for path in paths]
        for item in reports:
            self.assertEqual(catalog.validation_errors(item), [], item["identity"])
        result = catalog.merge_reports(reports)
        self.assertEqual(result["product_count"], 165)
        self.assertNotIn("\\u0000", json.dumps(result))
        self.assertEqual(catalog.merge_reports(result["repositories"]), result)
        self.assertTrue(any(p["kind"] == "application" for r in reports for p in r["products"]))
        self.assertTrue(any("firmware" in p["formats"] for r in reports for p in r["products"]))
        self.assertEqual(result["repositories"][0]["identity"], "AUDIO-001")
        self.assertEqual(result["repositories"][-1]["identity"], "BA-012")


if __name__ == "__main__":
    unittest.main()
