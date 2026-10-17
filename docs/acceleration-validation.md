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
- **16 packaged / 88 catalog-only** repositories, explicitly scoped as
  **12 native-plugin** and **4 windows-artifacts**. Nine native source packages
  (`basilica-miserere`, `basilica-seraph`, `basilica-silentium`,
  `audio-restoration-vst`, `instawidth`, `sub-orbit`, `peakeater`, `intersect`,
  `toneshifteq`) have passed source builds and scoped checks. Three native direct
  re-exports (`reevr`, `wolf-shaper`, `vaporizer2`) passed cache realization and
  static ELF/metadata checks, not fresh source compilation; top-level build stays
  `not-tested` for these three. See [locked reuse evidence](nixpkgs-audio.md).
- AUDIO-001 `drumcloud-windows` and AUDIO-072 `tonetwist-windows` have passed
  Windows source builds and ZIP/NSIS artifact/source/docs checks; final review
  remains pending. Conditional opt-in reflects copyright/maturity, not a technical
  build prohibition. Wolf's additional `wolf-shaper-windows` is a separate
  Windows delivery on the same AUDIO-067 row. Reviewed AUDIO-020 `gunk-windows`
  and AUDIO-040 `0xfx-windows` add two Windows-only repository records;
  `toneshifteq-windows` is additional delivery on native AUDIO-097, not a new row.
  No Windows ZIP establishes native
  Linux installability. All 104 top-level runtime values remain `not-tested`.
- Current exports: **32 free / 14 conditional**, **46 total**. New working-tree definitions
  are unpublished and do not establish downstream activation. The existing
  **98 backend records are preserved**: cache realization of a selected nixpkgs
  version does not promote a captured-HEAD source assessment to built.
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
PRODUCT_REPORTS="$REPORTS" python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 scripts/render-acceleration-matrix.py --write
python3 scripts/render-acceleration-matrix.py --check
```

Set `REPORTS` to the local reviewed 114-report directory explicitly. Temporary
capture paths are operator inputs, not public metadata or canonical publication.

Historical acceleration-campaign results: catalog acceptance **7 tests passed**;
acceleration contract/merge **46 tests passed**; renderer **7 tests passed**;
combined discovery **53 tests passed**. The current metadata integration adds
renderer coverage for delivery scopes and derived fixture counts; current totals
are reported separately below.
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

### Current delivery metadata integration

Current offline validation with the product report capture enabled: Python
discovery passed **82 tests**, with no skips; strict root catalog acceptance
passed **7 tests**. Renderer coverage is **12 tests**, including mixed delivery
scopes, invalid/missing schema-2 scope rejection, legacy schema-1 compatibility and an independent
one-Windows-record fixture (1 packaged / 103 catalog-only), so derived counts
are not hardcoded to the live catalog. Test-first execution rejected the old
4/100 summary and missing Windows scopes before implementation.

Accepted package work reports successful top-level builds/checks for the two
new native source packages and two Windows-only builders. Public reproduction
commands, from the Git root with the existing lock, are:

```sh
nix build --no-link --no-write-lock-file .#instawidth .#sub-orbit \
  .#checks.x86_64-linux.instawidth .#checks.x86_64-linux.sub-orbit
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file \
  .#tonetwist-windows .#drumcloud-windows \
  .#tonetwist-windows.installer .#drumcloud-windows.installer \
  .#checks.x86_64-linux.tonetwist-windows \
  .#checks.x86_64-linux.drumcloud-windows
```

These observed successes are package-work evidence, not another source rebuild
performed by this metadata update. Full immutable source/toolchain pins, hashes,
build history and check boundaries are in [InstaWidth](instawidth.md),
[Sub-Orbit](sub-orbit.md), [ToneTwist](tonetwist-windows.md),
[DrumCloud](drumcloud-windows.md) and the [export integration report](nixpkgs-audio.md).
Final ToneTwist/DrumCloud review is still pending; successful real artifact bytes
do not imply runtime acceptance or publication.

Miserere's reviewed experimental native VST3 source package and artifact check
are now registered as `basilica-miserere` and
`checks.x86_64-linux.basilica-miserere`. Its successful source build and bounded
loader check are recorded in [native evidence](basilica-miserere.md), with
release source `6ce6cc2deb616f337622e36c747a292f505ea0b7` and JUCE 8.0.14
`2cdfca8feb300fb424002ba2c2751569e5bacb64`. Public command portability changes
were evaluated to the same derivation; no new compilation is implied by that
evaluation. Reproduction from the Git root:

```sh
nix build --no-link --no-write-lock-file .#basilica-miserere \
  .#checks.x86_64-linux.basilica-miserere
```

`RTLD_NOW`/factory-symbol lookup, all 16 embedded assets and font/notice checks
passed without invoking the factory; automatic manifest generation was disabled.
This is experimental local Linux delivery, not upstream Linux support or
DAW/audio/GUI acceptance. AGPL/JUCE/OFL evidence remains informational with
consumer judgement required. The separate [Windows MinGW probe](basilica-miserere-windows.md)
failed JUCE's explicit unsupported-compiler guard and produced no artifact or
export. It does not rule out untested MSVC-compatible compiler/ABI and SDK
alternatives. Its failure receipt is
`pkgs/basilica-miserere-windows/verification.json`. Neither that Windows attempt
nor the native build changes the older acceleration source assessment or its
proof boundaries. Current routing totals are **58 native / 14 wine / 4 both /
23 undecided / 5 skip**; all 104 top-level runtime values remain `not-tested`.

### Complete native family and additional Windows artifact evidence

The reviewed [Basilica family](basilica-native-suite.md) supplies thirteen
individual experimental VST3 source recipes: existing Miserere and twelve new
members. All thirteen have matching source-build and bounded loader/assets/
notices evidence on captured nixpkgs
`fd1462031fdee08f65fd0b4c6b64e22239a77870`. Seraph (AUDIO-007 / BA-006) uses
release `d851142d0b64a0a70970dc6f628956b03a3973af`, Silentium (AUDIO-058 /
BA-004) `574fd36431d26c1f572f7c7f9955b82293b669f3`; these differ from the
captured source assessment HEADs. The ten other BA identities stay outside
the root 104. Full source revisions, recursive hashes, dependency pins and
per-profile receipts are in `pkgs/basilica-native-suite/pins.json` and the
linked family report, not inferred from a historical HEAD build.

Nave's approved compatibility change includes `<algorithm>` and replaces
exactly two explicit scalar `juce::jmin<juce::int64>` calls with
`std::min<juce::int64>`, retaining operand types, caps, conversion and guards.
The pinned-JUCE failure reproduction and **14 scalar / 6 clamp cases** passed;
the patch, notice, original/modified hashes and all sixteen declared assets
remain recorded. This does not constitute host/audio/GUI acceptance.

`candidateDefinitions` and `candidateChecks` expose thirteen source-audited
recipes under both public profiles. Alternate nixpkgs
`f5c082a40f7571c266e74e80ae2e68aadd8a9fc7` has **0 verified packages/checks**:
all thirteen current derivations are stale, despite portable source definitions.
Only the captured profile has thirteen matching receipts. The verified aggregate
is a helper-only source recipe, not a top-level export or default module
selection, and is not an instruction to co-install individual duplicates.

Across **114 primary inputs**, **22 repositories** have native package routes
and **26** have any package route. The reviewed temporary report merge derives
**165 source/delivery records**. Neither count means all source-built, installed
or accepted at runtime; nixpkgs realization, plugin products, applications,
format files and source-only leads remain distinct.

The additional reviewed [ToneShiftEQ](toneshifteq-windows.md),
[Gunk](gunk-windows.md) and [0xFX](0xfx-windows.md) Windows builds passed real
source/artifact, exact-path/byte installer, corresponding-source/notice and
independent packaging checks. Their reports distinguish genuine recompilation
from cached check realization. ToneShiftEQ remains GNU Make, not DPF, and
exports Master/Live within the same CLAP/VST3 binaries; no Windows LV2/standalone
is claimed. Gunk's native manifest generation is a build prerequisite, not
Windows factory validation or a native package export. 0xFX builds SDL2 from
source and carries plugin, GUI and console targets; ARM64 remains source-only.
Operator NSIS scripts are not upstream installer definitions, and upstream's
console staging omission is not overwritten as a source fact.

There are now **six Windows builder projects / fourteen source-delivery leads**:
**twelve plugin products plus GUI and console applications**. These are not
fourteen installed products or fourteen binary format files. The current actual
collection remains **three manual ZIPs, three NSIS installers and three source
capsules**, covering **eight plugin products / sixteen DLLs**. New builder
approval does not mean those artifacts or 0xFX applications have been copied.
GUI/console delivery metadata and profile-specific source-only variants describe
collector capabilities, not new collection or runtime receipts. Current recipes
and metadata are unpublished working-tree definitions. No Windows plugin,
installer, GUI/console payload, audio host or Wine prefix is executed by this
metadata validation. All 104 runtime flags and the 98 acceleration backend
records retain their existing boundaries.

### Accepted public experimental variants

The parent reports all three optional aliases and their linked/load checks
passed with `NIXPKGS_ALLOW_UNFREE=1 --impure`. This documentation refresh does not
claim another hardware test; the **53 unit / 7 catalog** totals above describe
the original acceleration campaign.
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
| Miserere experimental native | Release source `6ce6cc2deb616f337622e36c747a292f505ea0b7`; JUCE 8.0.14 `2cdfca8feb300fb424002ba2c2751569e5bacb64` | Source build, VST3 `RTLD_NOW`/factory-symbol and 16 embedded-asset/font/notice checks passed; no factory invocation or automatic manifest generation. Full pins/receipts: [native report](basilica-miserere.md). No host/audio/GUI acceptance; separate Windows MinGW profile blocked. |
| AudioRestorationVST CPU | Source `df7bf68c764095634b45d79f3a40839f0ff39306`, 1.6.35; official Microsoft ORT 1.24.4 CPU archive, ORT revision `2d924974ef147392ced8409d36bd6d2e7fcc8a74` | Source build, VST3 `RTLD_NOW`/factory resolution and GPU-free transitive closure passed. No model session/inference acceptance. |
| AudioRestorationVST CUDA experimental alias | Same plugin source; official ORT 1.24.4 CUDA12 archive; locked CUDA runtime 12.9.79 and cuDNN 9.22.0.52 | Linked build and VST3/core ORT/CUDA EP load passed. EP uses the real host handshake and options serialization; no factory/session/model/device operation or provider execution. |
| INTERSECT CPU | Source `f89e556d074ee46d88717ddfe92a84d3df824879`, 0.17.0; upstream provider project's ORT 1.24.2 CPU archive, ORT revision `058787ceead760166e3c50a0a4cba8a833a6f53f` | Source VST3 build, factory/library load and ORT API/CreateEnv passed; acquisition helpers disabled; no model inference. |
| INTERSECT CUDA12 experimental alias | Same source/provider ORT 1.24.2; locked CUDA runtime 12.9.79, cuDNN 9.22.0.52 | Linked build, VST3/core ORT API/CreateEnv load passed; separate provider DSO dependency/relocation trace exits before initialization. No CUDA provider initialization/execution. CUDA13 is not an implemented recipe choice. |
| INTERSECT MIGraphX experimental alias | Same source/provider ORT 1.24.2; archive references ROCm 7.2.2 layout; recipe selects locked CLR/MIGraphX 7.2.3 | Linked build, VST3/core ORT API/CreateEnv load passed; provider DSO dependency/relocation trace exits before initialization. No MIGraphX provider initialization or device execution; all three AMD hardware stages remain policy-skipped. |
| PeakEater / ToneShiftEQ | Source packages 0.8.2 / 1.3.0 | CPU plugin formats and scoped artifact/entrypoint/library checks; no DAW/audio acceptance. |
| InstaWidth / Sub-Orbit | Source `fcefc76077b7ec8f03d1a52deef475146cf67fd1` / `768bb5b65fd5da637c481f42c002041da24e4d22`; JUCE 8.0.12 `29396c22c93392d6738e021b83196283d6e4d850` | Reviewed source builds, artifact/library checks passed; Sub-Orbit's 47 upstream tests passed. Full hashes/dependencies: [InstaWidth](instawidth.md), [Sub-Orbit](sub-orbit.md). JUCE AGPLv3/commercial and project/font terms remain separate. |
| REEV-R / Wolf Shaper / Vaporizer2 | Locked nixpkgs versions, source recipes and installed formats in [reuse report](nixpkgs-audio.md) | Cache realization and static ELF checks only; no fresh compilation or plugin loading/execution. Overlay follows consumer nixpkgs. Selected release source is not assumed equivalent to captured HEAD; even a matching revision does not turn substitution into source compilation. |
| Windows artifact builders | [Wolf](wolf-shaper-windows.md), [ToneTwist](tonetwist-windows.md), [DrumCloud](drumcloud-windows.md) record full source/toolchain pins | Real source-built VST3/CLAP ZIP and operator NSIS bytes passed scoped checks. ToneTwist/DrumCloud final review pending; no native Linux delivery or Windows/Wine execution acceptance. |

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
