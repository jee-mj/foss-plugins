# ToneShiftEQ Windows source cross-build

The scoped recipe is `pkgs/toneshifteq-windows/default.nix`; the artifact check
is `tests/toneshifteq-windows.nix`. Shared package exports are integrated
separately. From the Git repository root, stage legitimate new recipe/test
files and build through the Git source boundary:

```sh
ROOT="$PWD" nix build --impure --no-link --max-jobs 1 --cores 4 --print-out-paths \
  --expr 'let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "ROOT");
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in pkgs.callPackage (f.outPath + "/tests/toneshifteq-windows.nix") {}'
```

To build deliverables directly, use the same expression with
`"/pkgs/toneshifteq-windows"` instead of the test filename. Select `.installer`
on that package for the separate operator installer output. No local-flake
helper or raw path flake import is needed.

## Source and toolchain

- ToneShiftEQ **1.3.0**, commit `2c9798ded641988d59e6d5e79fa88feb2d9ff13c`.
- Recursive source NAR: `sha256-y85UbyIbkFS8UDxzLg23nPQyqS/GRX1VEcVg5Rr/9Go=`.
- libxputty gitlink: `439d5cd5fed48618f773375ae6624e91ff82ee1e`.
- Locked nixpkgs: `fd1462031fdee08f65fd0b4c6b64e22239a77870`, NAR
  `sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=`.
- MinGW-w64 13.0.0, GCC 15.2.0, binutils 2.46, MCF Gthread 2.3.2.
- Static Cairo 1.18.4, pixman 0.46.4, zlib 1.3.2, libpng 1.6.58,
  libsndfile 1.2.2. Exact source hashes and applied patches are emitted in
  `source/dependencies.json`; `source/packaging/flake.lock` pins the Nix recipes.

The actual upstream workflow invokes native GNU Make via a PawPaw-enabled
MinGW action. ToneShiftEQ **is not DPF**. The Nix recipe supplies the equivalent
explicit target/compiler/pkg-config/static-library settings; it does not run
or fetch the mutable action/PawPaw scripts. `TARGET=Windows` selects libxputty's
Win32 backend and `x86_64-win` VST3 layout. Static link order repeats the
graphics libraries after libxputty, as upstream PawPaw does. The ordinary
`_USE_MATH_DEFINES` header switch exposes math constants under strict C++17.
No DSP code or source guards are changed.

Embedded Roboto fonts and the stb_truetype/Cairo user-font implementation are
retained. FreeType/fontconfig are unnecessary for this pinned implementation.
Libsndfile's optional FLAC/Ogg/Vorbis/Opus/MPEG codecs are explicitly disabled;
built-in WAV/AIFF and other built-in formats remain. This is a documented codec
limitation of this operator build, not upstream release equivalence.

## Deliverables and identities

The main output contains:

- `payload/CLAP/toneshifteq.clap` — PE32+ AMD64 DLL.
- `payload/VST3/Toneshifteq.vst3/Contents/x86_64-win/Toneshifteq.vst3` —
  PE32+ AMD64 DLL inside a VST3 bundle.
- `payload/Notices/` — complete project/vendor/font and dependency notices.
- `toneshifteq-1.3.0-windows-x86_64.zip` — deterministic manual-copy archive.
- `source/` — corresponding recursive source, library/toolchain source
  snapshots or archives, applied patches, recipe, lock, and relink inputs.

The callable delivered entry is
`source/packaging/pkgs/toneshifteq-windows/default.nix`. The repository-shaped
layout preserves its `../../flake.lock` reference within the supplied tree;
`package.py`, `collect-notices.py`, `installer.nsi` and `LICENSE-REVIEW.md` are
alongside the entry. `verification.json` is deliberately excluded from this
tree to avoid an artifact-output self-reference.

To evaluate or rebuild without the original checkout, set `DELIVERY` to the
main output directory and use the supplied lock:

```sh
DELIVERY="/nix/store/<main-output>" nix build --impure --no-link \
  --max-jobs 1 --cores 4 --print-out-paths --expr 'let
    packaging = builtins.getEnv "DELIVERY" + "/source/packaging";
    lock = (builtins.fromJSON (builtins.readFile
      (packaging + "/flake.lock"))).nodes.nixpkgs.locked;
    pkgs = import (builtins.fetchTree lock) { system = "x86_64-linux"; };
  in pkgs.callPackage (packaging + "/pkgs/toneshifteq-windows") {}'
```

Use `nix eval --impure --raw --expr` with the same expression and select
`.drvPath` on the `callPackage` result for evaluation only. This reads a store
delivery and fetches the exact public locked nixpkgs input; it does not import
a local checkout as a raw flake. A populated Nix cache/store is still required
for offline builds, as described below.

Each binary contains **both** products:

| Product | CLAP ID | VST3 FUID words |
| --- | --- | --- |
| ToneShift-EQ12M (Master) | `com.brummer10.ToneShiftEQ.Master` | `f56bf8c5 f60047ce a5a7dd43 1717129a` |
| ToneShift-EQ12L (Live) | `com.brummer10.ToneShiftEQ.Live` | `c1de8249 99ae4365 85a775bc 91ea8d7e` |

Windows LV2 and standalone are explicitly unsupported by this upstream source.

The separate `installer` output contains an **unsigned operator NSIS installer**
(`toneshifteq-1.3.0-windows-x86_64-setup.exe`), its recipe, and NSIS notice.
It places CLAP/VST3 under the respective 64-bit Common Files directories and
notices under `Common Files/ToneShiftEQ/Notices`. It is not an upstream installer.
Distribute corresponding `source/` alongside either binary delivery, including
the LGPL libsndfile sources and relink inputs. The snapshots support offline
source inspection/relink work with an available toolchain; they are not an
export of the complete Nix bootstrap/build-tool closure for an empty machine.

## Verification

The check parses PE data without loading a plugin, checks AMD64/DLL flags,
CLAP entry and VST3 factory/lifecycle exports, both product names/IDs, zero
link timestamps, absence of signatures/delay imports, and system-only imports.
It compares every manual ZIP member and extracts NSIS **as data** with 7-Zip,
checking the exact destination set and every payload byte. Misplaced-path and
invalid-PE mutations must fail. Full embedded notices are compared with the
pinned source.

Independent repackaging uses the same compiled input and compares ZIP/installer
bytes. A distinct salted compilation derivation recompiles source and compares
both plugin binaries separately. The delivered entry is also evaluated using
its own lock and must yield the same unsalted derivation. A separately salted
archived-recipe build recompiles source and compares both DLLs and ZIP/installer
bytes. These are separate assertions, not a claim that evaluating the same
derivation forces a new compilation. Neither result proves a historical upstream
release match. Static identity checks do not execute factories or establish
Windows host discovery, GUI behavior, DSP correctness, latency, or audio quality.
