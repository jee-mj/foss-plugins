# Basilica Miserere: experimental native Linux source route

## Result (2026-10-17)

**Miserere v0.7.0 built locally as an x86-64 Linux VST3 from its exact release
source and JUCE 8.0.14.** The sandbox artifact check passed. This establishes an
experimental native route through this repository, not upstream Linux support,
DAW acceptance, or tested audio/GUI behavior.

The [Windows spike](basilica-miserere-windows.md) encountered JUCE's explicit
MinGW rejection. That evidence is Windows-toolchain-specific; it does not imply
that Linux source builds are unsupported or that Linux requires Wine.

## Full immutable pins

| Input | Revision | Unpacked NAR hash |
| --- | --- | --- |
| `basilica-audio/Miserere` v0.7.0 | `6ce6cc2deb616f337622e36c747a292f505ea0b7` | `sha256-gzAKD2fO8DzPaFRBVOYq7Apj7haEBgrTl0qsUzTJXME=` |
| `juce-framework/JUCE` 8.0.14 | `2cdfca8feb300fb424002ba2c2751569e5bacb64` | `sha256-oXFYfFqySW2XtM1e5/ifxAp9qSIVLzY1WAUKE3EscoQ=` |
| nixpkgs (`flake.lock`) | `fd1462031fdee08f65fd0b4c6b64e22239a77870` | `sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=` |

Miserere's annotated tag object is
`db9a91bcd2095f69fd4a2d7708f8105aff17976a`; the recipe fetches the release
commit, not the tag object. Target: `x86_64-linux`, GCC 15.2.0, Release build,
one Nix job and four cores.

## Recipe and formats

`pkgs/basilica-miserere/default.nix` uses the existing `juceRuntime` and
`pluginArtifacts` helpers, following the PeakEater/audio-restoration patterns.
Its only installed plugin format is VST3:

```text
lib/vst3/Miserere.vst3/Contents/x86_64-linux/Miserere.so
```

`adapt.py` modifies only the top-level CMake graph:

- Replace CPM provisioning with the immutable, already-fetched JUCE source.
- Select VST3 only; disable post-build user-directory copying and automatic
  manifest generation (which would execute a plugin loader).
- Omit the LTO recommendation and unconditional Catch2 test/discovery graph.
  Catch2 is not fetched, and upstream instance-creating tests are not run.

JUCE's standard native CMake graph builds its own exact-version `juceaide`.
The recipe does not import the Windows recipe or its private helper. Miserere's
`src/`, embedded resources, and JUCE's modules are untouched. No source guard is
bypassed. The build uses the two public source fetches above and compiles all 16
BinaryData translation units; no neural models, firmware, or external user
content are downloaded. The installed library receives the shared JUCE runtime
RPATH, including its dynamically loaded X11/OpenGL libraries.

## Test-first evidence and reproduction

`tests/basilica-miserere.nix` was staged and run before the package existed. It
failed with the expected `pkgs/basilica-miserere does not exist` evaluation
error. After implementing the recipe, the original explicit-checkout command
built the package and passed the real-artifact assertions. The portable form
below derives a URI-encoded Git source URI from the checkout root. It was
checked by offline derivation evaluation, without rebuilding. Run from the Git root:

```bash
git add tests/basilica-miserere.nix pkgs/basilica-miserere/default.nix \
  pkgs/basilica-miserere/adapt.py
export FOSS_PLUGINS_FLAKE_URI="$(python3 -c \
  'import pathlib, sys; print("git+" + pathlib.Path(sys.argv[1]).as_uri())' \
  "$(git rev-parse --show-toplevel)")"
nix build --impure --no-link --print-out-paths -L --max-jobs 1 --cores 4 \
  --expr 'let
    f = builtins.getFlake (builtins.getEnv "FOSS_PLUGINS_FLAKE_URI");
    p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in p.callPackage (f.outPath + "/tests/basilica-miserere.nix") {}'
```

The source boundary is explicit Git filtering. `nix config show sandbox`
returned `true`. These are ordinary sandboxed derivations, without a
`__noChroot` override. The test reads the installed store bundle and checks:

- ELF64, little-endian, x86-64 identity and exact VST3 installation path.
- Dynamic exports `GetPluginFactory`, `ModuleEntry`, and `ModuleExit`.
- `ctypes.CDLL` with `RTLD_NOW | RTLD_LOCAL` for complete relocation resolution,
  plus symbol lookup without invoking the factory or module entrypoints.
- RPATH resolution and read-only loading of `libX11.so.6`, `libXcursor.so.1`,
  `libXinerama.so.1`, `libXrandr.so.2`, and `libGL.so.1`.
- Byte-for-byte presence of all 13 factory presets, German translation, and
  both complete original EB Garamond TTF files in the built ELF.
- Retained project/JUCE/OFL notices, no standalone binary, and no ONNX payload.

No GUI initialization, audio instance, factory call, or host scan is performed.
ELF/export/asset inspection is data-only; `dlopen` necessarily executes loader
initializers, so that part is a bounded loader smoke test, not static analysis.
The build emitted upstream C++ warnings (hidden overloads, float comparisons,
shadowing), an ignored legacy JUCE splash-flag note, and unused CMake option
warnings; none blocked compilation. No DSP fixes were applied.

## Receipts and realized outputs

| Item | Value |
| --- | --- |
| Plugin derivation | `/nix/store/silh3y3aal8ylrrz858zcpwxl61l9i5c-basilica-miserere-0.7.0.drv` |
| Plugin output | `/nix/store/415izqbh7cjcaki676h2nh33kygn5pn3-basilica-miserere-0.7.0` |
| Artifact-test derivation | `/nix/store/l2pbrx0mpcfj8bgmrai8yczihh3gj0iq-basilica-miserere-native-artifacts.drv` |
| Artifact-test output | `/nix/store/wr5a031mivlq14zl7irc86zrdjnq6chx-basilica-miserere-native-artifacts` |
| Full machine-readable receipt | `/nix/store/wr5a031mivlq14zl7irc86zrdjnq6chx-basilica-miserere-native-artifacts/verification.json` |
| Installed `Miserere.so` SHA-256 | `95e8b38155dbdc02933f112883771fcb169169edb857ec2e0ea1663a480894b6` |

The JSON receipt includes all embedded-asset SHA-256 values, resolved runtime
paths, direct dependencies, and verification scope. Direct `DT_NEEDED` entries:
`libasound.so.2`, `libfontconfig.so.1`, `libfreetype.so.6`, `librt.so.1`,
`libdl.so.2`, `libpthread.so.0`, `libstdc++.so.6`, `libm.so.6`, `libgcc_s.so.1`,
`libc.so.6`, and `ld-linux-x86-64.so.2`.

Build logs:

```bash
nix log /nix/store/silh3y3aal8ylrrz858zcpwxl61l9i5c-basilica-miserere-0.7.0.drv
nix log /nix/store/l2pbrx0mpcfj8bgmrai8yczihh3gj0iq-basilica-miserere-native-artifacts.drv
```

These are receipts for one local realization, not a reproducibility claim.

## Licensing

The actual Miserere `LICENSE` is GNU AGPL version 3. JUCE 8.0.14's
`LICENSE.md` offers AGPLv3 or commercial terms; this build takes its AGPLv3
open-source path. Metadata declares `agpl3Only` and `ofl`, without an unfree
gate. The public source includes EB Garamond Regular and SemiBold under
SIL OFL 1.1; their original bytes are embedded and the complete original
copyright/OFL terms are installed alongside the project and JUCE notices in
`share/doc/basilica-miserere/`.

The exact fetched Miserere/JUCE trees retain their original source and bundled
third-party notices. This task realizes a local plugin/test output, not a
redistribution archive; redistribution needs corresponding source, these build
adaptations, and applicable notices. The recipe and artifact test are directly
callable for parent integration review.
