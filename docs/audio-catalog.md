# Audio repository catalog

The machine-readable [audio catalog](../catalog/audio-104.json) makes **all 104
repositories** in the captured [Audio starred list](https://github.com/stars/jee-mj/lists/audio)
discoverable, including Windows-only, source-only, platform-uncertain and
currently unsuitable projects. Its snapshot date is **2026-10-17** and
`schema_version` is `2`.

## What catalog inclusion means

The catalog preserves captured order and stable IDs **AUDIO-001–AUDIO-104**.
These are repository identities, not plugin-product counts: a repository may
contain a suite, an application, a scaffold or several plugin identities.
Future list reordering must not silently reassign the captured IDs.

### Find a plugin or an available package

From a clone's Git root, query the flake metadata without building plugins:

```sh
nix eval --json .#catalog
```

With `jq` available, search by repository/name and print its usage route:

```sh
jq '.entries[] | select(.repository | test("basilica|peakeater"; "i")) |
    {id, repository, proposed_target, distribution, references, copyright}' \
    catalog/audio-104.json

# Only implemented local package exports, not every discovery record:
jq '.entries[] | select(.distribution.status == "packaged") |
    {id, repository, attribute: .distribution.nix_attribute, verification}' \
    catalog/audio-104.json
```

Upstream references and the Windows manifest remain useful on systems without
Nix. No private installer framework is needed to find or acquire upstream files.

These states are distinct:

| State | Meaning |
| --- | --- |
| Cataloged | Metadata and upstream evidence have been recorded. |
| Packaged | A real package definition or independently identified package exists for the relevant source/product. |
| Selected | A consumer configuration names a package; this alone does not establish deployment. |
| Acquired | Actual source or binary bytes have been obtained and their provenance recorded. |
| Built | A particular source/package build has been attempted with a recorded result. |
| Runtime-tested | A specific plugin, host and environment have been exercised with recorded results. |

**104 catalog entries do not mean 104 packaged, acquired or working plugins.**
There are now **16 packaged entries and 88 catalog-only entries**:
**12 native-plugin** repository records and **4 windows-artifacts-only** records.
Every packaged entry explicitly records `distribution.delivery_scope` as
`native-plugin` or `windows-artifacts`. AUDIO-001 `drumcloud-windows`,
AUDIO-020 `gunk-windows`, AUDIO-040 `0xfx-windows` and AUDIO-072
`tonetwist-windows` build Windows ZIP/NSIS artifacts on Linux; these
are not native Linux plugins. AUDIO-067 primarily exports native `wolf-shaper`
and lists `wolf-shaper-windows` in `distribution.additional_attributes` without
creating another repository record. AUDIO-097 similarly retains primary native
`toneshifteq` with additional `toneshifteq-windows`.

The nine local native source packages (the original four, InstaWidth,
Sub-Orbit and experimental Miserere/Seraph/Silentium) and four Windows-only
source builders have `verification.build: "passed"`, with scoped evidence.
The three reused native nixpkgs packages retain
`verification.build: "not-tested"`: cache realization and static ELF/metadata
checks passed, but no fresh compilation of captured HEAD is asserted. The other
88 records also retain build `not-tested`.
**All 104 retain `verification.runtime: "not-tested"`.**

Current exports total **32 free and 14 conditional**, **46 total**; these package totals differ
from repository and product counts. New exports are unpublished working-tree
definitions, not downstream activation. Evidence distinguishes local source
builds, upstream release archives and direct locked nixpkgs reuse. The catalog
itself does not build packages or acquire artifacts.

Release filenames and README/build declarations are upstream evidence.
General catalog release archives have not been inspected; the two ONNX package
reports separately document their specific runtime-archive audits. Platform
labels do not establish complete bundles, dependency compatibility, successful
scanning or working audio.
Standalone applications are not plugin formats, AU is macOS-specific, and a
host's supported format is not necessarily its own delivery format.

## Current technical routing

`initial_proposed_target` preserves the intake decision. `proposed_target`
records the current investigation route, with a reason where it changed.

| Target | Initial count | Current count | Interpretation |
| --- | ---: | ---: | --- |
| `native` | 56 | **58** | Investigate a Linux download or documented Linux source route. |
| `wine` | 13 | **14** | Investigate the Windows plugin route under Wine; compatibility is untested. |
| `both` | 1 | **4** | Compare native source and a Windows fallback. |
| `undecided` | 29 | **23** | Platform, payload, source readiness or delivery evidence remains unresolved. |
| `skip` | 5 | **5** | Retain discovery metadata while preserving the current scope/readiness disposition. |
| **Total** | **104** | **104** | Repository records, not expanded products. |

Six entries changed from `undecided` after separating copyright facts from
technical routing:

- **Wine:** AUDIO-019 Tiptoe, AUDIO-049 WetDiaper, AUDIO-056 AudioVisualiser and
  AUDIO-059 ArSonKuPik. AudioVisualiser is a Windows **source investigation**,
  with no released binary or successful build asserted.
- **Native:** AUDIO-099 AfroVocal-Presets and AUDIO-100 abcTrain. AfroVocal has
  Linux source presets, not a released Linux binary. abcTrain has a Linux
  release with a tag/asset version mismatch and unverified plugin contents.

The remaining 23 `undecided` records stay visible. Examples include unlabelled
binary operating systems, macOS-only evidence, incomplete target matrices and
unestablished source/artifact readiness. `skip` entries also stay visible:
SmoothieVST's public pass-through scaffold, macOS-only purrification and snida,
SolarSynth's unresolved source availability and evaluation terms, and Nota's
DAW/host scope are described rather than hidden.

AUDIO-003 Miserere, AUDIO-007 Seraph and AUDIO-058 Silentium separately moved
from `wine` to `both` after reviewed experimental Linux VST3 release-source
builds. Their initial Wine routes remain preserved.
This is not an upstream Linux-support declaration or DAW acceptance. The tested
Windows MinGW profile failed JUCE's explicit unsupported-compiler guard;
MSVC-compatible compiler/ABI and SDK alternatives remain untested.

## Native, Wine and bridge routes

### Native Linux plugin

Use the entry's upstream README and release references to investigate either a
Linux artifact or a Linux source build. Establish the actual format, CPU
architecture, ABI/runtime requirements and complete bundle layout. A source
support declaration is separate from an available binary, and either remains
separate from a successful build or host test.

### Nine local source-built native package records

| Catalog ID | Package | Version | Local packaged formats | Evidence |
| --- | --- | --- | --- | --- |
| AUDIO-003 | `basilica-miserere` | 0.7.0 | VST3 (experimental Linux) | [Release-source build, bounded loader/assets/notices check](basilica-miserere.md) |
| AUDIO-007 | `basilica-seraph` | 0.4.0 | VST3 (experimental Linux) | [Release pins, Signalsmith and captured profile checks](basilica-native-suite.md) |
| AUDIO-013 | `audio-restoration-vst` | 1.6.35 | VST3 | [CPU source build, official binary ORT and provider boundaries](acceleration/audio-restoration-vst-build.md) |
| AUDIO-047 | `instawidth` | 1.0.0-unstable | VST3, LV2 | [Pinned source/JUCE, artifact and library checks](instawidth.md) |
| AUDIO-050 | `sub-orbit` | 1.0.0-unstable | VST3 | [Pinned source/JUCE/Catch2, 47 upstream tests and artifact checks](sub-orbit.md) |
| AUDIO-058 | `basilica-silentium` | 0.5.0 | VST3 (experimental Linux) | [Release pins and captured profile checks](basilica-native-suite.md) |
| AUDIO-064 | `peakeater` | 0.8.2 | VST3, CLAP, LV2 | [Source build and artifact/dynamic-loading verification](peakeater.md) |
| AUDIO-065 | `intersect` | 0.17.0 | VST3 | [CPU source build, pinned provider runtime and offline adaptation](acceleration/intersect-build.md) |
| AUDIO-097 | `toneshifteq` | 1.3.0 | CLAP, VST3, LV2 | [Source package and scoped artifact test](toneshifteq.md) |

All nine source builds and scoped tests passed as reported by the package work.
Miserere builds release source `6ce6cc2deb616f337622e36c747a292f505ea0b7`
with JUCE 8.0.14 `2cdfca8feb300fb424002ba2c2751569e5bacb64`, independently
of its older captured acceleration source assessment. Its VST3 passed
`RTLD_NOW` loading and factory-symbol lookup, all 16 embedded assets and
font/notice checks. The factory was not called; automatic manifest generation,
plugin copying and instance-creating upstream tests were disabled. Project/JUCE
AGPL and EB Garamond OFL notices are retained; this is not host/audio/GUI acceptance.
InstaWidth uses source `fcefc76077b7ec8f03d1a52deef475146cf67fd1`;
Sub-Orbit uses `768bb5b65fd5da637c481f42c002041da24e4d22`. Both use pinned
JUCE 8.0.12 (`29396c22c93392d6738e021b83196283d6e4d850`), whose actual license
is **AGPLv3 or commercial**, with project/font terms recorded independently.
Sub-Orbit's upstream NOTICE calling JUCE GPLv3 is not the dependency license.
Full dependency commits/hashes and disconnected build procedures are in the
linked package reports.
PeakEater's regression includes **binary `dlopen` with `RTLD_NOW`**, exported
VST3/CLAP/LV2 entrypoints, bundle/metadata checks and dependency resolution.
ToneShiftEQ's scoped test checks plugin binaries, LV2 metadata, immediate
library loading and format entrypoints.
ToneShiftEQ uses native Make, not DPF, and its package omits the upstream
standalone application. The PeakEater package does not ship macOS AU even
though the repository-level catalog records that upstream format.

AudioRestorationVST and INTERSECT compile the plugins from pinned source against
explicitly binary ORT dependencies: official Microsoft CPU ORT 1.24.4 for
AudioRestorationVST and the upstream provider project's CPU ORT 1.24.2 for
INTERSECT. These are not source-built ORT claims or release-plugin substitutions.
Their default CPU builds omit models and GPU dependency closures. Model-free
library load and provider-registration checks do not establish inference.

These checks do not establish DAW scanning, GUI operation, audio processing,
automation, state recall or host compatibility. Runtime remains `not-tested`
for all nine. Their license notices and package metadata are recorded evidence,
not a legal audit; copyright remains `not-audited`.

Run these public CPU package/check commands from the Git checkout root:

```sh
nix build --no-link .#audio-restoration-vst
nix build --no-link .#peakeater
nix build --no-link .#intersect
nix build --no-link .#toneshifteq
nix build --no-link .#basilica-miserere
nix build --no-link .#checks.x86_64-linux.audio-restoration-vst
nix build --no-link .#checks.x86_64-linux.peakeater
nix build --no-link .#checks.x86_64-linux.intersect
nix build --no-link .#checks.x86_64-linux.toneshifteq
nix build --no-link .#checks.x86_64-linux.basilica-miserere
```

The [current validation report](acceleration-validation.md) records exact combined
commands and observed results. Git CLI source autodetection preserves the source
boundary. The [first-batch report](audio-first-batch-verification.md) is historical
evidence for its original two-package scope.

The independent [identity fixture](../tests/audio-catalog-identities.json)
freezes the expected 104 ID-to-repository mappings from the four original
captured intake-page inventories, separately from catalog availability and
verification metadata.

### Thirteen-member Basilica native source family

All thirteen original Basilica members have reviewed experimental Linux VST3
source-build and bounded loader/assets/notices evidence on nixpkgs
`fd1462031fdee08f65fd0b4c6b64e22239a77870`. Only Miserere, Seraph and Silentium
belong to the root 104. The ten supplemental BA identities remain outside it:
BA-001 Overture, BA-002 Tenebrae, BA-003 Nave, BA-005 Requiem, BA-007 Aureate,
BA-008 Firmament, BA-009 Triptych, BA-010 Apotheosis, BA-011 Crypta and BA-012
Lancet. Their stable individual attributes are `basilica-` plus the lowercase
product name. No AUDIO identities are invented for them.

Seraph uses release source `d851142d0b64a0a70970dc6f628956b03a3973af` and
Silentium `574fd36431d26c1f572f7c7f9955b82293b669f3`; neither is its original
captured assessment HEAD. Full recursive hashes, JUCE/Signalsmith inputs and
receipts are in [family evidence](basilica-native-suite.md) and
[`pins.json`](../pkgs/basilica-native-suite/pins.json). AGPL/JUCE, OFL fonts,
Signalsmith MIT and Crypta's analytical CC0 IR notices remain distinct facts.
Nave discloses the exact two-call scalar `std::min` compatibility patch, its
notice and original/modified hashes, plus 14 scalar and 6 clamp cases. These
are source/library checks, not DSP/GUI/host runtime acceptance.

Portable `candidateDefinitions` expose all thirteen recipes and checks on the
captured profile and public alternate
`f5c082a40f7571c266e74e80ae2e68aadd8a9fc7`. The alternate has **zero verified
current builds/checks**: source-audited definitions are not passed receipts.
The aggregate remains a helper-only source recipe, not a top-level package,
module default or recommendation to co-install duplicate members.

Across **114 primary input repositories**, **22** have a native package route
and **26** have any package route. Those totals include nixpkgs reuse and
Windows-only artifacts; they do not mean all source-built or installed. The
canonical [product catalog](../catalog/products.json) now contains **165
source/delivery records**; those rows are not all plugin products. The merged
catalog is present in the working tree, not committed or publicly released.

### Independently identified nixpkgs routes

Three direct local exports reuse supplied nixpkgs derivations without custom
native recipes. The standalone flake uses locked nixpkgs
`fd1462031fdee08f65fd0b4c6b64e22239a77870`; overlays follow consumer nixpkgs:

| ID / local attribute | Locked version / source | Observed installed formats |
| --- | --- | --- |
| AUDIO-066 / `reevr` | 1.4.0 / `refs/tags/v1.4.0` | VST3, LV2 |
| AUDIO-067 / `wolf-shaper` | 1.0.2 / `refs/tags/v1.0.2` | VST2, LV2, DSSI, standalone |
| AUDIO-068 / `vaporizer2` | 3.5.0-unstable-2024-09-14 / `1c56c4be304255f1c397dad725ea784f15a55ef5` | VST3, LV2, CLAP |

All three passed cache realization and static ELF64/entrypoint/LV2 checks; these
checks did not load or execute plugins. No fresh compilation is claimed.
REEV-R and Wolf's selected release sources are not assumed equivalent to captured
HEAD assessments; Vaporizer2's revision matches, but cache substitution still
does not prove a fresh source build. Existing acceleration backend source/proof
records are preserved. Vaporizer2's existing consumer selection is independent
of deployment. Full provenance and observed commands: [reuse report](nixpkgs-audio.md).

Other entries' null `nix_attribute` values mean no usable attribute is asserted
by this catalog; they are not exhaustive findings of package absence.

**AUDIO-081 Hikaru Lumen is related, not an exact source match**, to the
existing `pixelsncodes/lumen` package. The port and original share declared
product/manufacturer/plugin identities and bundle names, but have source and
Lumena-integration differences. The port's bare `Lumen.so` release does not
establish a complete VST3 bundle, architecture, binary equivalence or compatible
replacement. Resolve identity collisions before exposing both variants.

### Windows DAW under Wine

The local Windows builders deliver manual-copy ZIPs and separate operator-authored
NSIS installers: [DrumCloud](drumcloud-windows.md),
[ToneTwist's six effects](tonetwist-windows.md),
[Wolf Shaper](wolf-shaper-windows.md), [ToneShiftEQ](toneshifteq-windows.md),
[Gunk](gunk-windows.md) and [0xFX](0xfx-windows.md). Source builds and artifact/source/docs
checks passed; ToneTwist and DrumCloud final parent review remains pending.
Their conditional copyright/maturity opt-in is not a technical build prohibition.
Windows artifacts imply neither native Linux installability nor Wine/host
acceptance. Wolf and ToneShiftEQ's additional Windows attributes do not create
extra repository rows or change the **16/88** split.

The six builder projects cover **14 source/delivery leads: 12 plugin products
plus 0xFX GUI and console applications**. ToneShiftEQ Master/Live share each
CLAP/VST3 binary; applications and format files are not extra plugin products.
Gunk uses a native manifest prerequisite; that does not publish a native package
or validate its Windows factory. 0xFX uses source-built SDL2; its ARM64 source
route remains unbuilt. Upstream installer definitions and source-only staging
remain distinct from the operator's new NSIS and console staging.

Builder approval is separate from collection. The current collected subset is
**3 manual ZIPs / 3 NSIS installers / 3 source capsules**, covering **8 plugin
products / 16 DLLs**. The three new builders and 0xFX applications have not been
asserted copied. Collector metadata can describe GUI/console delivery and
profile-specific source-only variants without treating them as plugin binaries
or build/runtime proof. Nothing here asserts a six-project collection.

Miserere's [Windows MinGW probe](basilica-miserere-windows.md) is separately
blocked at JUCE 8.0.14's unsupported-compiler guard. No Windows plugin, ZIP or
installer was produced and no Windows export is registered. Successful native
VST3 checks do not promote that Windows profile, while one failed MinGW profile
does not rule out appropriately provisioned MSVC-compatible compiler/SDK routes.

A Windows DAW running in a Wine environment can be investigated as a host for
Windows plugins in that same environment. Use official Windows artifacts or an
appropriate Windows source build, preserve complete bundles/resources, and
check the payload architecture and runtime dependencies. Installation may be
manual-copy or installer-based; a ZIP is not automatically portable.

The [Windows acquisition manifest](windows-plugin-acquisition.md) preserves a
finite **24-candidate** research batch. It is an acquisition reference, not an
installer or a declaration that those plugins work under Wine.

### Native Linux host with a Windows-plugin bridge

A native Linux DAW requires an appropriate Windows-plugin bridge for Windows
plugins. This is a distinct route with its own bridge, Wine, architecture,
format and host requirements. Success in a Windows DAW under Wine does not
establish bridged Linux-host support, or the reverse. No project-specific CLI
or runtime wrapper is required to interpret this documentation.

For any route, future runtime evidence should identify the plugin version,
host, environment and result for scanning, GUI, audio/MIDI routing, sidechain
where relevant, latency, automation and project save/reopen. Acquisition and
build success alone do not establish those results.

## Copyright evidence and consumer judgement

Under the user policy for this catalog, **missing or unclear license evidence
is informational, not an automatic technical implementation gate**. Every
entry records `copyright.implementation_gate: false`,
`consumer_judgement_required: true` and `review_status: "not-audited"`.
Consumers are encouraged to examine the linked evidence and exercise their
own judgement about use, modification and distribution.

Unknown is not a permissive grant, and catalog inclusion grants no rights.
Keep explicit facts visible: DrumCloud has custom release-use permission;
SolarSynth has private non-commercial evaluation restrictions; abcTrain
restricts redistribution and commercial source reuse; ArSonKuPik has a
proprietary EULA and activation terms. These facts are not erased by a
technical route or by an unfree/conditional package classification.

**AI status never implies copyright-free code, models, samples or outputs.**
AI-assisted development and AI processing do not create a copyright exemption.
Models, firmware, IRs, samples, SDKs and other dependencies can have terms
separate from the repository license. VDX7 specifically requires a legally
obtained user-supplied original DX7 Mk I v1.8 ROM; firmware is not included in
the acquisition manifest.

## Aliases and acquisition scope

Only these Basilica aliases occur in the 104 captured records:

| Catalog ID | Basilica alias | Repository |
| --- | --- | --- |
| AUDIO-003 | BA-013 | `basilica-audio/Miserere` |
| AUDIO-007 | BA-006 | `basilica-audio/Seraph` |
| AUDIO-058 | BA-004 | `basilica-audio/Silentium` |

The Windows manifest includes the original 13 Basilica products and the
original 14 Wine/both catalog proposals, deduplicating these three aliases:
**13 + 14 − 3 = 24**. Ten Basilica products in that manifest are outside the
captured 104; they are not additional AUDIO records. The six updated routing
decisions do not silently expand that dated acquisition batch. Follow the
catalog's references for those newly routed leads; their Windows acquisition
metadata has not been added to the finite manifest.

The catalog and both guides preserve research evidence dated 2026-10-17.
Mutable releases and upstream documentation may change; any later acquisition
or packaging should record the exact revision/artifact and observed result.

## Executed full-set acceleration assessment and limitations

The [acceleration design](specs/2026-10-17-catalog-acceleration.md) and
[execution plan](plans/2026-10-17-full-catalog-acceleration.md) cover all 104
entries in one coordinated campaign, including optional NVIDIA and AMD routes.
The additive schema-2 migration and full-set source assessment are executed:
**99 complete, 5 blocked-evidence, zero pending**. Completion describes assessment
coverage, not implementation of every plugin or GPU backend. The generated
[acceleration matrix](acceleration-matrix.md) derives AI-role counts from the
catalog, lists all 104 canonical identities and all 98 component/backend records,
and links source evidence, rights notes and next actions. These records include
non-neural DSP and unsupported/port-required routes; 98 is not a neural-plugin count.

AMD hardware execution is deliberately not part of that campaign. An AMD package
may have build evidence while its hardware validation remains `not-run-policy`.
Three conditional **experimental** aliases are now accepted:
`audio-restoration-vst-cuda`, `intersect-cuda12` and `intersect-migraphx`.
Their linked builds and scoped load checks passed through the public aliases,
matching the reviewed derivations/outputs. Of the 98 backend records, **5 are
packaged: 2 CPU and 3 optional GPU routes**; repository counts are **16 packaged
and 88 catalog-only**, split into twelve native-plugin and four Windows-only records.
New delivery metadata does not promote the 98 older backend assessments.
Pure CPU evaluation remains lazy and GPU-independent.

The aliases require per-command `NIXPKGS_ALLOW_UNFREE=1` and `--impure`. For
MIGraphX this existing conditional gate expresses experimental-support opt-in,
not a finding that AMD/MIGraphX is unfree. CUDA dependency terms remain separate.
**Choose exactly one variant per product**: CPU/CUDA restoration variants share
one plugin identity; CPU/CUDA12/MIGraphX INTERSECT variants share another. Do not
co-install variants of the same product.

Follow the [validation report's protected-dependency gates and public commands](acceleration-validation.md)
before optional builds. The tested cache-only procedure avoided model-bearing
ONNX/MIGraphX source acquisition; an unrestricted cold-source build has no
model-free guarantee. Earlier deferred/unpublished statements in the source-build
reports are historical and superseded by their appended linked-build and public
registration results. Build/load acceptance does not establish provider/device
execution: INTERSECT checks VST3/core ORT/CreateEnv plus provider DSO tracing
before initialization; restoration CUDA checks EP loading via host handshake and
options serialization without factory/session/device operations.

The [OBSIDIAN server feasibility report](acceleration/obsidian-server-packaging.md)
explains why its GPU-only startup, unresolved dependencies and model acquisition
prevent a working CPU-offline server claim. Plugin-local CPU ONNX support does
not establish CPU support for that server.

No model was acquired, and no model/provider execution or DAW/audio/GUI acceptance
was performed. Models and drivers remain user-owned; no automatic model download,
driver activation or custom Wine/installer framework is needed for catalog use or
native package discovery. Upstream-supported CPU routes remain default. The
executed plan does not make every AI label a CUDA/ROCm dependency or establish
unsupported GPU paths. See [validation](acceleration-validation.md) for stage
boundaries and remaining work.
