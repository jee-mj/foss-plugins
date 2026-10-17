# Audio export integration and locked nixpkgs reuse

## Export boundary

The free set now contains **32** exports: the previous 20 plus twelve additional
individual Basilica source recipes. The conditional set contains **14** exports:
the previous eleven plus `toneshifteq-windows`, `gunk-windows` and `0xfx-windows`.
Explicit opt-in exposes **46** top-level package attributes. The helper-only
Basilica aggregate is not an additional package export or module selection.

These are new, unpublished working-tree exports; downstream activation is not
established. The 19-free/30-total observations below predate Miserere's registration.
ToneTwist and DrumCloud
remain pending parent review and acceptance even though metadata evaluation and
cached technical checks succeed.

`pkgs/default.nix` receives `reevr`, `wolf-shaper`, and `vaporizer2` through its
top-level function arguments. It exports the supplied derivations directly;
there are no duplicate custom native derivations or overrides. An overlay uses
the consumer's package arguments; the standalone flake uses its own locked input.

## Locked native provenance and observed formats

The input is nixpkgs `fd1462031fdee08f65fd0b4c6b64e22239a77870`
(`nixos-26.05`), NAR hash
`sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=`.

| Export | Locked version / upstream source revision | Observed installed formats |
| --- | --- | --- |
| `reevr` | 1.4.0 / `refs/tags/v1.4.0` | VST3 `REEV-R.vst3`, LV2 `REEV-R.lv2` |
| `wolf-shaper` | 1.0.2 / `refs/tags/v1.0.2` | VST2 `wolf-shaper-vst.so`, LV2, DSSI, standalone |
| `vaporizer2` | 3.5.0-unstable-2024-09-14 / `1c56c4be304255f1c397dad725ea784f15a55ef5` | VST3, LV2, CLAP (`VASTvaporizer2`) |

The upstream recipes are `pkgs/by-name/re/reevr/package.nix`,
`pkgs/by-name/wo/wolf-shaper/package.nix`, and
`pkgs/by-name/va/vaporizer2/package.nix` in that exact nixpkgs revision.
The native Wolf package has neither VST3 nor CLAP. Its legacy VST2 export is
`main`, not `VSTPluginMain`.

The three exact realized outputs are:

```text
/nix/store/3pypkr3xlmkzi69lx83q12x1cja7raxz-reevr-1.4.0
/nix/store/rkw9y0mq9cpp8bx7q8xdqnxzbqc1wnqb-wolf-shaper-1.0.2
/nix/store/lrnydq5s393vgx1mnwmfwa3k37ny3x60-vaporizer2-3.5.0-unstable-2024-09-14
```

All three were substituted sequentially from `https://cache.nixos.org`, with
four cores and one build job configured. Vaporizer2's first download exceeded
the command timeout; the retry completed. No fresh compilation of these native
packages is claimed. No models were acquired, and no GPU execution or source
prefix mutation was performed.

## Native source and Windows artifact exports

InstaWidth builds the reviewed `fcefc76077b7ec8f03d1a52deef475146cf67fd1`
source as VST3/LV2. Sub-Orbit builds
`768bb5b65fd5da637c481f42c002041da24e4d22` as VST3. Their existing checks
inspect installed bundles and runtime resolution, including `dlopen` and symbol
lookup, without opening an audio device or plugin GUI.

The following original Windows builders have **two real outputs**, `out` and `installer`:

| Export | Source revision | Payload |
| --- | --- | --- |
| `wolf-shaper-windows` | `4d7b6a1805d774fad553323bc9325c508428ac9e` (1.0.2 release source) | Wolf Shaper VST3 + CLAP |
| `tonetwist-windows` | `5fac29094050eecf665479921e6ebbd3595b2281` | MetalTone, CollisionDrive, Rumor, TubeScreamer, ValveCaster, BoobTube; six VST3 + six CLAP DLLs |
| `drumcloud-windows` | `294ed7fb3116f1f16c7430e5df7e1954349405c6` | DrumCloud VST3 + CLAP |

`out` contains the manual-copy ZIP, `payload/`, and corresponding source;
`installer` contains the operator-packaged NSIS setup and notices. These are
artifact builders on Linux, not native Linux plugins. There is no `lib` output
or Linux plugin directory to co-install. Installer outputs are selected with
`.#wolf-shaper-windows.installer`, `.#tonetwist-windows.installer`, and
`.#drumcloud-windows.installer`; no additional plugin-product exports are invented.

Wolf is free. ToneTwist preserves mixed-source notices without inventing a
suite-wide `meta.license`; DrumCloud preserves `meta.license = unfree` for its
custom terms. Both use the existing explicit conditional opt-in, as copyright
policy rather than a technical build prohibition. See their package-specific
review documents for details.

## Verification commands and actual results

### Current root integration

The root constructs Miserere once, passes that same recipe object to the family
helper, and merges `basilicaFamily.candidateDefinitions` into the free set. It
exposes `basilicaFamily` on the package-set API for inspection, not as a flake
package. The twelve other `candidateChecks` are merged into root checks; the
existing `basilica-miserere` artifact check wins that single key collision.

Current metadata-only observations:

| Public nixpkgs profile | Audited definitions/check definitions | Verified helper packages/checks | Helper aggregate |
| --- | --- | --- | --- |
| `fd1462031fdee08f65fd0b4c6b64e22239a77870` | 13 / 13 | 13 / 13 | Present |
| `f5c082a40f7571c266e74e80ae2e68aadd8a9fc7` | 13 / 13 | 0 / 0 | Absent |

The alternate profile remains source-audited/stale, not runtime-verified.
The current lock retains all thirteen captured matching receipts; the aggregate
keeps its complete free-license metadata in the helper API only. The README
lists all thirteen individual aliases and public identities.

ToneShiftEQ and Gunk have separate `out`/`installer` outputs. 0xFX has only `out`;
its installer is `installer/0xfx-1.3.0-source-x86_64-setup.exe` within that output.
All three are conditional experimental source-artifact routes, not assertions
of proprietary licensing. Their approved archived recipes remain callable with
their supplied locks; Windows payload execution/host acceptance is not claimed.

New Windows check names are `toneshifteq-windows`,
`gunk-windows-{artifacts,installer,notices,packaging,repack}` and
`0xfx-windows-{archiveLayout,artifacts,installerRepack,recompile,repack}`.
The two attribute-set test APIs are filtered with `lib.isDerivation` before
registration, excluding `callPackage` override helpers. All eleven conditional
checks are absent from pure evaluation.

Verification used Git-filtered CLI evaluation, offline cached target builds with
one job/four cores, and the existing read-only API test interfaces:

```bash
nix eval --offline --no-write-lock-file .#checks.x86_64-linux.free-package-set.drvPath
nix eval --offline --json --no-write-lock-file .#packages.x86_64-linux --apply builtins.attrNames
NIXPKGS_ALLOW_UNFREE=1 nix eval --offline --impure --json --no-write-lock-file \
  .#packages.x86_64-linux --apply 'ps: builtins.length (builtins.attrNames ps)'
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover \
  -s pkgs/basilica-native-suite -p test_api.py -v
PYTHONDONTWRITEBYTECODE=1 python3 pkgs/basilica-native-suite/finalize.py
```

The root count assertion first rejected 20 versus 32, then passed after the
integration. Pure/opted-in counts are 32/46. All **17** family API test methods
passed, including both public source profiles; the finalizer validated all
thirteen original receipts against their actual store proof bytes. Actual
cached NAR hashes were recomputed with `nix hash path` for all sixteen consumed
sources (thirteen products, JUCE, Linear and Stretch), matching the recorded
pins. Read-only profile evaluation retained 13/13 definitions on both public
profiles and 13/0 verified helper packages respectively. No receipt or
source-profile file was rewritten.

Archived ToneShiftEQ and Gunk recipes were evaluated using each delivered
`source/packaging/flake.lock`; both yielded the exact current unsalted package
derivation. The 0xFX source ZIP's `check-archive.py` also passed: an isolated
Git-filtered checkout of archived packaging evaluated its five derivation-only
checks offline with `--no-build`, retaining the lock bytes. This is archived
recipe/API validation, not payload execution or a fresh source compilation.

The thirteen root family checks, free-package-set, package-metadata and eleven
new conditional Windows checks all completed using existing local store outputs
after dry runs showed no build work. In particular, selecting a cached check
named `recompile` does not constitute a new recompilation in this integration.
No heavy source rebuild, model acquisition, runtime acceptance or source-prefix
change was performed. New exports remain unpublished and unactivated.

### Earlier integration evidence (historical counts)

Run from the Git root, using CLI Git autodetection and the existing lock:

```bash
nix eval --no-write-lock-file .#checks.x86_64-linux.free-package-set.drvPath
nix eval --json --no-write-lock-file .#packages.x86_64-linux --apply builtins.attrNames
NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --json --no-write-lock-file \
  .#packages.x86_64-linux --apply 'ps: builtins.length (builtins.attrNames ps)'

# Run these three sequentially.
nix build --no-write-lock-file --no-link --print-out-paths --cores 4 --max-jobs 1 .#reevr
nix build --no-write-lock-file --no-link --print-out-paths --cores 4 --max-jobs 1 .#wolf-shaper
nix build --no-write-lock-file --no-link --print-out-paths --cores 4 --max-jobs 1 .#vaporizer2

nix build --no-write-lock-file --no-link --print-out-paths --cores 4 --max-jobs 1 \
  .#checks.x86_64-linux.free-package-set \
  .#checks.x86_64-linux.package-metadata \
  .#checks.x86_64-linux.nixpkgs-audio \
  .#checks.x86_64-linux.instawidth \
  .#checks.x86_64-linux.sub-orbit \
  .#checks.x86_64-linux.wolf-shaper-windows

nix build --no-write-lock-file --no-link --print-out-paths --cores 4 --max-jobs 1 \
  .#checks.x86_64-linux.audio-catalog \
  .#checks.x86_64-linux.intersect-provider \
  .#checks.x86_64-linux.audio-restoration-vst-provider \
  .#wolf-shaper-windows.installer

NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-write-lock-file --no-link \
  --print-out-paths --cores 4 --max-jobs 1 \
  .#checks.x86_64-linux.tonetwist-windows \
  .#checks.x86_64-linux.drumcloud-windows \
  .#tonetwist-windows.installer .#drumcloud-windows.installer
```

Test-first package-count assertions initially rejected 13 versus 19. They now
pass and also establish exact native derivation reuse and conditional membership.
Pure evaluation lists 19 packages and omits both conditional Windows checks;
opted-in evaluation lists 30 packages. The pure metadata check validates all
free licenses without forcing conditional derivations.

All listed commands completed successfully after the download retry and correction
of the static test's initial VST2 entrypoint expectation. Only the new
`nixpkgs-audio` check was freshly built: it checks free-license metadata, installed
format paths, ELF64/x86-64 headers, defined exported entrypoints and LV2 manifests.
It never loads or executes these three plugins.

The existing InstaWidth, Sub-Orbit, Windows, catalog and CPU-provider checks
reused local store results. This is cached verification, not fresh source
compilation. The Wolf report records strict NSIS destinations, four rejected
extra-parent path mutations and byte-identical independent ZIP/installer repacks
sharing the source compilation. ToneTwist and DrumCloud cached reports likewise
record static PE imports/exports, exact installer payload placement and repack
byte equality. These checks execute no Windows plugin, installer or Wine runtime
and do not resolve their pending review/acceptance.

Windows check results reused:

```text
/nix/store/0pfccxlxw7c67x2pzvvfwb1yaq82n01h-wolf-shaper-windows-artifacts
/nix/store/7yhbg8dsjvj1x1cs4lvh6qyiq2ivkh6m-tonetwist-windows-artifacts
/nix/store/0vkwdpk580xmk1p3c4pl8g63j5c6j102-drumcloud-windows-artifacts
```
