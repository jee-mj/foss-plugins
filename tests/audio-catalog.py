"""Validate portable discovery metadata; never fetch or execute upstream code."""

import argparse
import json
from pathlib import Path
import sys
import unittest
from urllib.parse import urlparse

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.catalog_acceleration import validation_errors


PARSER = argparse.ArgumentParser(description=__doc__)
PARSER.add_argument("catalog", nargs="?", type=Path,
                    default=Path(__file__).resolve().parents[1] / "catalog/audio-104.json")
PARSER.add_argument("identities", nargs="?", type=Path,
                    default=Path(__file__).resolve().parent / "audio-catalog-identities.json")
PARSER.add_argument("--require-assessed", action="store_true",
                    help="require a complete or explained blocked assessment for every entry")
ARGS, UNITTEST_ARGS = PARSER.parse_known_args()
CATALOG, IDENTITIES = ARGS.catalog, ARGS.identities


class AudioCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads(CATALOG.read_text())
        cls.entries = cls.catalog["entries"]

    def test_snapshot_identity_and_complete_order(self):
        self.assertIs(type(self.catalog["schema_version"]), int)
        # Ordinary validation retains legacy compatibility; final acceptance is v2.
        self.assertIn(self.catalog["schema_version"], (1, 2))
        if ARGS.require_assessed:
            self.assertEqual(self.catalog["schema_version"], 2,
                             "final acceptance requires schema_version 2")
        self.assertEqual(
            self.catalog["source_url"],
            "https://github.com/stars/jee-mj/lists/audio",
        )
        self.assertEqual(
            [entry["id"] for entry in self.entries],
            [f"AUDIO-{position:03d}" for position in range(1, 105)],
        )
        self.assertEqual(len({e["repository"].lower() for e in self.entries}), 104)

    def test_stable_ids_keep_original_repository_identity(self):
        # Independent capture fixture: catches swaps that preserve count/uniqueness.
        self.assertEqual(
            {entry["id"]: entry["repository"] for entry in self.entries},
            json.loads(IDENTITIES.read_text()),
        )

    def test_portable_references_and_required_evidence(self):
        required = {
            "id", "repository", "upstream_url", "summary", "kind",
            "initial_proposed_target", "proposed_target", "platform_evidence",
            "formats", "references", "distribution", "verification",
            "copyright", "aliases",
        }
        for entry in self.entries:
            with self.subTest(entry=entry["id"]):
                self.assertTrue(required <= entry.keys())
                self.assertEqual(entry["upstream_url"], f'https://github.com/{entry["repository"]}')
                self.assertEqual(len(entry["repository"].split("/")), 2)
                self.assertTrue(entry["summary"])
                self.assertTrue(entry["distribution"]["route"])
                self.assertTrue(entry["references"])
                for url in [entry["upstream_url"], *entry["references"]]:
                    parsed = urlparse(url)
                    self.assertEqual(parsed.scheme, "https")
                    self.assertTrue(parsed.netloc)
                self.assertNotIn("/home/kalki", json.dumps(entry))
                self.assertIsInstance(entry["formats"], list)
                for field in ("released", "documented_source"):
                    self.assertTrue(entry["platform_evidence"][field])

    def test_routing_and_copyright_are_separate(self):
        targets = {"native", "wine", "both", "undecided", "skip"}
        for entry in self.entries:
            with self.subTest(entry=entry["id"]):
                self.assertIn(entry["proposed_target"], targets)
                self.assertIn(entry["initial_proposed_target"], targets)
                if entry["proposed_target"] != entry["initial_proposed_target"]:
                    self.assertTrue(entry["target_change_reason"])
                rights = entry["copyright"]
                self.assertTrue(rights["license_evidence"])
                self.assertIn(rights["review_status"], {"not-audited", "reviewed"})
                self.assertIsInstance(rights["concerns"], list)
                self.assertIs(rights["implementation_gate"], False)
                self.assertIs(rights["consumer_judgement_required"], True)

    def test_availability_is_not_confused_with_runtime_success(self):
        for entry in self.entries:
            with self.subTest(entry=entry["id"]):
                distribution = entry["distribution"]
                self.assertIn(distribution["status"], {"catalog-only", "packaged"})
                self.assertTrue("nix_attribute" in distribution)
                self.assertIn(entry["verification"]["build"], {"not-tested", "passed", "failed"})
                self.assertIn(entry["verification"]["runtime"], {"not-tested", "passed", "failed"})
                # Any future success claim must include evidence, not just a flag.
                if "passed" in entry["verification"].values():
                    self.assertTrue(entry["verification"].get("evidence"))
                if distribution["status"] == "packaged":
                    self.assertTrue(distribution["nix_attribute"])

    def test_basilica_aliases_do_not_create_duplicate_records(self):
        self.assertEqual(
            {e["id"]: e["aliases"] for e in self.entries if e["aliases"]},
            {"AUDIO-003": ["BA-013"], "AUDIO-007": ["BA-006"], "AUDIO-058": ["BA-004"]},
        )

    def test_acceleration_contract(self):
        for entry in self.entries:
            if self.catalog["schema_version"] == 2 or ARGS.require_assessed or "acceleration" in entry:
                with self.subTest(entry=entry["id"]):
                    self.assertEqual(validation_errors(entry, require_assessed=ARGS.require_assessed), [])


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0], *UNITTEST_ARGS])
