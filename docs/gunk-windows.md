# JQ Gunk: Linux-hosted Windows source build

This isolated recipe builds **JQ Gunk 0.2.2 x86-64 Windows VST3** from
[`cemkod/gunk`](https://github.com/cemkod/gunk/tree/9cb7995ec4dbb982bf1c034f4499104422f1b0a9).
It produces a complete manual-copy ZIP, corresponding-source ZIP and an
**operator-created NSIS installer**. These are distinct artifacts. The recipe
is deliberately not added to the shared package exports or catalog.

## Immutable inputs

All full revisions and fixed-output hashes are in
[`sources.nix`](../pkgs/gunk-windows/sources.nix).

| Source | Revision | Meaning |
| --- | --- | --- |
| Gunk | `9cb7995ec4dbb982bf1c034f4499104422f1b0a9` | Reviewed product source, CMake version 0.2.2 |
| JUCE | `4f43011b96eb0636104cb3e433894cda98243626` | Upstream-selected 7.0.12 |
| aubio | `319186517bfc0dd5c015241c091b849f209e0483` | Upstream-selected 0.4.9, bundled Ooura FFT, no optional file-I/O backends |
| Cycfi Q | `efe26114f39e4a78bd67c1456a25487d356fb910` | Mutable master resolved on 2026-10-17; a new dependency selection, not historical build provenance |
| Cycfi Infra | `62a88cab2278ac843765c986edfd4d7393ae3db2` | Exact gitlink in that Q revision |

The repository lock selects public nixpkgs commit
`fd1462031fdee08f65fd0b4c6b64e22239a77870`. The exercised tools are GCC
15.2.0, binutils 2.46, MinGW-w64 13.0.0, MCF Gthread 2.3.2, CMake 4.1.6 and
NSIS 3.11. CMake dependency fetching is disconnected; source trees are supplied
by Nix. No Microsoft SDK, proprietary dependency or upstream release binary is
used as a build input.

## Upstream evidence and adaptations

The pinned source has a real Ubuntu/MinGW workflow, a Windows CMake preset and
`cmake/Toolchain-mingw-w64.cmake`. It first builds a native Linux VST3 and copies
its manifest when cross-compiling. JUCE **7.0.12 explicitly supports MinGW**;
the JUCE 8 unsupported-toolchain guard encountered in other projects does not
apply to this source. No platform/compiler guard was removed or overridden.

The latest release observed on 2026-10-17 was `v0.2.1`, containing Linux DEB/RPM
and a macOS DMG, **no Windows asset**. The selected source says 0.2.2. Neither
the release assets nor the presence of cross CI was treated as proof of a
working source build. No release payload was downloaded or used.

Actual build findings, in order:

1. Native JUCE `juceaide` built from the same pinned JUCE source.
2. Plugin compilation failed at `Source/PitchDetector.h:4` with
   `fatal error: aubio/aubio.h: No such file or directory`. The bundled aubio
   recipe exposed only `src/`, while the plugin uses aubio's installed include
   namespace. The adaptation adds an `include/aubio -> ../src` alias and its
   include directory; no DSP/header implementation is substituted.
3. Native Release linking exposed `ar`/`ranlib` messages saying
   `plugin needed to handle lto object`. An attempted `gcc-ar` wrapper path was
   absent. This bounded recipe disables the optional recommended LTO target.
4. Native VST3 and `moduleinfo.json` then built successfully. Linux plugin
   execution is limited to JUCE's upstream manifest generation during the
   build; no plugin was installed or activated in a host.
5. Windows cross compilation and linking succeeded. The manifest-copy shell
   wrapper initially failed inside the sandbox because its interpreter was
   not patched. Marking the template executable before `patchShebangs` fixes
   that packaging problem. A CMake linker-flag quoting error in the initial
   recipe was also corrected before the successful cross build.
6. The Ubuntu-specific static winpthread path is replaced by Nix's selected
   static GCC/C++/MCF runtime. Data-only import inspection finds no external
   `libgcc`, `libstdc++`, `libwinpthread` or MCF DLL dependency.

The Nix cross CMake hook supplies Windows/x86-64 compilers and resource tools;
the upstream case-sensitive `Windows.h` shim is retained. The recipe imports
native `juceaide`, uses the upstream native-manifest-copy mechanism and copies
the entire resulting VST3 bundle. It does not invoke upstream's Ubuntu-specific
`bundle-windows` target. DSP and GUI implementation files are unchanged.

## Build and inspect

Run from this repository's **Git root**, with these new files tracked or staged
so that Nix's Git source filter includes them. The following imports only an
explicit Git flake source and uses the existing lock:

```sh
nix build --impure --no-write-lock-file --no-link --cores 4 --max-jobs 1 \
  --print-out-paths --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in p.callPackage (f.outPath + "/pkgs/gunk-windows") {}'
```

The `out` output contains `gunk-windows-x86_64.zip`, `gunk-source.zip`, `payload/`
and `source/`. The `installer` output contains
`gunk-0.2.2-windows-x86_64-setup.exe`; select it by appending `.installer` to
the expression's package result. The source archive includes the complete
upstream/JUCE/aubio/Q/Infra trees, GCC and MinGW source archives, MCF source,
the lock, tests and a standalone packaging flake. Its packaging directory can
be used as a separate Git checkout with the same Git-filtered invocation.

```sh
nix build --impure --no-write-lock-file --no-link --cores 4 --max-jobs 1 \
  --print-out-paths --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    t = p.callPackage (f.outPath + "/tests/gunk-windows.nix") {};
  in [ t.packaging t.artifacts t.notices t.installer t.repack ]'
```

Checks cover deterministic ZIP metadata and contents, the actual AMD64 PE DLL,
VST3 exports, normal/delay import closure, native-copied manifest identifiers,
factory data/notices/source retention, embedded component notice closure, and
static extraction of the NSIS payload. The NSIS bootstrapper is x86 and contains
the x64 plugin. Its complete 224-file payload is compared by **exact destination
path and bytes**, plus the sole expected `$PLUGINSDIR/System.dll` helper compared
with the locked NSIS input. The expected roots are:

- `$LOCALAPPDATA/Programs/Common/VST3/` for the bundle;
- `$APPDATA/JQGunk/` for factory presets and wavetables;
- `$LOCALAPPDATA/Programs/JQGunk/Notices/` for all notices and INSTALL.txt.

Negative checks relocate moduleinfo.json under a wrong parent, add an extra
wrong-parent duplicate, add an unknown helper, and alter the known helper.
All must be rejected; the original basename-only validator demonstrably accepted
the first mutation before the correction. The installer destinations themselves
are unchanged.

**Windows executables are never run.** The copied native manifest is not a
Windows factory-enumeration test. JUCE 7's generator emits trailing commas;
tests tolerate those without changing the upstream-generated manifest.
Windows DAW scanning, audio, GUI behavior and installer execution remain
untested.

## Installation and notices

See [`INSTALL.txt`](../pkgs/gunk-windows/INSTALL.txt) for manual installation and
the per-user installer destinations. The installer uses the current user's
VST3 directory; the DAW may require that path to be added explicitly.

The manual distribution includes factory presets and Surge wavetables as
external AppData files. Upstream's original Windows instructions incorrectly
claim that factory presets are embedded. The plugin uses
`%APPDATA%\JQGunk\Factory Presets` and `%APPDATA%\JQGunk\Wavetables`.

Project GPL terms, JUCE's GPL route, aubio GPL terms, Q MIT terms, Surge
attribution and GNU/MinGW/MCF runtime notices are retained. Both the binary ZIP
and NSIS installer carry `Notices/JUCE-component-source-notices.txt`: a lossless
raw-byte concatenation of the complete source/license contents of the 13 JUCE
modules with compiled translation units, covering 2,026 files. Clear filename
separators keep each file's legal text contiguous and visible. The companion
`Notices/JUCE-component-source-index.json` records relative path, zero-based
byte offset, length and SHA-256 for exact reconstruction, including binary bytes
and original line endings. No source bytes are transcoded or discarded.

This preserves every embedded attribution, grant, condition and disclaimer
instead of relying only on JUCE's top-level license or the separate source
archive. Tests reconstruct all 2,026 records and compare each byte to both the
immutable JUCE input and the intact original source tree in the source archive.
All license/copyright/README records are explicitly checked for contiguous byte
inclusion. Only the duplicated per-source entries in the binary payload were
replaced; the full JUCE tree is still retained in the corresponding-source ZIP.

There are now **224 manual ZIP members / installer payload files**, plus one
NSIS helper. The 2,026 indexed records are not installation members. Checks
enforce the collection's 2,048-file bound and a 128 MiB per-member bound; the
notice check JSON reports actual aggregate, source-byte and index sizes. No
generic source-extension allowlist is needed for this compact binary form.

The exercised aggregate is **28,336,388 bytes (27.02 MiB)**, containing
27,965,890 unmodified source bytes plus filename separators. Its index is
435,029 bytes. The aggregate is the largest manual member and is below even
32 MiB; the 128 MiB hard bound does not require a larger exception for this build.

Concrete evidence includes `juce_VST3Headers.h`'s assembled
`VST3_SDK/base/source/fstring.cpp`, whose full 2023 Steinberg BSD-3-Clause header
is preserved, the SDK's other license files and source headers, libpng's LICENSE
and png.h, the complete IJG JPEG README and per-file notices, and zlib.h with
the full zlib implementation tree. Graphics/font-handling source notices and
Surge attribution remain retained. No font asset exists in the pinned Gunk
source; Windows uses native system fonts, which are not redistributed. The
Linux helper's FreeType library is not part of the Windows payload.

See [`NOTICE-CLOSURE.md`](../pkgs/gunk-windows/NOTICE-CLOSURE.md) for scope,
assembled-code evidence and component locations. Infra's MIT notices remain
with its full corresponding source. The source archive preserves all source
inputs, the updated callable build recipe, validator, tests and locked public
toolchain reference, including the byte-aggregation helper. These are unsigned operator artifacts, not upstream
release artifacts.

## Repeat evidence

The successful Windows plugin derivation was separately compiled again with
`nix build --rebuild`, still using four cores and one job. Nix compared its
output against the first compilation and found it byte-identical. This is a
real repeat compilation of the same derivation, not a cached second invocation.

Manual/source ZIPs are also independently repacked and compared. NSIS records
input mtimes, so the installer staging files are normalized to 1980 before
packaging; the packaging derivation is separately rebuilt to compare both
outputs. These are separate packaging/recompilation claims, not Windows
runtime tests. Machine-readable artifact hashes and build receipts live in
[`verification.json`](../pkgs/gunk-windows/verification.json).
