"""Contract and offline CLI regressions; all success subjects are synthetic."""

import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

from lib.catalog_acceleration import validation_errors


ROOT = Path(__file__).resolve().parents[1]
FIXTURES = ROOT / "tests/fixtures/acceleration"


def fixture(name="intersect-amd"):
    return json.loads((FIXTURES / f"{name}.json").read_text())


def pending():
    return dict(assessment="pending", ai_role="unknown", execution_mode="unknown",
                components=[], backends=[], evidence=[], blocked_reason=None,
                next_action="Inspect pinned source.")


def blocked():
    return dict(pending(), assessment="blocked-evidence", blocked_reason="Pinned source unavailable.")


class AccelerationContractTests(unittest.TestCase):
    def test_experimental_amd_with_policy_skipped_hardware_is_valid(self):
        self.assertEqual(validation_errors(fixture()), [])

    def test_build_pass_does_not_authorize_provider_execution_pass(self):
        entry = fixture()
        entry["acceleration"]["backends"][0]["validation"]["provider_execution"] = "passed"
        self.assertIn("AMD hardware execution is outside campaign policy", validation_errors(entry))

    def test_missing_acceleration_does_not_look_assessed(self):
        self.assertIn("missing acceleration", validation_errors({"id": "AUDIO-001"}))

    def test_completed_conclusion_requires_source_evidence(self):
        entry = fixture()
        entry["acceleration"]["evidence"] = []
        self.assertIn("completed assessment requires evidence", validation_errors(entry))

    def test_pending_is_allowed_for_migration_but_not_final_acceptance(self):
        entry = fixture()
        entry["acceleration"].update(assessment="pending", ai_role="unknown")
        self.assertEqual(validation_errors(entry), [])
        self.assertIn("pending assessment AUDIO-065", validation_errors(entry, require_assessed=True))

    def test_blocked_unknown_is_a_final_outcome(self):
        self.assertEqual(validation_errors({"id": "AUDIO-001", "acceleration": blocked()}, require_assessed=True), [])
        for field in ("blocked_reason", "next_action"):
            entry = {"id": "AUDIO-001", "acceleration": blocked()}
            entry["acceleration"][field] = ""
            self.assertTrue(validation_errors(entry))

    def test_every_required_field_is_checked(self):
        for name in ("intersect-amd", "cpu-build"):
            original = fixture(name)
            a = original["acceleration"]
            b = a["backends"][0]
            records = [a, a["components"][0], a["evidence"][0], b, b["validation"]]
            if name == "cpu-build":
                records += [b["runtime_pins"][0], b["evidence"][0], b["evidence"][0]["subject"], b["evidence"][0]["subject"]["environment"]]
            for record in records:
                for key in list(record):
                    value = record.pop(key)
                    with self.subTest(fixture=name, field=key):
                        self.assertTrue(validation_errors(original), key)
                    record[key] = value

    def test_enums_and_malformed_values_never_raise(self):
        for value in (None, True, 12, [], {}, "", "invalid"):
            self.assertTrue(validation_errors(value))
            entry = fixture()
            entry["acceleration"] = value
            self.assertTrue(validation_errors(entry))
        entry = fixture()
        a = entry["acceleration"]
        b = a["backends"][0]
        fields = [(a, k) for k in ("assessment", "ai_role", "execution_mode", "components", "backends", "evidence")]
        fields += [(b, k) for k in ("platform", "vendor", "upstream_status", "integration_status", "cpu_fallback", "runtime_pins", "model_refs", "evidence", "validation")]
        fields += [(b["validation"], "build"), (a["components"][0], "kind"), (a["evidence"][0], "kind"), (a["evidence"][0], "stage")]
        for record, key in fields:
            old = record[key]
            for value in (None, True, 12, {}, "invalid"):
                record[key] = value
                with self.subTest(field=key, value=value):
                    errors = validation_errors(entry)
                    self.assertTrue(errors)
                    self.assertEqual(errors, validation_errors(entry))
            record[key] = old

    def test_duplicate_and_undefined_component_and_backend(self):
        for mutation in ("component", "backend", "undefined"):
            entry = fixture()
            a = entry["acceleration"]
            if mutation == "undefined":
                a["backends"][0]["component"] = "missing"
            else:
                key = "components" if mutation == "component" else "backends"
                a[key].append(copy.deepcopy(a[key][0]))
            self.assertTrue(validation_errors(entry), mutation)

    def test_missing_policy_reason_and_amd_hardware_failures_rejected(self):
        entry = fixture()
        entry["acceleration"]["backends"][0]["validation"]["reason"] = None
        self.assertTrue(validation_errors(entry))
        for stage in ("model_execution", "provider_execution", "host"):
            for status in ("passed", "failed", "not-run", "not-applicable"):
                entry = fixture()
                entry["acceleration"]["backends"][0]["validation"][stage] = status
                self.assertTrue(validation_errors(entry))

    def test_role_component_consistency_and_distinct_hip_dsp(self):
        for role in ("none", "training-only", "external-service", "mixed", "unknown"):
            entry = fixture()
            entry["acceleration"]["ai_role"] = role
            self.assertTrue(validation_errors(entry), role)
        entry = fixture()
        a = entry["acceleration"]
        a["ai_role"] = "none"
        a["components"][0]["kind"] = "non-neural-dsp"
        a["backends"][0]["provider"] = "hip-dsp"
        self.assertEqual(validation_errors(entry), [])
        a["components"][0]["kind"] = "application"
        a["backends"] = []
        self.assertTrue(validation_errors(entry))  # none with no GPU DSP uses not-applicable
        a["execution_mode"] = "not-applicable"
        self.assertEqual(validation_errors(entry), [])

    def test_legacy_rocm_and_migraphx_are_distinct_routes(self):
        entry = fixture()
        b = copy.deepcopy(entry["acceleration"]["backends"][0])
        b["provider"] = "onnxruntime-rocm-legacy"
        entry["acceleration"]["backends"].append(b)
        self.assertEqual(validation_errors(entry), [])

    def test_synthetic_cpu_build_subject_is_valid(self):
        self.assertEqual(validation_errors(fixture("cpu-build")), [])

    def test_store_artifact_rejects_traversal_bad_hashes_and_unsafe_components(self):
        base = "/nix/store/" + "0" * 32 + "-output"
        invalid = [base + suffix for suffix in (
            "/../../../../etc/passwd", "/.", "/..", "/lib/../output.so",
            "/lib//output.so", "/", "/lib/", "/lib/%2e%2e/output.so",
            "/lib/file\\unsafe", "/lib/file\x7funsafe", "/lib/file\x00unsafe", "/lib/file\x85unsafe",
            "/lib/%2fetc/passwd", "/lib/%5cprivate", "/lib/%00file",
        )]
        invalid += ["/nix/store/" + char * 32 + "-output" for char in "eotuAE"]
        invalid += ["/nix/store/" + "0" * size + "-output" for size in (31, 33)]
        invalid += ["/nix/store/" + "0" * 32 + "-" + name for name in (
            "", ".", "..", ".hidden", "bad@name", "bad:name", "bad%name",
        )]
        for artifact in invalid:
            entry = fixture("cpu-build")
            entry["acceleration"]["backends"][0]["evidence"][0]["subject"]["artifact"] = artifact
            with self.subTest(artifact=artifact):
                self.assertTrue(validation_errors(entry))

    def test_safe_store_artifacts_and_digests_remain_valid(self):
        base = "/nix/store/0123456789abcdfghijklmnpqrsvwxyz-output-1.0+gpu_out?x=y"
        for artifact in (base, base + "/lib/plugin.so", base + "/share/.metadata",
                         base + "/lib/plugin@2.so", base + "/lib/plugin:2.so",
                         base + "/share/model weights.bin",
                         "sha256:" + "a" * 64, "sha256-" + "A" * 43 + "="):
            entry = fixture("cpu-build")
            entry["acceleration"]["backends"][0]["evidence"][0]["subject"]["artifact"] = artifact
            with self.subTest(artifact=artifact):
                self.assertEqual(validation_errors(entry), [])

    def test_store_suffix_filenames_are_public_but_cannot_traverse(self):
        base = "/nix/store/" + "0" * 32 + "-output"
        for suffix in ("/lib/plugin@2.so", "/lib/plugin:2.so", "/share/model weights.bin"):
            entry = fixture("cpu-build")
            artifact = base + suffix
            entry["acceleration"]["backends"][0]["evidence"][0]["subject"]["artifact"] = artifact
            entry["acceleration"]["next_action"] = f"Check artifact {artifact}."
            with self.subTest(suffix=suffix):
                self.assertEqual(validation_errors(entry), [])
        for suffix in ("/lib/../plugin@2.so", "/lib//plugin@2.so", "/lib/./plugin@2.so", "/lib/%2e%2e/plugin@2.so"):
            entry = fixture("cpu-build")
            entry["acceleration"]["backends"][0]["evidence"][0]["subject"]["artifact"] = base + suffix
            with self.subTest(suffix=suffix):
                self.assertTrue(validation_errors(entry))

    def test_rejected_success_fixture_cases(self):
        for case in json.loads((FIXTURES / "rejected-success.json").read_text()):
            entry = fixture(case["base"])
            backend = entry["acceleration"]["backends"][0]
            for path, value in case["changes"].items():
                parts = path.split(".")
                target = backend
                for part in parts[:-1]:
                    target = target[int(part)] if isinstance(target, list) else target[part]
                target[parts[-1]] = value
            with self.subTest(case=case["name"]):
                self.assertTrue(validation_errors(entry))

    def test_private_paths_and_credentials_are_not_published_as_notes(self):
        for value in ("User model at /home/alice/secret.onnx", "See /Users/alice/private", "C:\\Users\\alice\\model.onnx", "Use ~/private/model.onnx", "https://user:password@example.com/model"):
            entry = fixture("cpu-build")
            entry["acceleration"]["backends"][0]["runtime_pins"][0]["note"] = value
            with self.subTest(value=value):
                self.assertTrue(validation_errors(entry))

    def test_private_absolute_paths_cover_mounts_alternative_homes_and_custom_roots(self):
        for value in ("User model /mnt/private/alice/model.onnx",
                      "User model /media/alice/disk/model.onnx",
                      "User model /var/home/alice/model.onnx",
                      "User model /srv/private/alice/model.onnx",
                      "User model /custom-volume/alice/model.onnx",
                      "User model /secret.onnx", "Model=/mnt/private/model.onnx",
                      "Model (/media/alice/model.onnx)",
                      "Model %2fmnt%2fprivate%2falice%2fmodel.onnx"):
            entry = fixture("cpu-build")
            entry["acceleration"]["next_action"] = value
            with self.subTest(value=value):
                self.assertTrue(validation_errors(entry))

    def test_public_paths_urls_and_api_names_are_not_private_filesystem_paths(self):
        artifact = "/nix/store/" + "0" * 32 + "-output/lib/plugin.so"
        for value in (artifact, f"Check artifact {artifact}.",
                      "Inspect https://github.com/example/project/blob/" + "1" * 40 + "/source/main.cpp",
                      "Inspect https://example.com/source/mnt/private/model.onnx",
                      "Inspect https://example.com/source/model%20name.onnx",
                      "Inspect torch.cuda/torch.version.hip and Ort::Session APIs.",
                      "Check CUDA/cuDNN and ONNX/Runtime API requirements.",
                      "See docs/acceleration/source.md and tests/fixtures/acceleration."):
            entry = fixture("cpu-build")
            entry["acceleration"]["next_action"] = value
            with self.subTest(value=value):
                self.assertEqual(validation_errors(entry), [])
        entry = fixture()
        entry["acceleration"]["evidence"][0]["reference"] = "https://github.com/example/project/blob/" + "1" * 40 + "/source/model.cpp"
        self.assertEqual(validation_errors(entry), [])

    def test_documented_gpu_device_paths_are_public(self):
        for device in ("/dev/dri/renderD128", "/dev/dri/renderD129", "/dev/nvidia0",
                       "/dev/nvidia12", "/dev/nvidiactl", "/dev/nvidia-uvm"):
            entry = fixture("cpu-build")
            entry["acceleration"]["next_action"] = f"GPU device {device}"
            with self.subTest(device=device):
                self.assertEqual(validation_errors(entry), [])

    def test_msvc_arch_switches_are_options_not_private_paths(self):
        for option in ("/arch:AVX2", "/arch:AVX", "/arch:SSE2", "/arch:AVX512"):
            entry = fixture()
            entry["acceleration"]["evidence"][0]["summary"] = f"MSVC uses {option} compiler option; this is not GPU execution."
            with self.subTest(option=option): self.assertEqual(validation_errors(entry), [])
        for path in ("/arch:AVX2/private/model.onnx", "/arch:unknown", "/mnt/private/model.onnx", "/var/home/alice/model.onnx"):
            entry = fixture()
            entry["acceleration"]["next_action"] = f"Inspect {path}"
            with self.subTest(path=path): self.assertTrue(validation_errors(entry))

    def test_root_relative_api_endpoint_documentation_is_not_a_private_file(self):
        entry = fixture()
        entry["acceleration"]["evidence"][0]["summary"] = "Release client POSTs to configured /process endpoint; server package/provider is separate."
        self.assertEqual(validation_errors(entry), [])
        for text in ("User model /process", "User model /mnt/private/model.onnx",
                     "Configured /mnt/private/model.onnx endpoint", "Configured /../private endpoint"):
            entry["acceleration"]["evidence"][0]["summary"] = text
            with self.subTest(text=text): self.assertTrue(validation_errors(entry))

    def test_device_exceptions_do_not_allow_other_paths_or_traversal(self):
        for path in ("/dev/private/alice/model.onnx", "/dev/shm/alice/model.onnx",
                     "/dev/dri/private", "/dev/dri/renderD128/../private",
                     "/dev/dri/renderD128/private", "/dev/dri/renderDabc",
                     "/dev/nvidia0/private", "/dev/nvidiactl/../private",
                     "/dev/nvidia-uvm/private", "/dev/nvidia-private",
                     "/mnt/private/alice/model.onnx", "/var/home/alice/model.onnx",
                     "/media/alice/model.onnx"):
            entry = fixture("cpu-build")
            entry["acceleration"]["next_action"] = f"User model {path}"
            with self.subTest(path=path):
                self.assertTrue(validation_errors(entry))

    def test_bare_artifact_names_and_bad_public_urls_rejected(self):
        for artifact in ("plugin.so", "built-output", "/tmp/output", "sha256:not-a-digest"):
            entry = fixture("cpu-build")
            entry["acceleration"]["backends"][0]["evidence"][0]["subject"]["artifact"] = artifact
            self.assertTrue(validation_errors(entry))
        for ref in ("https://bad host.example/file", "https://%6cocalhost/private", "https://[::1]/private", "https://127.0.0.1/x", "https://example.com?token=secret", "docs/%2e%2e/private.md", "//server/private", "https://.invalid/file"):
            entry = fixture()
            entry["acceleration"]["evidence"][0]["reference"] = ref
            with self.subTest(reference=ref): self.assertTrue(validation_errors(entry))

    def test_leaf_type_mutations_are_total_and_deterministic(self):
        entry = self.execution_entry()

        def walk(value):
            if isinstance(value, dict):
                for key in list(value):
                    old = value[key]
                    for replacement in ([], {}, True, 7, None):
                        value[key] = replacement
                        errors = validation_errors(entry)
                        self.assertIsInstance(errors, list)
                        self.assertEqual(errors, validation_errors(entry))
                    value[key] = old
                    walk(old)
            elif isinstance(value, list):
                for child in value: walk(child)

        walk(entry["acceleration"])

    def test_models_require_every_typed_field_and_known_enums(self):
        entry = self.execution_entry()
        model = entry["acceleration"]["backends"][0]["model_refs"][0]
        for key in list(model):
            value = model.pop(key)
            self.assertTrue(validation_errors(entry), key)
            model[key] = value
        for key in ("source_kind", "acquisition"):
            value = model[key]
            for invalid in ([], {}, True, "invalid"):
                model[key] = invalid
                self.assertTrue(validation_errors(entry))
            model[key] = value

    def test_all_documented_completed_roles_have_valid_component_examples(self):
        cases = (("none", ["application"], "not-applicable"),
                 ("training-only", ["training"], "background-job"),
                 ("external-service", ["external-inference"], "external-service"),
                 ("mixed", ["training", "neural-inference"], "mixed"))
        for role, kinds, mode in cases:
            entry = fixture()
            a = entry["acceleration"]
            a.update(ai_role=role, execution_mode=mode, backends=[])
            a["components"] = [{"id": str(i), "summary": "Synthetic component", "kind": kind} for i, kind in enumerate(kinds)]
            with self.subTest(role=role): self.assertEqual(validation_errors(entry), [])

    def test_verification_must_match_stage_source_runtime_artifact_environment(self):
        mutations = {
            "upstream-only": lambda b, e, s: e.update(kind="upstream"),
            "wrong-stage": lambda b, e, s: e.update(stage="load"),
            "wrong-source": lambda b, e, s: s.update(source_revision="2" * 40),
            "contradictory-evidence-revision": lambda b, e, s: e.update(revision="2" * 40),
            "wrong-runtime": lambda b, e, s: s.update(runtime_id="other"),
            "wrong-package": lambda b, e, s: s.update(package_attribute="other"),
            "missing-artifact": lambda b, e, s: s.update(artifact=None),
            "wrong-architecture": lambda b, e, s: s["environment"].update(architecture="aarch64"),
            "windows-for-wine": lambda b, e, s: b.update(platform="wine"),
        }
        for name, mutate in mutations.items():
            entry = fixture("cpu-build")
            b = entry["acceleration"]["backends"][0]
            e = b["evidence"][0]
            mutate(b, e, e["subject"])
            with self.subTest(case=name):
                self.assertTrue(validation_errors(entry))

    def test_failed_build_may_have_attempt_without_artifact(self):
        entry = fixture("cpu-build")
        b = entry["acceleration"]["backends"][0]
        b["validation"]["build"] = "failed"
        b["evidence"][0]["subject"].update(artifact=None, attempt="synthetic exact input derivation")
        self.assertEqual(validation_errors(entry), [])
        b["evidence"][0]["subject"]["attempt"] = None
        self.assertTrue(validation_errors(entry))

    def test_typed_pins_models_and_public_references(self):
        entry = fixture("cpu-build")
        b = entry["acceleration"]["backends"][0]
        for key, value in (("hash", None), ("version", None)):
            old = b["runtime_pins"][0][key]
            b["runtime_pins"][0][key] = value
            self.assertTrue(validation_errors(entry))
            b["runtime_pins"][0][key] = old
        for ref in ("http://github.com/a/b", "/home/user/private", "../private", "file:///tmp/x", "https://user:secret@github.com/a", "https:///missing", "C:\\private\\model", "https://localhost/private"):
            entry = fixture()
            entry["acceleration"]["evidence"][0]["reference"] = ref
            with self.subTest(reference=ref):
                self.assertTrue(validation_errors(entry))
        for value in (None, True, "model", {}, [None]):
            entry = fixture()
            entry["acceleration"]["backends"][0]["model_refs"] = [value]
            self.assertTrue(validation_errors(entry))

    def test_packaged_runtime_pins_may_be_recorded_in_cited_recipe(self):
        for reference in ("pkgs/synthetic/default.nix", "https://github.com/example/upstream/blob/main/package.nix"):
            entry = fixture("cpu-build")
            b = entry["acceleration"]["backends"][0]
            b["runtime_pins"] = []
            b["evidence"].append({"kind": "upstream", "reference": reference,
                                  "revision": None, "stage": "assessment",
                                  "summary": "Synthetic package recipe records the framework version and fetched artifact hash."})
            with self.subTest(reference=reference):
                self.assertEqual(validation_errors(entry), [])

    def execution_entry(self):
        entry = fixture("cpu-build")
        b = entry["acceleration"]["backends"][0]
        b["vendor"] = "nvidia"
        b["provider"] = "onnxruntime-cuda"
        b["validation"].update(build="not-run", provider_execution="passed")
        b["model_refs"] = [{"id": "model", "source_kind": "manual", "source_url": None, "revision": None, "sha256": "a" * 64, "bytes": 1, "license_evidence": "Synthetic terms.", "acquisition": "acquired"}]
        e = b["evidence"][0]
        e["stage"] = "provider_execution"
        e["subject"].update(model_id="model", model_sha256="a" * 64)
        e["subject"]["environment"].update(gpu_vendor="nvidia", gpu_model="synthetic", driver="synthetic")
        return entry

    def test_model_and_gpu_execution_require_exact_acquired_bytes_and_vendor(self):
        self.assertEqual(validation_errors(self.execution_entry()), [])
        for change in ("model-hash", "not-acquired", "model-id", "multi", "unknown", "driver", "gpu-vendor", "model-bytes", "duplicate-model"):
            entry = self.execution_entry()
            b = entry["acceleration"]["backends"][0]
            s = b["evidence"][0]["subject"]
            if change == "model-hash": s["model_sha256"] = "b" * 64
            elif change == "not-acquired": b["model_refs"][0]["acquisition"] = "authorized"
            elif change == "model-id": s["model_id"] = "missing"
            elif change in ("multi", "unknown"): b["vendor"] = change
            elif change == "driver": s["environment"]["driver"] = None
            elif change == "gpu-vendor": s["environment"]["gpu_vendor"] = "amd"
            elif change == "model-bytes": b["model_refs"][0]["bytes"] = True
            else: b["model_refs"].append(copy.deepcopy(b["model_refs"][0]))
            with self.subTest(case=change): self.assertTrue(validation_errors(entry))


class MergeTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.catalog = json.loads((ROOT / "catalog/audio-104.json").read_text())
        self.input = self.root / "catalog.json"
        self.input.write_text(json.dumps(self.catalog))
        self.reports = self.root / "reports"
        self.reports.mkdir()
        self.output = self.root / "output.json"
        for entry in self.catalog["entries"]:
            (self.reports / f'{entry["id"]}.json').write_text(json.dumps({"id": entry["id"], "acceleration": pending()}))

    def cli(self, script, *args):
        env = dict(os.environ)
        env.pop("PYTHONPATH", None)
        return subprocess.run([sys.executable, str(ROOT / script), *map(str, args)], cwd=self.root, env=env, capture_output=True, text=True)

    def merge(self, output=None):
        return self.cli("scripts/merge-acceleration.py", "--catalog", self.input, "--reports", self.reports, "--output", output or self.output)

    def assert_rejected_without_clobber(self):
        self.output.write_bytes(b"existing destination\n")
        result = self.merge()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.output.read_bytes(), b"existing destination\n")
        self.assertNotIn("Traceback", result.stderr)
        return result

    def test_missing_report_cannot_create_or_clobber_output(self):
        (self.reports / "AUDIO-104.json").unlink()
        result = self.merge()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("AUDIO-104", result.stderr)
        self.assertFalse(self.output.exists())
        self.assert_rejected_without_clobber()

    def test_duplicate_report_rejected(self):
        (self.reports / "duplicate.json").write_bytes((self.reports / "AUDIO-001.json").read_bytes())
        self.assertIn("duplicate", self.assert_rejected_without_clobber().stderr.lower())

    def test_extra_and_malformed_reports_rejected(self):
        for data in ({"id": "AUDIO-999", "acceleration": pending()}, [], {"id": "AUDIO-001", "acceleration": {}}, {"id": "AUDIO-001", "repository": "evil/replacement", "acceleration": pending()}):
            (self.reports / "bad.json").write_text(json.dumps(data))
            self.assert_rejected_without_clobber()

    def test_duplicate_json_keys_and_invalid_json_rejected(self):
        for text in ('{"id":"AUDIO-001","id":"AUDIO-002","acceleration":{}}', '{not json', 'null'):
            (self.reports / "bad.json").write_text(text)
            self.assert_rejected_without_clobber()

    def test_atomic_replace_failure_preserves_destination_and_cleans_temporary(self):
        spec = importlib.util.spec_from_file_location("merge_acceleration", ROOT / "scripts/merge-acceleration.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        self.output.write_bytes(b"original bytes")
        with patch.object(module.os, "replace", side_effect=OSError("synthetic replace failure")):
            with self.assertRaisesRegex(OSError, "synthetic replace failure"):
                module.merge(self.input, self.reports, self.output)
        self.assertEqual(self.output.read_bytes(), b"original bytes")
        self.assertFalse(list(self.root.glob(".merge-acceleration-*.tmp")))

    def test_original_identity_mutation_and_duplicate_catalog_rejected(self):
        self.catalog["entries"][0]["repository"] = "evil/replacement"
        self.input.write_text(json.dumps(self.catalog))
        self.assertIn("identity", self.assert_rejected_without_clobber().stderr.lower())
        self.catalog["entries"][0] = self.catalog["entries"][1]
        self.input.write_text(json.dumps(self.catalog))
        self.assert_rejected_without_clobber()

    def test_deterministic_join_preserves_every_existing_field(self):
        result = self.merge()
        self.assertEqual(result.returncode, 0, result.stderr)
        first = self.output.read_bytes()
        merged = json.loads(first)
        self.assertEqual(merged["schema_version"], 2)
        self.assertEqual([e["id"] for e in merged["entries"]], [f"AUDIO-{i:03}" for i in range(1, 105)])
        for original, entry in zip(self.catalog["entries"], merged["entries"]):
            self.assertEqual({k: v for k, v in entry.items() if k != "acceleration"}, {k: v for k, v in original.items() if k != "acceleration"})
        for i, path in enumerate(sorted(self.reports.glob("*.json"))):
            path.rename(self.reports / f"shuffled-{104-i:03}.json")
        self.catalog["entries"].reverse()
        self.input.write_text(json.dumps(self.catalog))
        result = self.merge()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(first, self.output.read_bytes())

    def test_in_place_merge_and_intervening_change_guard(self):
        result = self.merge(self.input)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(self.input.read_text())["schema_version"], 2)
        spec = importlib.util.spec_from_file_location("merge_acceleration", ROOT / "scripts/merge-acceleration.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        original = self.input.read_bytes()
        real_fsync = os.fsync

        def intervening_write(fd):
            real_fsync(fd)
            self.input.write_bytes(original + b" \n")

        with patch.object(module.os, "fsync", side_effect=intervening_write):
            with self.assertRaisesRegex(ValueError, "changed"):
                module.merge(self.input, self.reports, self.input)
        self.assertEqual(self.input.read_bytes(), original + b" \n")
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ["catalog.json", "reports"])

    def test_final_cli_gate_accepts_blocked_and_names_any_pending(self):
        self.catalog["schema_version"] = 2
        for entry in self.catalog["entries"]:
            entry["acceleration"] = blocked()
        self.input.write_text(json.dumps(self.catalog))
        identities = ROOT / "tests/audio-catalog-identities.json"
        result = self.cli("tests/audio-catalog.py", self.input, identities, "--require-assessed")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.catalog["entries"][52]["acceleration"] = pending()
        self.input.write_text(json.dumps(self.catalog))
        result = self.cli("tests/audio-catalog.py", self.input, identities, "--require-assessed")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("pending assessment AUDIO-053", result.stderr)
        result = self.cli("tests/audio-catalog.py", self.input, identities)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_schema1_baseline_runs_but_cannot_pass_final_gate(self):
        self.catalog["schema_version"] = 1
        for entry in self.catalog["entries"]:
            entry.pop("acceleration", None)
        self.input.write_text(json.dumps(self.catalog))
        result = self.cli("tests/audio-catalog.py", self.input)
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.cli("tests/audio-catalog.py", self.input, "--require-assessed")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing acceleration", result.stderr)

    def test_final_cli_requires_schema2_even_when_all_entries_assessed(self):
        self.catalog["schema_version"] = 1
        for entry in self.catalog["entries"]:
            entry["acceleration"] = blocked()
        self.input.write_text(json.dumps(self.catalog))
        result = self.cli("tests/audio-catalog.py", self.input)
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.cli("tests/audio-catalog.py", self.input, "--require-assessed")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("final acceptance requires schema_version 2", result.stderr)

    def test_cli_schema_version_is_an_integer_not_bool_or_float(self):
        for version in (True, False, 1.0, 2.0, "2", None):
            self.catalog["schema_version"] = version
            for entry in self.catalog["entries"]:
                entry["acceleration"] = blocked()
            self.input.write_text(json.dumps(self.catalog))
            for args in ((), ("--require-assessed",)):
                result = self.cli("tests/audio-catalog.py", self.input, *args)
                with self.subTest(version=version, args=args):
                    self.assertNotEqual(result.returncode, 0)

    def test_legacy_regression_is_independent_of_a_migrated_root_catalog(self):
        migrated = copy.deepcopy(self.catalog)
        migrated["schema_version"] = 2
        for entry in migrated["entries"]:
            entry["acceleration"] = blocked()
        self.catalog = migrated
        self.input.write_text(json.dumps(self.catalog))
        self.test_schema1_baseline_runs_but_cannot_pass_final_gate()


if __name__ == "__main__":
    unittest.main()
