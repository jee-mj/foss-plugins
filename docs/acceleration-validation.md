# Full-catalog acceleration validation

Snapshot: **2026-10-17**, native Linux x86_64. The
[implementation plan](plans/2026-10-17-full-catalog-acceleration.md) has been
executed with the limitations below. Assessment completion is distinct from
package delivery and hardware acceptance. The [generated matrix](acceleration-matrix.md)
is the current per-repository/per-backend view; its authority is the schema-2
[catalog](../catalog/audio-104.json), not temporary worker reports.

## Delivered and verified scope

- All **104** canonical ID-to-repository mappings retain captured identity/order.
- Schema **2**, **99 complete** assessments, **5 blocked-evidence**, **0 pending**.
- **98 backend records** distinguish component, platform, architecture, vendor,
  provider, upstream support, integration, package attribute and six validation
  stages. These are not 98 delivered or exclusively neural GPU implementations.
- **4 packaged / 100 catalog-only** repositories: AUDIO-013
  `audio-restoration-vst`, AUDIO-064 `peakeater`, AUDIO-065 `intersect`, AUDIO-097
  `toneshifteq`. All four source-plugin builds and artifact checks pass.
- The two ONNX source-plugin packages default to CPU and explicitly depend on
  pinned **binary ORT runtimes/headers**; they do not claim to source-build ORT.
  CPU runtime closures exclude GPU stacks and pure CPU evaluation remains lazy.
- **5 packaged backend records: 2 CPU and 3 optional GPU routes**. The conditional
  experimental aliases `intersect-cuda12`, `intersect-migraphx` and
  `audio-restoration-vst-cuda` now have accepted linked-build/scoped-load evidence
  through their public aliases, matching the reviewed derivations/outputs.
  This is packaging/load acceptance, not accelerator execution acceptance.
- No models were acquired by the documented procedure. Protected dependencies
  used cache-only gates to avoid model-bearing source acquisition. This does
  **not** establish an unrestricted cold-source model-free guarantee.

AI-role totals are calculated by the renderer from the root catalog and appear
in the matrix. Conventional DSP, neural inference, external services, training
and evidence-blocked projects retain distinct dispositions. Names containing
“AI”, automatic control and AI-assisted authorship do not establish inference.

## Reproducible commands and observed results

Run from this checkout's **Git root**. Nix CLI Git autodetection preserves the
source boundary; do not substitute a raw checkout path import. No command below
updates inputs, activates a system, starts an audio host or downloads models.

```sh
python3 tests/audio-catalog.py --require-assessed
python3 -m unittest discover -s tests -p 'test_catalog_acceleration.py' -v
python3 -m unittest discover -s tests -p 'test_render_acceleration_matrix.py' -v
python3 scripts/render-acceleration-matrix.py --write
python3 scripts/render-acceleration-matrix.py --check
```

Observed: catalog acceptance **7 tests passed**; acceleration contract/merge
**46 tests passed**; renderer **7 tests passed**. The combined command
`python3 -m unittest discover -s tests -p 'test_*.py' -v` passed **53 tests**.
The renderer's tests first failed with the renderer absent, then passed after
implementation. They verify all 104 rows against the independent identity
fixture, canonical order, summary/package counts, 98 backend rows, per-ID source
links, and identity-drift rejection. Fresh checks preserve bytes and modification
time; stale checks fail with exit **1** without rewriting; missing checks fail
without creating output. Other input/render errors return **2**.

The renderer is Python-standard-library-only and uses the existing local schema
validator. It reads catalog/identity JSON only, without networking, platform
probes, Nix imports or source-audit execution. `--write` is the explicit spelling
of the default write mode. `--check` never writes. `--catalog`, `--identities`
and `--output` permit controlled independent inputs/outputs. It compares exact
UTF-8 bytes and omits timestamps or machine-specific generated metadata.

Public CPU package and artifact/provider-contract checks, rerun successfully
after export integration (exit **0**, cached outputs may be reused):

```sh
nix build --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  .#audio-restoration-vst .#intersect .#peakeater .#toneshifteq \
  .#checks.x86_64-linux.audio-restoration-vst \
  .#checks.x86_64-linux.intersect \
  .#checks.x86_64-linux.peakeater \
  .#checks.x86_64-linux.toneshifteq \
  .#checks.x86_64-linux.audio-restoration-vst-provider \
  .#checks.x86_64-linux.intersect-provider
```

The command emitted the expected dirty-Git-tree warning and exited zero. It
requests four CPU packages, four artifact checks and two provider-contract
checks; it does not request a linked optional GPU build. Detailed worker
commands, output identities, failure history and archive-audit evidence are in
the linked package reports below. The
[first native batch report](audio-first-batch-verification.md) remains the
historical record of its original two-package scope.

### Accepted public experimental variants

The parent reports all three optional aliases and their linked/load checks
passed with `NIXPKGS_ALLOW_UNFREE=1 --impure`. This documentation refresh does not
claim another hardware test or change the reported **53 unit / 7 catalog** totals.
The aliases select the same reviewed/tested derivations and outputs; registration
does not change the validation subject. The source-build reports retain their
earlier deferral history, superseded by appended linked-build/load and public
registration sections.

The conditional gate is process-local. For CUDA it accompanies vendor dependency
terms; for AMD MIGraphX it is an **experimental-support opt-in, not a license
classification**. Pure evaluation continues to expose CPU defaults without
forcing optional GPU dependencies. **Choose exactly one variant per product**:
`intersect`, `intersect-cuda12` and `intersect-migraphx` share one VST3 identity;
`audio-restoration-vst` and `audio-restoration-vst-cuda` share another.

Optional commands below require successful source-graph review and the matching
cache-only protected-dependency gate first. Stop if a gate fails; do not enable
framework source fallback. Use the exact gates and pins documented in the
[INTERSECT acquisition/build addendum](acceleration/intersect-build.md#no-model-source-boundary-before-dependency-realization)
and [restoration acquisition/source gates](acceleration/audio-restoration-vst-build.md#acquisitionsource-gates).
Those gates use `--max-jobs 0`: INTERSECT protects CLR/MIGraphX and CUDA library
outputs; restoration pre-realizes its sparse plugin source, JUCE and binary ORT
input after recursive graph review. ONNX/MIGraphX model-bearing sources were
avoided. The environment opt-in alone does not enforce this acquisition boundary.
No unrestricted cold-source model-free guarantee is claimed.

After the corresponding gate succeeds, public reproduction commands are:

```sh
# INTERSECT CUDA12 alternative and its artifact/core-load checks:
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  .#intersect-cuda12 \
  .#checks.x86_64-linux.intersect-cuda12 \
  .#checks.x86_64-linux.intersect-cuda12-provider

# INTERSECT MIGraphX alternative and its artifact/core-load checks:
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  .#intersect-migraphx \
  .#checks.x86_64-linux.intersect-migraphx \
  .#checks.x86_64-linux.intersect-migraphx-provider

# Restoration CUDA alternative and its linked/library-load check:
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  .#audio-restoration-vst-cuda \
  .#checks.x86_64-linux.audio-restoration-vst-cuda
```

These commands reproduce the parent-reported public acceptance; executing every
line for checks is not an instruction to install multiple variants together.

## Exact runtime and dependency boundaries

| Package / route | Pinned source/runtime | Evidence and present limit |
| --- | --- | --- |
| AudioRestorationVST CPU | Source `df7bf68c764095634b45d79f3a40839f0ff39306`, 1.6.35; official Microsoft ORT 1.24.4 CPU archive, ORT revision `2d924974ef147392ced8409d36bd6d2e7fcc8a74` | Source build, VST3 `RTLD_NOW`/factory resolution and GPU-free transitive closure passed. No model session/inference acceptance. |
| AudioRestorationVST CUDA experimental alias | Same plugin source; official ORT 1.24.4 CUDA12 archive; locked CUDA runtime 12.9.79 and cuDNN 9.22.0.52 | Linked build and VST3/core ORT/CUDA EP load passed. EP uses the real host handshake and options serialization; no factory/session/model/device operation or provider execution. |
| INTERSECT CPU | Source `f89e556d074ee46d88717ddfe92a84d3df824879`, 0.17.0; upstream provider project's ORT 1.24.2 CPU archive, ORT revision `058787ceead760166e3c50a0a4cba8a833a6f53f` | Source VST3 build, factory/library load and ORT API/CreateEnv passed; acquisition helpers disabled; no model inference. |
| INTERSECT CUDA12 experimental alias | Same source/provider ORT 1.24.2; locked CUDA runtime 12.9.79, cuDNN 9.22.0.52 | Linked build, VST3/core ORT API/CreateEnv load passed; separate provider DSO dependency/relocation trace exits before initialization. No CUDA provider initialization/execution. CUDA13 is not an implemented recipe choice. |
| INTERSECT MIGraphX experimental alias | Same source/provider ORT 1.24.2; archive references ROCm 7.2.2 layout; recipe selects locked CLR/MIGraphX 7.2.3 | Linked build, VST3/core ORT API/CreateEnv load passed; provider DSO dependency/relocation trace exits before initialization. No MIGraphX provider initialization or device execution; all three AMD hardware stages remain policy-skipped. |
| PeakEater / ToneShiftEQ | Source packages 0.8.2 / 1.3.0 | CPU plugin formats and scoped artifact/entrypoint/library checks; no DAW/audio acceptance. |

The locked nixpkgs revision for these reports is
`fd1462031fdee08f65fd0b4c6b64e22239a77870`. Full archive hashes, JUCE/submodule
pins, runtime IDs, artifacts, provider registration semantics and dependency
versions are recorded in
[AudioRestorationVST build evidence](acceleration/audio-restoration-vst-build.md),
[INTERSECT build evidence](acceleration/intersect-build.md),
[PeakEater evidence](peakeater.md) and [ToneShiftEQ evidence](toneshifteq.md).
Those exact runtime tuples must not be replaced with a current package-index
version and treated as the same validation subject.

**Driver/device tuple: none tested.** No NVIDIA or AMD driver version, GPU model,
device support, graph-node placement or driver/runtime compatibility is accepted
by these checks. Dependency sonames, declared compute capabilities and archive
RUNPATHs establish investigation inputs, not device compatibility. Native Linux,
native Windows, macOS and Wine outcomes remain distinct in the matrix.

## Hardware, models and host acceptance

`evaluation`, `build` and `load` are independent stages. Model-free `dlopen` and
factory symbol resolution do not instantiate a full processor/model session.
`model_execution`, `provider_execution` and `host` need their own matching
evidence; a source branch, upstream CI configuration or failed CUDA registration
cannot promote any of these to passed.

- **Models acquired: none.** No model execution occurred on CPU, NVIDIA or AMD.
  Model URLs/hashes in assessment notes are provenance leads, not acquired bytes.
- **NVIDIA hardware/provider execution: none.** Linked build and scoped load
  acceptance do not establish successful model-session provider registration or
  GPU placement. Restoration's CPU-side EP host handshake/options serialization
  does not create a CUDA factory/session or perform device operations.
- **All AMD hardware stages are `not-run-policy`**, including model execution,
  provider execution and host acceptance. AMD linked builds/core loads and
  pre-initialization DSO tracing never count as hardware execution. Legacy ROCm,
  MIGraphX, HIP DSP and DirectML remain distinct routes.
- **Provider execution and host/audio tests: none.** All 104 top-level runtime
  fields remain `not-tested`. DAW scanning, GUI, audio/MIDI, automation, sidechain,
  latency, state recall and save/reopen remain unvalidated.

Models and drivers remain user-owned. Native package discovery/builds do not
require a custom Wine or installer framework. Model acquisition is explicit and
separate; package builds/launch integration must not silently fetch models or
activate drivers. Copyright/terms remain informational technical metadata,
with consumer judgement required; AI labels imply no exemption for code,
models, samples, firmware or outputs.

## Blocked server and next steps

[OBSIDIAN server feasibility](acceleration/obsidian-server-packaging.md) is
**blocked for a working CPU-offline server**. Its pinned startup requires a GPU,
its default SA3 path can acquire resources, and its dependency/model closure is
not immutable/complete. The plugin's separate local CPU ONNX route is not server
CPU support. No invented `--cpu`, `--offline` or `--no-download` flag is accepted
as a solution, and no server package, startup, offline generation or hardware
result is claimed.

Per-ID next actions and evidence links are generated in the matrix. Optional
linked builds and bounded load checks are now accepted; broader provider
initialization and inference acceptance remain separate. Any later inference acceptance requires
explicit model provenance/terms, exact acquired bytes and runtime/device/driver
identity. Host acceptance follows as an independent step. AMD hardware execution
remains excluded by the current campaign policy.
