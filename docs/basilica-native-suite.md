# Basilica native Linux source recipes (experimental)

This source-recipe API accounts for the original thirteen Basilica products.
Linux support is experimental and locally tested, not upstream official CI
support. The only requested format is x86-64 Linux VST3. No GUI/audio instances
or factory calls are used during verification; host acceptance is not tested.

## Scope and source provenance

`pkgs/basilica-native-suite/pins.json` records full Git commits and recursive
NAR SHA-256 hashes of the twelve official release sources and Seraph's two
Signalsmith dependencies. Versions match `windows-plugin-acquisition.md` and
`catalog/products.json`. `research.json` records the official GitHub source
license texts and CMake graph inspected before fetching source archives.
Annotated release tags were dereferenced through the official GitHub API.
No branch or floating tag is used by the recipes.

Miserere (BA-013 / AUDIO-003) reuses the existing reviewed source recipe at
`6ce6cc2deb616f337622e36c747a292f505ea0b7`, version 0.7.0. Its existing output
is `/nix/store/415izqbh7cjcaki676h2nh33kygn5pn3-basilica-miserere-0.7.0`.
There is no second Miserere source variant in this suite.
Silentium is BA-004 / AUDIO-058 and Seraph is BA-006 / AUDIO-007.
The ten supplemental BA identities have no AUDIO aliases.

## Asset and license review, before fetch

The twelve release sources declare AGPL-3.0. The source-tree review found:

* Silentium, Seraph, Firmament, Triptych, Apotheosis and Crypta bundle EB
  Garamond Regular/SemiBold with `resources/fonts/OFL-EBGaramond.txt` (OFL-1.1).
* Crypta bundles four ordinary mono PCM WAV impulse responses, each 12,332
  bytes. `resources/irs/LICENSES.md` identifies their analytical filter/tap
  generator and explicitly dedicates them under CC0-1.0, with complete legal
  code in `resources/irs/CC0-1.0.txt`. These are not learned neural weights.
* Aureate's committed WAV is a test render; Firmament's 543-byte `.bin` is a
  versioned state test fixture. Neither is an external asset dependency.
* Overture, Nave, Silentium and Apotheosis also contain committed PNG GUI
  filmstrips under the repository AGPL grant, up to 17,532,617 bytes. These are
  retained source GUI resources, not external downloads. `asset-audit.json`
  records their exact Git blob identities and the reviewed state fixture.
* Seraph uses Signalsmith Linear 0.3.1 and Stretch's exact upstream development
  commit, under MIT. Its portable C++ FFT path and source guards are retained.
  Stretch's `cmd/util` gitlink is used only by its separate command-line tool;
  the plugin's upstream download-only header graph does not build or fetch it.
* JUCE 8.0.14 uses the reviewed pinned source and AGPL route. Third-party
  vendored notices are retained, including notices embedded in source files.

`notices.py` installs full notice files and copyright-bearing text source files
without extracting/truncating their license blocks, preserving upstream paths.
Factory IR provenance and font notices are included. No NN models, firmware,
user content, external fonts or external IR packs are downloaded. Unexpected
external assets or unpinned provisioning must block a product rather than
silently remove functionality. These reviewed sources have no unresolved asset
license gate; any future uncertainty belongs in an explicit conditional profile.

## API and verification

Call `pkgs/basilica-native-suite/default.nix` with `callPackage`. It returns
`candidateDefinitions`, `candidateChecks`, `namedPackages`, `checks`, and all
thirteen `profiles`. A full verified `aggregate` exists
only when all thirteen current source profiles have matching captured checks,
including reused Miserere. Stale/not-tested products remain visible in profiles
without package exports; historical `passed` labels do not establish eligibility.
The caller can supply the existing `basilica-miserere`, `juceRuntime`, and
`pluginArtifacts`; defaults use their existing repository recipes via callPackage.
Shared package/flake/catalog integration is owned by the parent change.
Parent module integration merges the individual `candidateDefinitions` as
portable experimental source recipes. The aggregate remains an internal
source-recipe/verification output with complete free-license metadata.

### Portable definitions versus profile-specific verification

`candidateDefinitions` exposes the thirteen stable `basilica-*` member names
under any compatible nixpkgs profile whose current package source identities
match the exact inventory and clean source audits. `candidateChecks` exposes
their corresponding independent, current receipt-check definitions with the
same names. Both fields require the product's current source revision/NAR hash,
actual source consistency and every relevant JUCE/Signalsmith audit; an unknown
model source or another unexpected audit item removes affected definitions.
They do **not** require the current consumer derivation to have passed a stored
build receipt. They contain individual members, not the aggregate.

The strict fields `namedPackages`, `checks` and `aggregate` retain their existing
receipt-bound meaning. A different nixpkgs profile can change package/check
derivation identities while preserving the audited source recipes. Such a
profile receives experimental definitions but no historical build-pass claim:
`sourceStatus` is `source-audited`, while `status` and
`currentDerivationStatus` are `stale` (or `not-tested` if no result exists).
On the verified profile, `currentDerivationStatus` is `verified`; Miserere's
existing `reused-reviewed-source-build` status remains explicit.

The [public profile pins](../pkgs/basilica-native-suite/public-nixpkgs-profiles.json)
use only immutable public GitHub commits and NAR hashes. The
[metadata-only test](../pkgs/basilica-native-suite/source_profiles.py) imports
those public sources with `nix eval --offline`, disables import-from-derivation,
and performs no builds or receipt refresh. Its
[review receipt](../pkgs/basilica-native-suite/source-profile-verification.json)
records exact candidate/current drv and output identities.

| Public nixpkgs profile | Candidate definitions | Candidate check definitions | Verified packages/checks | Verified aggregate | Current profile status |
| --- | ---: | ---: | ---: | --- | --- |
| `fd1462031fdee08f65fd0b4c6b64e22239a77870` | 13 | 13 | 13 / 13 | Present, same output | Verified; Miserere reused |
| `f5c082a40f7571c266e74e80ae2e68aadd8a9fc7` | 13 | 13 | 0 / 0 | Absent | All thirteen source-audited / stale |

Run this bounded portable-profile review with:

```sh
python3 pkgs/basilica-native-suite/source_profiles.py
```

### Current candidate and evidence binding

`candidates.nix` constructs all packages, original artifact checks and receipt
checks independently of `results.json`, audit decisions and archived proofs.
`inventory.nix` fixes the twelve new product names, BA identities and AUDIO
aliases; exactly those products plus the two pinned Signalsmith dependencies
must occur in `pins.json`. Missing/renamed/extra identities fail closed. Existing
Miserere is the thirteenth member. Completeness never follows a filtered or empty
inventory.

Each current receipt binds source version/full commit/NAR hash/source derivation
and output, package derivation/output, original artifact check derivation/output,
consumed JUCE/Signalsmith sources, recipe/helper/verifier content hashes and
Nave's exact patch/notice/compatibility-check identity. The wrapper check emits
`proof.json` without embedding its own derivation or output identity, avoiding a
self-hash cycle. Individual helper files and stable binding text are used rather
than copying a whole family/root directory into a derivation.

`refresh-proofs.py` builds the independent current checks, copies their exact
receipts into `proofs/<name>.json`, and records the actual current check drv/output
and receipt digest. Eligibility matches every recorded binding and compact
verifier receipt against that archive and the independently constructed current
candidate. Source or recipe/test/verifier changes make historical evidence
`stale`. Changing results/archive files cannot change candidate identities.

These are **unsigned local observations**, not signed attestations. Pure API
evaluation checks the captured bytes without realizing/building a candidate.
`finalize.py` additionally compares archives byte-for-byte with the actual store
check outputs and validates the original artifact-receipt digest. It validates
original source hashes and versions; it never overwrites them from current pins
or promotes/relabels a historical receipt.

All sixteen suite-managed upstream source archives are audited: thirteen products, common
JUCE and Seraph's Linear/Stretch dependencies. Every consumed source needs the
current revision and NAR hash with an empty `unexpected` list. A dependency audit
mismatch blocks its consumers and the aggregate even with a clean product audit.

Before aggregate export, every member must declare free licenses, a description
and the tested platform. Aggregate metadata contains the flattened, deduplicated
union from all thirteen members: AGPL-3.0-only, OFL-1.1, MIT and CC0-1.0, plus
`x86_64-linux` and the experimental local-test description. Individual notices
remain installed with each member.

`adapt.py` generalizes the reviewed Miserere graph adaptation: pinned JUCE,
VST3-only, post-build copying and VST3 auto-manifest disabled, no LTO, and the
unconditional Catch2 instance-test graph omitted. The only source-level exception
is the separately approved Nave scalar-minimum compatibility patch described
below; DSP algorithms, GUI code and guards are retained. Seraph's download-only dependencies become explicit offline source
directories. Remaining provisioning is rejected and Nix builds are sandboxed.

`test_verify.py` first demonstrated failure with the verifier absent, then
passed against the implementation. It rejects both missing and empty bundles.
`tests/basilica-native-suite.nix` repeats these negative controls before checking
the installed nonempty bundle, ELF64 x86-64 headers, factory/module exports,
RTLD_NOW loading, JUCE dlopen libraries, retained embedded fonts/IRs and notices.
It never calls the factory, module entrypoints, GUI or audio processing.

From the Git repository root, after staging the new source files:

```sh
python3 pkgs/basilica-native-suite/test_verify.py
python3 pkgs/basilica-native-suite/audit-source-assets.py
python3 pkgs/basilica-native-suite/refresh-proofs.py
# Make the genuine captured evidence visible through Git filtering.
git add pkgs/basilica-native-suite/proofs pkgs/basilica-native-suite/results.json
python3 pkgs/basilica-native-suite/finalize.py
python3 pkgs/basilica-native-suite/test_api.py
python3 pkgs/basilica-native-suite/verify-api.py
```

The runner constructs `builtins.getFlake` with an explicit `git+file://` URI,
uses `nix build --impure --no-link --no-write-lock-file --json --max-jobs 1
--cores 4 --expr ...`. The bounded source-build runner remains
`build-batch.py`; verification-only refresh uses `refresh-proofs.py` and does not
consume another source-build attempt. Both use one job and at most four cores.
`results.json` contains exact versions, commits, exit codes and output receipts.
No production-selection or Downloads writes are involved.

The official pinned-tree audit (`audit-source-assets.py`) rejects unexpected
weight extensions, unreviewed submodules and unreviewed source blobs above
4 MiB. The reviewed filmstrips are explicitly allowlisted by Git blob identity;
they are not omitted to shrink the plugin. The local daemon configuration used
for this batch has `sandbox = true` and `sandbox-fallback = false`.

## Local build inventory

| Identity | Product | Version | Native VST3 outcome |
| --- | --- | --- | --- |
| BA-001 | Overture | 0.5.0 | Passed |
| BA-002 | Tenebrae | 0.5.0 | Passed |
| BA-003 | Nave | 0.5.0 | Passed with disclosed scalar compatibility patch |
| BA-004 / AUDIO-058 | Silentium | 0.5.0 | Passed |
| BA-005 | Requiem | 0.5.0 | Passed |
| BA-006 / AUDIO-007 | Seraph | 0.4.0 | Passed |
| BA-007 | Aureate | 0.5.0 | Passed |
| BA-008 | Firmament | 0.4.0 | Passed |
| BA-009 | Triptych | 0.6.0 | Passed |
| BA-010 | Apotheosis | 0.6.1 | Passed |
| BA-011 | Crypta | 0.4.1 | Passed |
| BA-012 | Lancet | 0.5.0 | Passed |
| BA-013 / AUDIO-003 | Miserere | 0.7.0 | Reused reviewed source build |

All twelve new native VST3 products plus existing Miserere are available.
The thirteen-product aggregate is exported only after every source profile has
passed and its sandbox checks are satisfied. All thirteen products remain
accounted for in the API profiles; Nave is explicitly marked modified source.

### Nave: confirmed overload failure and minimal compatibility fix

The original Nave build failed at `src/PluginProcessor.cpp:390`; the same
expression also occurs at line 436 in the second IR loader. The complete loader
context was reviewed, including operand types, the signed cap, int conversion
and nonpositive guard. JUCE 8.0.14 defines scalar `jmin(Type,Type)` as
`b < a ? b : a` and also declares a `jmin(SIMDRegister<Type>,SIMDRegister<Type>)`
overload. On this Linux LP64 target, `juce::int64` is `long long`, while
`int64_t` is `long`. JUCE's signed 64-bit SIMD specialization uses `int64_t`.

The standalone `nave-repro.nix` test uses actual pinned JUCE headers, asserts
those type identities and keeps SIMD enabled. The explicit
`jmin<juce::int64>` call fails with the original incomplete
`SIMDNativeOps<long long>` diagnostic; deduced scalar `jmin(a,b)` and explicit
scalar `std::min<juce::int64>` compile. This is a failure while considering the
SIMD overload candidate, not evidence that SIMD was the intended operation.

The approved `nave-scalar-minimum.patch` adds `<algorithm>` and changes just
the two calls to `std::min<juce::int64>`. Operand types, cap, outer conversion,
guards and processing remain identical. It is applied only to Nave. The exact
patch, `NOTICE-Nave.md` and modified `PluginProcessor.cpp` are installed beside
the unchanged upstream notices. `profiles.Nave.modifiedSource` and
`results.json` record the modification, original/modified source hashes and
patch hash; the original failed diagnostic is retained as prior-attempt evidence.

`nave-compatibility.nix` applies the patch with zero fuzz and checks the exact
minimal delta. It compiles both actual patched source expressions and checks
14 signed scalar cases (minimum, maximum, zero, negative values, reversed
operands and ties) against real deduced JUCE scalar `jmin`; six additional cases
exercise the source length clamp. The same scalar arithmetic runs separately
without linking JUCE's module sentinel or creating GUI/audio objects. The
negative original-overload reproduction is a dependency of this check.

Nave's artifact check additionally verifies every one of its sixteen declared
binary assets: ten factory presets, German localization, four GUI PNGs and the
brand icon. The two committed toggle PNGs are not in upstream's Nave target
(its layout has zero toggles); the target and all declared assets are preserved.

Reproducible diagnostic and compatibility check recipes are
`pkgs/basilica-native-suite/nave-repro.nix` and `nave-compatibility.nix`;
invoke them with `callPackage` through the same explicit Git-flake CLI boundary.
The final API verifier builds all thirteen artifact checks and the aggregate
with `--max-jobs 1 --cores 4`.

Attempts are bounded to two per project. The four early successful projects
receive a second pass after the notice-source correction; Nave's original
failed attempt is followed by the confirmed compatibility-patched build. The
remaining projects use the final notice-source recipe on their
first attempt. `checkOutput` now identifies the current bound `proof.json`.
`binding.artifactCheckOutput` identifies the original sandbox artifact receipt,
including complete per-file notice hashes. Compact proofs summarize that notice
manifest by count and digest to avoid duplicating thousands of JUCE entries.

`api-verification.json` records the final successful thirteen-check build and aggregate, exact
package/check output paths and all thirteen profile statuses. The verification
also asserts that each exported new package/check matches its recorded result,
Miserere remains the existing `415iz…` output. Package outputs and underlying
artifact-check outputs are retained; thirteen new receipt-check drv/output pairs
bind them to current recipe/verifier content. All current pairs and accepted
profile statuses are recorded explicitly in `api-verification.json`.

The review first reproduced 42 failures across receipt, consumed-audit, inventory
and aggregate-metadata mutations. The corrected review gate initially passed
fourteen test methods; the portable definition extension brings `test_api.py` to
seventeen. It covers finalizer non-relabeling, missing archives,
results-independent candidate identities, receipt-independent audited definitions,
consumed-source audit mutations and both public nixpkgs profiles. Each mutation
uses `nix eval` only, with no per-case source builds. `api-tests.json` records the
current test outcome. The existing thirteen source receipts are retained, not
re-labelled for the alternate profile.

Final outputs:

* Nave: `/nix/store/15lb99fi646gfh1sjwhcb709ly988naw-basilica-nave-0.5.0`
* Nave artifact/asset/compatibility receipt:
  `/nix/store/7vryayi6jjdi80h6z1l1nb9m8v9k6z4p-basilica-Nave-native-artifacts`
* Nave current bound receipt:
  `/nix/store/mqm4hbrx1g871nv5sr00yrb8zgy0k9va-basilica-Nave-current-proof`
* Full experimental aggregate:
  `/nix/store/15a39z9b6qz4vwmqgf11215kcwk4sp1f-basilica-native-suite-experimental`
* Aggregate derivation:
  `/nix/store/qp6887iginlpf9sq1a099q1571prl2xr-basilica-native-suite-experimental.drv`
