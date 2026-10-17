# Full-Catalog NVIDIA and AMD Acceleration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Assess all 104 catalog repositories and deliver evidence-supported optional NVIDIA/AMD acceleration while keeping technical feasibility, packaging and hardware validation separate.

**Architecture:** Extend the existing JSON catalog additively, collect full-set source-backed assessments in disjoint shards, and let the parent orchestrator integrate shared metadata and exports. Implement native/provider/server work only for real upstream paths; retain unknown, unsupported and port-required outcomes as first-class catalog results.

**Tech Stack:** Nix flakes and existing package helpers; JSON; Python standard-library validation/tests; upstream ONNX Runtime/PyTorch/native DSP backends where actually used.

**Spec:** `docs/specs/2026-10-17-catalog-acceleration.md` — read it before executing any task.

## Execution outcome — 2026-10-17

Full-set assessment/schema/publication work is complete: 104 identities, 99
complete conclusions, five explicit evidence blocks, zero pending assessments.
The catalog is schema 2 with validated per-component/provider evidence and a
generated [full matrix](../acceleration-matrix.md).

Two additional CPU-default source packages and three conditional experimental
GPU alternatives have passed linked builds and scoped library checks. The two
earlier native pilots remain available, yielding four packaged products and
seven campaign package attributes. OBSIDIAN server packaging is explicitly
blocked rather than represented by a nonworking export.

**Hardware/inference acceptance is not complete:** no models were acquired, no
model/provider graph or DAW execution was performed, and AMD hardware stages
remain deliberately `not-run-policy`. Model acquisition requires separate
authorization. The task checklists below retain the original detailed plan;
unexecuted hardware/model steps must not be read as passed. Current commands,
test totals, dependency gates and limitations are in
[acceleration validation](../acceleration-validation.md).

## Global Constraints

- Native package definitions and public catalog metadata belong in `foss-plugins`.
- `.site` owns workstation selection and Wine integration, not duplicate native recipes.
- Preserve exactly 104 stable AUDIO ID-to-repository mappings and the three BA aliases.
- CPU use remains the default where upstream supplies a viable CPU route.
- GPU support is optional, per component, platform, architecture and provider.
- NVIDIA and AMD are both in scope; neither vendor is inferred from an AI label.
- AMD hardware execution is deliberately not performed in this campaign.
- Record AMD hardware validation as `not-run-policy`, never `passed` or `failed`.
- Windows/Wine acceleration is separate from native Windows and native Linux acceleration.
- Missing/unclear license metadata is informational, not a technical implementation gate.
- Record explicit restrictions, model/sample/firmware terms and consumer judgement separately.
- No commits, input updates, model downloads, system activation or driver changes without explicit authorization.
- Never import either entire checkout as an unfiltered raw path Nix source.
- At most 10 concurrent child agents; no recursive delegation.

This is a single full-set campaign with independent deliverables, not an instruction
to run 104 compilers or download all models simultaneously. Do not claim all
packages are implemented when only assessment coverage is complete. Git staging
of legitimate new source for Git-filtered flake visibility is permitted; do not
stage unrelated existing changes. Do not commit as part of this plan.

## Files and ownership

| File / boundary | Responsibility | Writer |
| --- | --- | --- |
| `catalog/audio-104.json` | Version-2 published metadata for all 104 identities | Parent only |
| `tests/audio-catalog-identities.json` | Immutable captured identity fixture | Do not modify |
| `lib/catalog_acceleration.py` | Validate acceleration records, no network/model execution | Parent/schema worker |
| `tests/test_catalog_acceleration.py` | Contract, negative and merge regression tests | Parent/schema worker |
| `tests/fixtures/acceleration/` | Small synthetic records with known expected outcomes | Parent/schema worker |
| `scripts/merge-acceleration.py` | Deterministic all-104 report merge; no partial writes | Parent/schema worker |
| `tests/audio-catalog.py` | Existing schema/version/full-catalog checks | Parent only |
| `flake.nix`, `pkgs/default.nix`, `README.md` | Checks, lazy exports, discovery instructions | Parent only |
| `docs/acceleration/AUDIO-<id>.md` | Pinned source assessment, per-component backend evidence | Assigned shard worker |
| `pkgs/<assigned-name>/`, `tests/<assigned-name>.nix` | One source package/provider/server and artifact checks | Assigned implementation worker |
| `docs/acceleration-matrix.md` | Human-readable full-set conclusions generated from catalog | Parent only |
| `docs/acceleration-validation.md` | Exact commands, framework/driver tuples, results and limitations | Parent only |

Use `/tmp/opencode/foss-plugins-acceleration/<run-id>/` for transient per-ID
`{id, acceleration}` reports. Verify its parent directory before creating files.
The published catalog remains authoritative; temporary reports are not a second
maintained catalog. Preserve cited assessment notes in the public repository.

## Task 1: Validate the acceleration contract before migrating data

**Files:** create `lib/catalog_acceleration.py`, `tests/test_catalog_acceleration.py`,
and `tests/fixtures/acceleration/intersect-amd.json`; modify `tests/audio-catalog.py`.

**Interfaces:** `validation_errors(entry: dict, *, require_assessed: bool = False) -> list[str]` consumes an entry
with the spec's `acceleration` object and returns deterministic diagnostics without
raising for malformed user data. This function does not import Nix or load models.
Fixture contents are the complete backend example in the spec, wrapped in an
`{"id":"AUDIO-065","acceleration": ...}` entry, with `components` containing
`{"id":"stem-separation","summary":"Background stem separation","kind":"neural-inference"}` and one
official upstream assessment evidence record. Use `assessment: "complete"`,
  `ai_role: "inference"`, and `execution_mode: "background-job"` in this fixture.
Use `blocked_reason: null` and `cpu_fallback: "supported"`. Keep null package,
source-revision and runtime-ID fields while it is an unpackaged fixture; it has
no campaign success claims.

- [ ] Add these regression cases before writing `validation_errors`:

```python
import copy
import json
import unittest
from pathlib import Path
from lib.catalog_acceleration import validation_errors


def amd_entry():
    return json.loads(Path("tests/fixtures/acceleration/intersect-amd.json").read_text())


class AccelerationContractTests(unittest.TestCase):
    def test_experimental_amd_with_policy_skipped_hardware_is_valid(self):
        self.assertEqual(validation_errors(amd_entry()), [])

    def test_build_pass_does_not_authorize_provider_execution_pass(self):
        entry = amd_entry()
        backend = entry["acceleration"]["backends"][0]
        backend["validation"]["provider_execution"] = "passed"
        self.assertIn("AMD hardware execution is outside campaign policy", validation_errors(entry))

    def test_missing_acceleration_does_not_look_assessed(self):
        self.assertIn("missing acceleration", validation_errors({"id": "AUDIO-001"}))

    def test_completed_conclusion_requires_source_evidence(self):
        entry = copy.deepcopy(amd_entry())
        entry["acceleration"]["evidence"] = []
        self.assertIn("completed assessment requires evidence", validation_errors(entry))

    def test_pending_is_allowed_for_migration_but_not_final_acceptance(self):
        entry = amd_entry()
        entry["acceleration"].update(assessment="pending", ai_role="unknown")
        self.assertEqual(validation_errors(entry), [])
        self.assertIn("pending assessment AUDIO-065", validation_errors(entry, require_assessed=True))
```

- [ ] Run `python3 -m unittest discover -s tests -p 'test_catalog_acceleration.py' -v`;
  observe failure because the new validator is absent, not a broken fixture path.
- [ ] Implement validation for every spec enum and required field; require unique
  component IDs, defined backend component references, evidence for completed
  conclusions and passed/failed stages, and reasons for policy skips. Reject
  malformed containers, invalid URLs/private paths, duplicate backend tuples and
  unsupported `assessment`/`ai_role` combinations with explicit diagnostics.
- [ ] Add negative tests for each rejection: duplicate backend tuple, undefined
  component, hardware success without execution evidence, missing policy reason,
  and `ai_role:none` with an NN backend incorrectly declared. Allow explicitly
  separate non-neural `hip-dsp` components. An assessment with unknown role and
  `blocked-evidence` is valid if its reason and next action are recorded.
- [ ] Add specific rejected-success fixtures: upstream-only evidence, a matching
  runtime with wrong stage, a matching stage with wrong source/runtime identity,
  model execution without acquired model hash, and native Windows evidence used
  for Wine. A valid synthetic CPU build fixture must cite `kind:verification`
  and a matching artifact/runtime/environment subject; no hardware is used.
- [ ] Run the unit suite and existing `python3 tests/audio-catalog.py` successfully.
  Do not yet raise the existing catalog's required schema version to 2.

**Review gate:** validators can distinguish CPU fallback, upstream support and
actual GPU execution; they do not invent support from provider availability.

**Python import contract:** both direct CLI scripts (`tests/audio-catalog.py`
and `scripts/merge-acceleration.py`) insert their checked-out repository root
before importing `lib.catalog_acceleration`:

```python
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from lib.catalog_acceleration import validation_errors
```

The unit suite runs from the Git root via `python3 -m unittest`; direct CLI
subprocess tests must also work with `PYTHONPATH` unset. Do not rely on the
developer shell's import path.

## Task 2: Make full-set assessment merging deterministic and safe

**Files:** create `scripts/merge-acceleration.py`; extend
`tests/test_catalog_acceleration.py`; synthetic merge inputs stay in test fixtures.

**Interfaces:** the script accepts `--catalog PATH --reports DIR --output PATH`.
Each report is `{id, acceleration}`. Require exactly one report for each captured
ID, reject extra/duplicate/missing IDs, preserve all existing entry fields other
than `acceleration`, and set `schema_version: 2`. Use the identity fixture to
check original and output ID-to-repository mappings. No network or package builds.

- [ ] Write failing subprocess tests using `tempfile.TemporaryDirectory`: generate
  104 pending synthetic reports, omit AUDIO-104 and assert nonzero exit with no
  output modification; add a duplicate AUDIO-001 under another filename and
  assert nonzero; mutate a repository identity and assert rejection.
- [ ] Add a passing-case expectation: merge twice with shuffled report filenames;
  bytes must match, 104 IDs remain ordered, and copyright/verification/distribution
  fields must equal their original values. Pending seed reports are allowed for
  migration but the final campaign acceptance check must reject pending results.
- [ ] Test the final-acceptance API explicitly: all explained `blocked-evidence`
  outcomes are acceptable, while changing any one ID to `pending` fails and names
  that ID. Expose this mode as `tests/audio-catalog.py --require-assessed` using
  argparse, retaining the existing optional catalog and identity-fixture arguments.
- [ ] Run the tests and observe the script-missing failure.
- [ ] Implement argparse, deterministic sorted ID joining, `validation_errors`,
  complete pre-write checks, and an atomic same-directory temporary-file replacement
  of the destination. If updating the input in place, compare its initial bytes
  immediately before replacement and abort on intervening changes. Never overwrite
  copyright or source identities from a worker report.
- [ ] Run all merge/validator tests; demonstrate that a deliberately missing report
  cannot produce a seemingly complete catalog or clobber an existing destination.

**Review gate:** parent can merge untrusted worker report data without partial
writes, identity reassignment or silently lost fields.

## Task 3: Research all 104 entries in the same run

**Files:** workers create only their own `docs/acceleration/AUDIO-<id>.md` files
and corresponding transient reports. Parent owns shared catalog modifications.

**Interfaces:** every report conforms to the spec and Task 2's envelope. Notes
record official URLs, observed commit/release, inspected code/build files,
components, training versus inference, backend/platform/vendor claims, model
provenance, fallback and the next technical action. Findings about licenses go
in notes for parent review; they do not gate technical routing.

| Worker | Assigned IDs, inclusive | Records |
| --- | --- | ---: |
| 1 | AUDIO-001–AUDIO-013 | 13 |
| 2 | AUDIO-014–AUDIO-026 | 13 |
| 3 | AUDIO-027–AUDIO-039 | 13 |
| 4 | AUDIO-040–AUDIO-052 | 13 |
| 5 | AUDIO-053–AUDIO-065 | 13 |
| 6 | AUDIO-066–AUDIO-078 | 13 |
| 7 | AUDIO-079–AUDIO-091 | 13 |
| 8 | AUDIO-092–AUDIO-104 | 13 |

- [ ] Verify both worktrees' `git status` and preserve existing module/package work.
  Create a parent-owned queue with all IDs before dispatching workers.
- [ ] Dispatch eight research workers concurrently, with no recursive delegation.
  Reserve at most two additional agent slots for independent review; never exceed
  10 total active children. Give each worker the spec, exact IDs and file boundary.
- [ ] Inspect actual inference entrypoints, build configuration, runtime installers
  and server components using official upstream APIs (`gh` for GitHub). Record
  current full commits and selected release differences; do not equate a moving
  README's capability with an older pinned binary.
- [ ] For every entry, including the five current `skip` proposals, conclude
  `complete` with evidence or `blocked-evidence` with a concrete limitation. Never
  label an uninspected project CPU-only or non-neural based only on its name.
- [ ] For neural suites, enumerate affected products/components; distinguish CPU,
  CUDA/cuDNN, MIGraphX/legacy ROCm, DirectML/CoreML/MPS, external service and
  training-only references. For ordinary DSP, record no NN inference with source
  evidence; GPU audio DSP may be a separate component.
- [ ] Cross-review each shard's counts, pinned evidence and unsupported claims.
  Return corrections to its owner, not another concurrent writer.
- [ ] Merge the 104 accepted reports using Task 2's script. Update the existing
  catalog version test to 2, add acceleration validation to its per-entry loop,
  and wire `--require-assessed` to `validation_errors(..., require_assessed=True)`.
- [ ] Change the flake metadata check to construct a **narrow** source layout in
  its build directory, rather than interpolating isolated scripts with missing
  imports. Copy only `lib/catalog_acceleration.py`, both catalog test scripts,
  the identity fixture, `tests/fixtures/acceleration/`, `scripts/merge-acceleration.py`
  and `catalog/audio-104.json` into matching relative paths. For example:

```nix
pkgs.runCommand "foss-plugins-audio-catalog" {
  nativeBuildInputs = [ pkgs.python3 ];
} ''
  mkdir -p lib tests/fixtures scripts catalog
  cp ${./lib/catalog_acceleration.py} lib/catalog_acceleration.py
  cp ${./tests/audio-catalog.py} tests/audio-catalog.py
  cp ${./tests/test_catalog_acceleration.py} tests/test_catalog_acceleration.py
  cp ${./tests/audio-catalog-identities.json} tests/audio-catalog-identities.json
  cp -R ${./tests/fixtures/acceleration} tests/fixtures/acceleration
  cp ${./scripts/merge-acceleration.py} scripts/merge-acceleration.py
  cp ${./catalog/audio-104.json} catalog/audio-104.json
  python3 tests/audio-catalog.py
  python3 -m unittest discover -s tests -p 'test_catalog_acceleration.py' -v
  touch "$out"
''
```

Synthetic tests must not depend on private worktree paths, external reports or
unrelated package sources. This check runs the contract and direct CLI merge
regressions on a CPU-only sandbox, with no provider or model downloads.

**Acceptance:** all 104 have an explicit assessment outcome; no pending IDs or
omissions. The original identity fixture, aliases and copyright fields are intact.

## Task 4: Package supported acceleration without forcing GPU closures

**Files:** package workers own only `pkgs/<assigned-name>/`, corresponding
`tests/<assigned-name>.nix`, and `docs/acceleration/<assigned-name>-build.md`.
Parent registers implemented attributes in `pkgs/default.nix` and `flake.nix`.

**Interfaces:** select a base package and explicit provider-specific overrides
only after inspecting that package's upstream API. Catalog `package_attribute`
must name a real exported derivation; absent packages stay null. Preserve existing
`pluginArtifacts`/`juceRuntime` interfaces and conditional-package classification.

- [ ] For each implementation candidate write a package/artifact test first using
  the existing PeakEater/ToneShiftEQ checks as local interface references. Include
  the upstream provider entrypoint/API required by that particular package and
  a headless CPU baseline. Observe an expected missing-package/provider failure.
- [ ] Freeze source, models-as-references and provider tuples before building;
  use live Nix MCP queries for package/options/store questions, then inspect the
  locked input's actual API. Do not update the lock file to obtain a dependency.
- [ ] Prioritize INTERSECT's existing CPU/CUDA/MIGraphX paths; keep its AMD route
  experimental. Reconcile exact ORT/provider ABI and supported GPU architectures.
- [ ] Package AudioRestorationVST's actual CPU/CUDA route. Its ORT 1.17.3 ROCm
  integration is a legacy candidate, not a modern MIGraphX implementation. Record
  a port-required or blocked result if the legacy tuple cannot be maintained;
  keep incomplete HIP spectral DSP separate from NN provider enablement.
- [ ] Treat OBSIDIAN's external server separately from its client. NVIDIA packages
  must preserve supported engine/framework requirements; AMD remains port-required
  until engine-level compatibility is implemented. Do not just substitute a ROCm
  PyTorch wheel into the NVIDIA installer and claim all engines supported.
- [ ] Implement any additional source-backed candidates discovered by the full-set
  research using the same independent package/test boundary. Do not promise that
  all 104 need providers or that every port will succeed.
- [ ] Keep provider evaluation lazy, preserve CPU defaults, and avoid global
  `cudaSupport`, ambient DAW-wide library-path changes or driver setup. Optional
  variants must not be imported/fetched by CPU-only metadata checks.
- [ ] Run source/package and artifact checks with Git CLI flake autodetection from
  the correct root. At most two heavy builds concurrently; initially four cores
  and one Nix job per build. Record failures instead of hiding them behind CPU fallback.
- [ ] Review each package before parent export registration and catalog update.

**Acceptance:** every published attribute exists and has reproducible pinned
inputs and honest evaluation/build/load evidence. AMD hardware stages remain
policy-skipped, even when the package compiles or libraries load on another host.

## Task 5: Validate providers separately from audio and hardware claims

**Files:** create per-implemented-package `tests/<name>-provider.nix` only where
non-hardware checks are meaningful; record execution in `docs/acceleration-validation.md`.
Parent adds hardware-dependent tests as manually invoked checks, not mandatory
flake checks requiring GPUs or model downloads in the sandbox.

- [ ] Before any model download, record its source, terms, byte size, hash and
  resource limits; obtain explicit authorization under the global constraints.
  Models requiring credentials or user-supplied content remain manual references.
- [ ] On this NVIDIA host, record driver/GPU/framework/provider versions before
  attempting permitted hardware tests. Serialize GPU execution and bound VRAM,
  disk use and test duration; never run unreviewed installers or training jobs.
- [ ] For a tested model collect provider/profile evidence that accelerated nodes
  actually executed. Record CPU node placement and output tolerances against CPU;
  provider registration or `get_available_providers()` alone cannot pass this stage.
- [ ] For live audio test 48 kHz and 64/128/256-frame blocks, including warm-up,
  latency, deadline misses and CPU fallback. For background workloads measure
  completion time/VRAM while playback runs. Test GUI/automation/state recall
  separately; do not infer host acceptance from standalone inference.
- [ ] Do not run AMD hardware tests. Set AMD model/provider/host stages to
  `not-run-policy` with an explicit reason; publish reproducible commands and
  hardware prerequisites for consumers to validate independently.
- [ ] Record native Windows DirectML evidence separately from Wine. Mark Wine
  GPU use unknown unless independently exercised; Linux ROCm/CUDA libraries do
  not satisfy Windows provider DLL dependencies by installation alone.

**Acceptance:** catalog evidence matches each actual test stage. No hardware
success claims are inferred from build, library-load or CPU-fallback results.

## Task 6: Publish the full-set matrix and run the final gates

**Files:** update `docs/audio-catalog.md`, `README.md`,
`docs/acceleration-matrix.md`, `docs/acceleration-validation.md`, and the catalog.
Keep private workstation inventory/paths out of public required usage instructions.

- [ ] Generate a matrix row for every one of the 104 IDs, with AI role, component
  routes, NVIDIA/AMD status, package attributes, test stages, rights-note links
  and next action. Empty backend arrays mean no recorded route, not automatic
  hardware incompatibility. Include totals for complete/blocked assessments and
  separately packaged/build-tested/hardware-tested routes.
- [ ] Document public CPU/CUDA/AMD variant build commands only for real exports.
  Explain MIGraphX versus legacy ROCm, native Windows versus Wine, CPU fallback,
  optional servers, model acquisition boundaries and consumer-owned drivers.
- [ ] Run the final validation commands from the Git root:

```sh
python3 tests/audio-catalog.py --require-assessed
python3 -m unittest discover -s tests -p 'test_catalog_acceleration.py' -v
nix build --no-link --no-write-lock-file .#checks.x86_64-linux.audio-catalog
nix flake check --no-build --no-write-lock-file
git diff --check
git diff --cached --check
```

- [ ] Build each newly exported package/check explicitly and record the exact
  command; `--no-build` evaluation does not count as compilation. Separately
  verify pure CPU metadata evaluation does not force provider/model derivations.
- [ ] Exercise the final gate's negative control: run against a temporary copy
  with exactly one assessment set to `pending`; require nonzero exit naming that
  ID. Then run the unchanged published catalog with `--require-assessed` and
  require zero exit. Do not modify the published file for this negative test.
- [ ] Have an independent reviewer compare catalog evidence, matrix totals,
  actual exported attributes and test records. Reject any `pending` assessment,
  any changed identity or alias, and any AMD hardware success claim.
- [ ] Publish a bounded result summary: all-104 assessment coverage, actual
  packages/variants delivered, unresolved ports and evidence blocks, NVIDIA
  execution results if authorized, and deliberately untested AMD hardware routes.

## Planning-time review

Coverage: spec identity/policy/schema → Tasks 1–3; full-set concurrency → Task 3;
native and Windows/provider/server separation → Tasks 3–5; lazy CPU/optional GPU
packaging and version pins → Task 4; honest AMD/NVIDIA validation → Task 5;
public usability, copyright notes, stable denominator and final evidence → Task 6.

Execution order: Tasks 1–2 precede the shared merge. Task 3's eight research shards
run together; validated package work can start after a shard review while the
remaining assessments continue, within the same 10-agent ceiling. Tasks 4–5 run
per accepted component, and Task 6 closes the entire campaign. Native package
work remains disjoint from `.site` activation, which is not authorized here.
