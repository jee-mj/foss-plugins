# 0xFX Windows source-build probe

The unexported recipe in `pkgs/0xfx-windows/` builds **three distinct delivery
targets** for Windows x86-64: CLAP/VST3 plugins, the GUI application, and the
console application. All four binaries were compiled from source and passed
data-only artifact checks. This is an operator source build, not a published
upstream release or a host/runtime acceptance result.

## Frozen inputs

| Input | Pin |
| --- | --- |
| 0xFX | `averagenative/0xFX`, `5b248779c96dce6e64d0ed29cfa598014dc4d3c4` |
| SDL2 2.30.12 | `libsdl-org/SDL`, `8236e01a9f758d15927624925c6043f84d8a261f` |
| Nixpkgs | `fd1462031fdee08f65fd0b4c6b64e22239a77870`, existing `flake.lock` |
| Compiler/API closure | MinGW-w64 GCC 15.2.0, binutils 2.46, MinGW-w64 13.0.0, MCF Gthread 2.3.2 |
| Native tools | CMake 4.1.6, Python 3.13.14, NSIS 3.11 |

Content hashes, artifact hashes, derivation references and check outputs are in
[`verification.json`](../pkgs/0xfx-windows/verification.json). The locked Nix
toolchain closure was reused; this task rebuilt the program and SDL2, not GCC
or the entire toolchain.

Upstream's CMake project and installer literals say **1.3.0**, while plugin
configuration says **0.1.0**. Both are retained. The build does not claim to be
release 1.3.1. Vendored CPLUG, CLAP/VST3 C API, ImGui, cJSON, KissFFT, dr_wav,
miniaudio, nativefiledialog-extended, Shine and stb_image are pinned by the
0xFX tree; independent historical revisions of those copies are not inferred.

## Source adaptation and notices

The upstream GNU x86-64 cross recipe explicitly references vendored precompiled
SDL2 archives. This probe removes both vendored SDL distribution directories
before configuration and adds the exact same SDL2 version's **source** to the
CMake graph. `SDL2::SDL2-static` and `SDL2::SDL2main` replace the binary paths.
The Nix cross compiler supplies compiler, linker, resource compiler, Windows
headers and import libraries. No proprietary SDK is downloaded.

The adaptation touches build-graph wiring only. No DSP, GUI implementation,
platform guards or plugin identity is ported. Upstream Python embeds existing
PNG/ICO bytes into C; no cross-produced generator executable is run. This
project uses conventional DSP and cabinet IR convolution, not neural inference.

Notices include original vendored source files, not abbreviated summaries.
Supplemental official KissFFT and Shine license files repair omissions in the
vendored directories; their exact provenance and the limits of the version
matching are recorded in
[`NOTICE-PROVENANCE.md`](../pkgs/0xfx-windows/NOTICE-PROVENANCE.md).
GPLv3, GCC runtime exception, MCF and MinGW notices are retained separately.
Four bundled IRs retain upstream's public-domain attribution to zoyd; no new IR
pack or model is acquired.

The source ZIP contains the parent-pinned source **with precompiled SDL
directories removed**, replacement SDL2 source with internal Android symlinks
materialized, GCC/MinGW/MCF sources, and the recipe/tests/lock file. It is not a
pristine upstream archive or a fully offline mirror of all Nix build inputs.

## Layout and installer coverage

```text
payload/
  CLAP/0xFX.clap
  VST3/0xFX.vst3/Contents/x86_64-win/0xFX.vst3
  Applications/0xfx_gui.exe
  Applications/0xfx_standalone.exe
  Applications/presets/factory/...
  Applications/resources/ir/bundled/...
  Notices/...
  LICENSE
  README.md
  INSTALL.txt
```

The GUI changes to its executable directory, so its factory presets and IRs
must accompany it under `Applications/`. Console is a separate executable,
staged explicitly beside GUI. Plugins retain the documented Windows bundle
layout; static inspection does not establish plugin preset-discovery behavior.

Upstream has actual x64 GNU/MinGW and ARM64 llvm-mingw toolchain files, release
staging, and two NSIS definitions. Its x64 NSIS recipe selects **GUI, CLAP and
VST3, not console**. Those upstream installers were not built here.

The produced `installer/0xfx-1.3.0-source-x86_64-setup.exe` is an **operator-owned
NSIS installer**, with explicit staging for both applications, plugins, notices
and data. It has an i386 NSIS bootstrapper carrying AMD64 payloads. Its proposed
installation layout places applications/data under the program directory and
plugins under Common Files. No installer, uninstaller or payload was executed;
installer runtime behavior is untested. The operator script does not implement
an uninstaller or upstream shortcuts/registry behavior.

## Evidence and limits

The initial evaluation failed because the package did not exist. The first
actual attempt linked all targets, then failed copying a nonexistent
`build.ninja` evidence file (CMake selected Makefiles). After correction, source
archiving rejected an internal SDL Android symlink; source staging now
materializes it. Exact Nix log derivations are retained in the receipt. Neither
failure caused a binary fallback.

Checks in `tests/0xfx-windows.nix` subsequently passed:

- **Source build:** all four AMD64 PE32+ binaries; source-built static SDL2.
- **Source archive entry paths:** the standalone flake, lock, recipe and
  `packaging/tests/0xfx-windows.nix` exist at their exact referenced paths;
  the output-identity receipt is not embedded in the archive.
- **PE contract:** plugin DLL flags, GUI/console subsystems, non-forwarded
  `clap_entry` and `GetPluginFactory`/`InitDll`/`ExitDll`; CLAP ID and
  hand-derived Windows VST3 UID storage bytes.
- **Dependency closure:** direct and delay imports limited to an explicit
  Windows system-library allowlist; no missing non-system import or external
  SDL/GNU runtime DLL requirement found. Dynamically loaded audio backends and
  actual device drivers remain unexercised.
- **Archives:** complete path sets and per-file bytes compared with staged
  trees, with fixed ZIP timestamps.
- **Installer:** static extraction matched the exact paths and bytes of all
  **144 payload files**, including console; no unexplained extracted files.
- **Independent repack:** manual/source ZIPs and separately salted NSIS
  packaging were byte-identical.
- **Independent recompile:** a separately salted source compilation produced
  byte-identical CLAP, VST3, GUI and console binaries, with no normalization.

Artifacts are `0xfx-windows-x86_64.zip` (62,363,866 bytes), `0xfx-source.zip`
(155,669,585 bytes), and the operator installer (57,338,337 bytes). The receipt
identifies their existing local store output and SHA-256 hashes.

ARM64 remains a documented upstream source branch only; no llvm-mingw ARM64
closure or artifact was attempted. AU is Apple-only. DAW load, audio, GUI,
state, preset enumeration, installation and driver behavior are **not run**.

## Reproduce without shared exports

From the repository's Git root, after staging the legitimate new recipe/test
files, use explicit Git flake fetching. This reuses the existing lock file and
limits builds to four cores and one job:

```bash
nix build --impure --no-link --no-write-lock-file --cores 4 --max-jobs 1 \
  --print-out-paths --expr '
    let
      f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
      p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    in p.callPackage (f.outPath + "/pkgs/0xfx-windows") {}'

nix build --impure --no-link --no-write-lock-file --cores 4 --max-jobs 1 \
  --print-out-paths --expr '
    let
      f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
      p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
      t = p.callPackage (f.outPath + "/tests/0xfx-windows.nix") {};
    in [ t.archiveLayout t.artifacts t.repack t.installerRepack t.recompile ]'
```

To test the actual source ZIP's standalone flake, set `OUTPUT` to the package
output printed above, then run:

```bash
python3 pkgs/0xfx-windows/check-archive.py "$OUTPUT/0xfx-source.zip"
```

The native test helper is also included under the archived
`packaging/pkgs/0xfx-windows/` directory. It extracts only archived packaging
files into a fresh temporary Git checkout, stages them without a commit, and
runs `nix flake check --no-build --offline --no-write-lock-file` through an
explicit `git+file://` URI. It then evaluates the five named checks offline
and confirms the archived lock bytes are unchanged. The locked input must
already be cached. Evaluation uses no files from the original checkout and
executes no Windows payload or generated helper.

This isolated evaluation passed on 2026-10-17. The review test first reproduced
the store-prefixed test filename defect; the copy now sets an explicit basename.
Actual flake evaluation also exposed `callPackage`'s non-derivation override
helpers in `checks`; the standalone flake now exports derivations only. The
source archive changed, while all four binaries, the manual ZIP and the NSIS
installer retained their previous hashes. The main recipe remains unexported
pending parent review.
