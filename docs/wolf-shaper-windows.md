# Wolf Shaper: Windows x86-64 source build

This package builds Wolf Shaper **1.0.2** from its pinned release source with
the locked nixpkgs MinGW-w64 cross toolchain. Both **VST3 and CLAP**, including
the OpenGL editor and embedded fonts, compile successfully. DPF supplies its
ISC-licensed `travesty` VST3 implementation; no proprietary SDK is fetched.

## Source and toolchain pins

| Input | Pin |
| --- | --- |
| Wolf Shaper release | `v1.0.2` |
| Full upstream commit | `4d7b6a1805d774fad553323bc9325c508428ac9e` |
| DPF submodule at that commit | `d8c26737120cc36aacfb61c7c6b667eb6814e392` |
| Source URL | <https://github.com/wolf-plugins/wolf-shaper/releases/download/v1.0.2/wolf-shaper-v1.0.2-source.tar.gz> |
| Unpacked release source NAR hash | `sha256-cE68kB8ui/VhoIe4hEH3bLG/Ken4az6jSdAnYhKmPm4=` |
| Locked nixpkgs commit | `fd1462031fdee08f65fd0b4c6b64e22239a77870` |
| Locked nixpkgs NAR hash | `sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=` |
| Cross API / target | `pkgs.pkgsCross.mingwW64` / `x86_64-w64-mingw32` |
| Compiler / linker | GCC `15.2.0` / binutils `2.46` |
| Windows headers, CRT and winpthreads | MinGW-w64 `13.0.0` |
| GCC threading implementation | MCF Gthread `2.3.2` |
| Installer compiler / archive parser | NSIS `3.11` / 7-Zip `26.01` |
| PE parser | Python pefile `2024.8.26` |

The source archive includes DPF and DSPFilters. The release tag's commit and
DPF gitlink were checked with the GitHub API. The archive's NAR hash pins all
bundled source bytes, including subdependencies. Upstream's release workflow
explicitly targets `win64` with DPF.

NSIS is supplied by the same locked nixpkgs. That recipe builds the native
compiler from `nsis-3.11-src.tar.bz2` (flat SHA-256
`19e72062676ebdc67c11dc032ba80b979cdbffd3886c60b04bb442cdd401ff4b`),
and uses Windows stubs/includes/plugins from `nsis-3.11.zip` (unpacked NAR
SHA-256 `e574f335ab9d3ad73118f46615e5c9f2a52f3e4622ecbb7e5886badbc8601348`).
These are pinned SourceForge inputs. The NSIS bootstrap and helper are supplied
by that pinned distribution, **not rebuilt from source by this package**.

## Build and check

Run from this repository's Git root, with the new package and test files
Git-visible. These commands use a Git flake source boundary and narrowly
`callPackage` the new files. They do not require parent flake export changes.

```sh
nix build --impure --no-write-lock-file --no-link --print-out-paths \
  --cores 4 --max-jobs 1 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    package = pkgs.callPackage (f.outPath + "/pkgs/wolf-shaper-windows") {};
  in [ package package.installer ]'

nix build --impure --no-write-lock-file --no-link --print-out-paths \
  --cores 4 --max-jobs 1 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in pkgs.callPackage (f.outPath + "/tests/wolf-shaper-windows.nix") {}'
```

Package interface for parent integration:

```nix
wolf-shaper-windows = pkgs.callPackage ./pkgs/wolf-shaper-windows { };
# wolf-shaper-windows: manual-copy output
# wolf-shaper-windows.installer: separate installer output
# wolf-shaper-windows.plugin: compiled bundles before packaging
```

### Outputs

The default output contains:

- `wolf-shaper-1.0.2-windows-x86_64.zip`: an actual ZIP for manual installation.
- `payload/VST3/wolf-shaper.vst3/Contents/x86_64-win/wolf-shaper.vst3`:
  the complete upstream Windows VST3 bundle layout.
- `payload/CLAP/wolf-shaper.clap`: the Windows single-file CLAP layout.
- `payload/Notices/`: licenses, attribution and build information.
- `source/`: exact unpacked upstream source and the package/installer recipe.

The separate `installer` output contains:

- `wolf-shaper-1.0.2-windows-x86_64-setup.exe`: an actual NSIS installer PE.
- `installer.nsi`: the human-readable installer source.
- `NSIS-COPYING`: the NSIS redistribution notice.

The installer is **operator-packaged from source, not an upstream installer**.
No project-specific Windows installer source was found in the pinned release.
The small NSIS recipe in this package supplies that missing packaging layer.

For manual installation, copy the entire `VST3/wolf-shaper.vst3` directory to
the Windows host's VST3 scan directory, and `CLAP/wolf-shaper.clap` to its CLAP
scan directory. Retain `Notices`. The installer targets the standard 64-bit
Common Files `VST3` and `CLAP` directories, and places notices in Common Files
`Wolf Shaper/Notices`.

## Verification evidence

The initial test failed because the package did not exist. The completed test
then built real source artifacts and parsed them without loading any DLL or
executing any Windows payload. Nix sandboxing was enabled.

- Both plugins: **PE32+, machine `0x8664` (AMD64), DLL characteristic set**.
- VST3 exports `GetPluginFactory`; CLAP exports `clap_entry`.
- Actual imports, for both plugins: `GDI32.dll`, `KERNEL32.dll`, `msvcrt.dll`,
  `ntdll.dll`, `OPENGL32.dll`, `USER32.dll` (case-insensitive).
- No loose GCC, C++, MCF Gthread or pthread runtime DLL is required; those
  runtimes are linked statically. Windows system DLLs and working OpenGL remain
  required. A compatible 64-bit plugin host is required.
- Installer: **PE32, machine `0x014c` (x86)**, using NSIS Unicode stubs. This is
  the bootstrap architecture; its installed plugins are AMD64. The installer
  checks for 64-bit Windows using NSIS's `x64.nsh`.
- 7-Zip identifies the EXE as **Nsis**, extracts it inside a Nix sandbox, and
  every installed file's SHA-256 matches the corresponding ZIP entry. Its only
  additional file is NSIS's `System.dll` helper: the test verifies exact bytes
  against the locked NSIS distribution and verifies its x86 PE header.
- The tests reject unexpected installer files and non-system plugin DLL imports.
- Two independent **packaging derivations**, sharing the compiled plugins,
  produced byte-identical ZIPs and EXEs. File order, ZIP timestamps, permissions
  and NSIS input timestamps are normalized.
- Separately, `nix build --rebuild` on `.plugin`, capped at four cores and one
  job, successfully rebuilt the source and matched the original derivation's
  output. This demonstrates a local repeat build, not cross-machine proof.

Observed artifact SHA-256 values:

| Artifact | SHA-256 |
| --- | --- |
| VST3 PE | `bb32acdd88fd2b51b6dd1a222295b875b5720d7a500257268022b5551176cc0c` |
| CLAP PE | `21509b91d9053dbecf8dc1f988090d590f0e1c8227053d67310a31bf9d72be83` |
| Manual ZIP | `06b6ff9e8b71fde8360b3f4ea08cc11d1640d5e686b75b32a50d4e81b9efe7eb` |
| NSIS EXE | `afe0087be19b6b26de6fcbe3a876e9fb40bd338fd7850f09fef816d3e436f944` |

Repeat the compilation check by using the first build expression above,
replacing its final expression with `package.plugin`, and adding `--rebuild`.

## Notices and limits

Wolf Shaper is GPL-3.0-or-later. The notices preserve DPF/travesty (ISC), CLAP
(MIT), DSPFilters (MIT), NanoVG/STB, Pugl, Chivo (OFL), DejaVu, embedded math
attributions, MinGW-w64/winpthreads notices and MCF Gthread/GNU runtime licenses
and exceptions. Keep the corresponding source and build recipe available when
redistributing the binaries. The source directory beside the ZIP preserves the
plugin's release source; runtime/toolchain source pins remain in locked nixpkgs.

The NSIS installer requests administrator rights for system-wide Common Files
installation. It is unsigned, installs both formats, and provides no uninstaller,
registry integration, component selection or automatic upgrade rollback. Manual
removal is by deleting the installed plugin files and notices. No executable was
run to test installation, host scanning, GUI rendering or audio processing.
7-Zip reports `NSIS-3 Unicode BadCmd=13` while successfully extracting every file;
archive inspection does not establish runtime installer behavior.

The source compilation emits a GCC 15 `-Wstringop-overflow` warning in bundled
STB PNG code. No upstream code was patched or warning suppressed. There is no
source-support blocker for the requested VST3/CLAP build, so no alternate project
was needed. LV2, VST2 and standalone executables are not built; specifically,
the top-level LV2 metadata generator is not invoked.

## Implementation checklist

- [x] Establish missing-package failure with `tests/wolf-shaper-windows.nix`.
- [x] Build VST3 and CLAP from the pinned DPF release via MinGW-w64.
- [x] Produce deterministic manual ZIP and separately sourced NSIS EXE.
- [x] Parse PE headers/exports/imports and compare extracted installer payload.
- [x] Compare independent packaging realizations and force a source rebuild.
- [x] Record input pins, output hashes, notices and verification limits.
