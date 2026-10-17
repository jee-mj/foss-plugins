# DrumCloud Windows source cross-build

This scoped package builds **DrumCloud 1.9.0-beta.8** from source into x86-64
Windows CLAP and VST3 plugins. The plugin reports version 1.9.0 internally.
The upstream workflow supplies a manual-copy ZIP. Our ZIP is likewise a
**manual-copy archive**, and the separate NSIS setup is **operator-authored**,
not upstream installer source or a repackaged upstream executable.

## Frozen source closure

All hashes below are unpacked NAR SHA-256 hashes, not archive-byte hashes.
The package fetches immutable GitHub source archives and populates the exact
gitlinks; Pugl declares no further submodules at this revision.

| Repository | Full commit | Unpacked hash |
| --- | --- | --- |
| `Chmod666music/Fuimadane-DrumCloud` | `294ed7fb3116f1f16c7430e5df7e1954349405c6` | `sha256-FCv0zrg30jyiPrsNfHtttoutWfI94UVaONx+85EvkKo=` |
| `Chmod666music/DPF` | `9959b7567b57e39b6573547f4281a879bbc23475` | `sha256-+S2HN07emY+DUz2E+8K+KlIH1PFAiunp74YFHloZITk=` |
| `DISTRHO/pugl` | `5e2621d714ddf1cb0f86e852f8ba5dffe04aa3a3` | `sha256-a13PBEn929aq6dNwVaLK1XHGebEJgxfDe4ADp/UB83g=` |

Immutable archive URLs are recorded in `pkgs/drumcloud-windows/default.nix`
and in each payload's `Notices/SOURCE-PINS.json`. The `out` output also includes
the complete assembled upstream source and the packaging recipe in `source/`.
No external SDK, models, firmware, sample packs or binary releases are fetched.
VST3 uses DPF's ISC-licensed travesty implementation.

## Licensing, fonts and artwork

The custom upstream `LICENSE.txt` permits downloading, installing and using
release contents but does not establish a standard modification/redistribution
grant for the complete project. The DSP source retains an inherited ISC DPF
header and `getLicense()` returns `ISC`; these do not resolve the custom terms
for the remaining project files and artwork. Both derivations carry `unfree`
metadata and require explicit opt-in. See `LICENSE-REVIEW.md` in the package.

The active UI draws its own pixel glyphs directly with OpenGL. It does not load
the checked-in `UI/fuimadane_wave_bg.png`; that artwork is retained in `source/`.
DPF's DGL builds generic Resources/NanoVG objects and contains DejaVu Sans,
fontstash and stb components. Their resources and notices are retained
conservatively, without claiming every object/resource survives linker garbage
collection. The original dr_libs decoder headers, CLAP headers and MIT notice,
travesty headers, DPF/Pugl notices, DSP source attribution, and MinGW/GCC/thread
runtime notices are included. Tests compare key notices and font bytes against
the supplied source. No additional fonts or samples are acquired.

## Build and verify

Run from this repository's **Git root**. New package/test files must be staged
for Git-filtered visibility. This deliberately uses explicit `git+file://`
fetching; do not substitute a raw path flake or a local-flake MCP operation.
These commands leave shared package exports and catalog integration to callers.

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --print-out-paths \
  --max-jobs 1 --cores 4 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    p = import f.inputs.nixpkgs {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in p.callPackage (f.outPath + "/tests/drumcloud-windows.nix") {}'
```

To realize the distributables directly, use the same expression prefix with:

```nix
in let d = p.callPackage (f.outPath + "/pkgs/drumcloud-windows") {};
in [ d d.installer ]
```

The compiler is `pkgsCross.mingwW64`: GCC **15.2.0**, binutils **2.46**,
mingw-w64 **13.0.0**, MCF Gthread **2.3.2**, with GNU Make and C++17.
The repository lock pins nixpkgs to
`fd1462031fdee08f65fd0b4c6b64e22239a77870`
(`sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=`).
NSIS is **3.11**. Unlike upstream's Ubuntu POSIX-thread compiler, this pinned
Nixpkgs compiler uses MCF threading. `-static` closes the C++/GCC/thread runtime
dependency chain; it does not statically provide Windows system DLLs or OpenGL.
`--no-insert-timestamp` suppresses linker timestamps. The Windows file browser
is explicitly retained with `USE_FILE_BROWSER=true`; DGL is built first,
followed by the explicit `clap vst3` targets. No generated target helper is run.

## Payload and installation layout

The ZIP has these top-level paths (no additional enclosing directory):

```text
CLAP/d_drumcloud.clap
VST3/d_drumcloud.vst3/Contents/x86_64-win/d_drumcloud.vst3
Notices/...
```

For manual installation, copy the CLAP file to the host's Windows CLAP directory
and the **whole** `.vst3` bundle to its VST3 directory; retain the notices.
The separate installer requests administrator rights and places those same
bytes under `$COMMONFILES64/CLAP`, `$COMMONFILES64/VST3`, and
`$COMMONFILES64/DrumCloud/Notices`. Its x64 guard uses NSIS's pinned 32-bit
`System.dll` helper; the plugins themselves are 64-bit. The operator installer
does not implement an uninstaller.

Both plugins import only these Windows system DLLs:

```text
comdlg32.dll dwmapi.dll gdi32.dll kernel32.dll msvcrt.dll
ntdll.dll opengl32.dll shell32.dll user32.dll
```

`dwmapi.dll` is used by the pinned Pugl Win32 backend. No MinGW runtime DLL is
shipped or imported. `Notices/PE-IMPORTS.json` records the actual import table
for each format; tests reject unexpected imports and delayed imports.

## Verification evidence and limits

The Nix artifact test passed on 2026-10-17. It verifies PE32+ AMD64 DLLs,
`clap_entry`, VST3 `GetPluginFactory`/`InitDll`/`ExitDll`, exact bundle paths,
notice retention, and ZIP contents/timestamps. It statically extracts the NSIS
archive with 7-Zip, verifies every installed byte and destination including the
NSIS helper, and rejects three misplaced-path mutations.

Two independently realized packaging derivations share the compiled plugin
payload and produce identical ZIP and setup bytes. Separately, two distinct
plugin derivations with different `rebuildSalt` values each compiled the source;
comparison found **every payload file byte-identical**, including both plugins.
To reproduce that source-build comparison, realize
`[ d.plugin (d.override { rebuildSalt = "independent-source-rebuild"; }).plugin ]`
using the build expression above, then compare the returned directories with
`diff -r`. Packaging-only repetition uses `repackSalt` and does not recompile.

| Artifact | SHA-256 |
| --- | --- |
| `drumcloud-1.9.0-beta.8-windows-x86_64.zip` | `3af5c0eea50901205b960fd8a4caead48e6f1cc3566f3e0e0e0e7cecdcad7bf0` |
| `drumcloud-1.9.0-beta.8-windows-x86_64-setup.exe` | `f8b0a26c30892aa780baba52a6e21b778e73188de25422cc92c061de5d290c89` |
| `CLAP/d_drumcloud.clap` | `33df4ae81df5bf88416b2a2e0150b20a28fbf5c56f62aea0f4cbf7baf0140d4b` |
| `VST3/d_drumcloud.vst3/Contents/x86_64-win/d_drumcloud.vst3` | `5c6cb4a6a5262351e99e7984372f0a09ad9f7e6d402a34cefa0f5d9f0907f33c` |

This is evidence of repeatability with the same pinned inputs and toolchain,
not a cross-toolchain or cross-host reproducibility study. The successful build
emits upstream GCC warnings for old stb_image code, deprecated `<cstdbool>`,
and unused functions. No upstream source patches were needed.

No plugin or installer was executed. There are no Windows DAW, audio, GUI,
file-browser, installer execution, Wine or bridging runtime claims. Verification
did not touch Wine prefixes, Downloads, activation or driver configuration.
