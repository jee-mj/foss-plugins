# ToneTwist: six Windows x86-64 source-built effects

The package builds **MetalTone, CollisionDrive, Rumor, TubeScreamer,
ValveCaster and BoobTube**, each as **CLAP and VST3** with its Cairo editor.
These are twelve real Windows DLLs compiled offline from pinned public source
using Linux-hosted MinGW-w64 GCC. NewPedal is an upstream development template,
not a suite product. ValveCaster's booster and BoobTube's voltage modes remain
within their existing product identities. The upstream CollisionDrive display
spelling `CollisonDrive` is retained; its filename/ID uses `collisiondrive`.

## Pins

| Input | Revision / unpacked NAR hash |
| --- | --- |
| ToneTwistPlugs | `5fac29094050eecf665479921e6ebbd3595b2281` |
| Source NAR | `sha256-YDnRTHKIjmeTxsT8oLt7N7OcGc+tIKDfJr+++cYFkV0=` |
| DPF gitlink | `29addec6f6e072162d0269fe8f1341b333c69e42` |
| DPF NAR | `sha256-WleyOtcEfUNgbwBIvqrZcGwLhLOKDsxcqNCVKvjyst0=` |
| Nested Pugl gitlink | `e33b2f6b0cea6d6263990aa9abe6a69fdfba5973` |
| Pugl NAR | `sha256-MPbhlHTJGCPH7bdHaBQMMtXC//yxeuPrSstf8pd+uQo=` |
| Locked nixpkgs | `fd1462031fdee08f65fd0b4c6b64e22239a77870` |
| nixpkgs NAR | `sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=` |

Each Git source comes from its full-commit GitHub archive URL:
`https://github.com/OWNER/REPO/archive/REVISION.tar.gz`, using
`brummer10/ToneTwistPlugs`, `DISTRHO/DPF`, and `DISTRHO/pugl`, respectively.
Both gitlinks were checked in the pinned source checkout. Embedded
zita-resampler 1.1.0, generated DSP, CairoWidgets, images and other suite files
are covered by the ToneTwist source hash. The upstream `pugl.patch` is applied
offline to the pinned Pugl source.

Toolchain: `pkgsCross.mingwW64`, target `x86_64-w64-mingw32`, **GCC 15.2.0**,
**binutils 2.46**, **MinGW-w64 13.0.0**, **MCF Gthread 2.3.2**. Packaging uses
**NSIS 3.11**; checks use **7-Zip 26.01** and **pefile 2024.8.26**, all supplied
by the locked nixpkgs. Compiler/runtime source recipes remain pinned there.

Graphics dependencies are statically built from these source archives
(the hashes below are flat archive SHA-256 SRI, not NAR hashes):

| Dependency | Source archive hash |
| --- | --- |
| Cairo 1.18.4 | `sha256-RF7YIIpuSCPeEianTKMZ02AOg/Y2n5mxQmUAZZnDLMs=` |
| pixman 0.46.4 | `sha256-0JxE68O9W+5wIcefki/o+y+1f3Mg9V6X/5kU0jRqWRw=` |
| zlib 1.3.2 | `sha256-uzKaCizQJ00FUZ1hxmfAYuBpkNcuEl7i36jeZPARnRY=` |
| libpng 1.6.58 | `sha256-KOtAP1Hw90BSSRMs7P6C6lwO+X8bMsWmWCiBSuDTR3U=` |

Cairo uses Win32/image/PNG support, without X11, fontconfig, FreeType, GLib,
LZO or downloaded Meson subprojects. libpng APNG support is disabled, avoiding
an unnecessary patch dependency. DPF's ISC `travesty` implementation supplies
VST3 support; no proprietary Steinberg SDK is acquired. PawPaw and the mutable
upstream CI action tags are evidence of the cross-build route, not build inputs.

## Build and check

Run from the repository Git root after making the new package/test files
Git-visible. Use the Git flake boundary; these commands do not need shared
package exports or flake check integration:

```sh
nix build --impure --no-write-lock-file --no-link --print-out-paths \
  --cores 4 --max-jobs 1 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    package = pkgs.callPackage (f.outPath + "/pkgs/tonetwist-windows") {};
  in [ package package.installer ]'

nix build --impure --no-write-lock-file --no-link --print-out-paths \
  --cores 4 --max-jobs 1 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "PWD");
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in pkgs.callPackage (f.outPath + "/tests/tonetwist-windows.nix") {}'
```

To repeat compilation rather than just packaging, use the first expression,
replace its final expression with `package.plugin`, and add `--rebuild`.
The package's `plugin` passthru is the compiled suite before packaging.
`licenseStatus` is `conditional-mixed-source-notices`; do not infer membership
in a shared free-package set from the successful technical build.

## Outputs and manual use

The default output contains:

- `tonetwist-unstable-5fac290-windows-x86_64.zip`, a manual-copy ZIP.
- `payload/CLAP/NAME.clap` for each of the six lowercase product names.
- Complete `payload/VST3/NAME.vst3` bundles, each containing
  `Contents/x86_64-win/NAME.vst3`. Copy the entire bundle directory.
- `payload/Notices`: public source notices, original headers/assets, graphics
  licenses, complete attributed CLAP MIT grant (`LICENSE-CLAP`), DejaVu
  resource notice and compiler/runtime notices/exceptions.
- `source/upstream`, `source/dpf`, `source/pugl`: exact unmodified fetched
  source trees; `default.nix` reconstructs the nested dependency layout and
  applies the upstream Pugl patch. Source archives for all four graphics
  dependencies, the recipe, ZIP script, installer source, `flake.lock`, and
  `dependencies.json` (versions, URLs, hashes) accompany them. `source/LICENSE-CLAP`
  preserves the exact same CLAP grant as the payload, ZIP and installer.

Lowercase product names: `metaltone`, `collisiondrive`, `rumor`, `tubescreamer`,
`valvecaster`, `boobtube`. For manual use, copy the CLAP files into a Windows
host's CLAP scan directory, whole VST3 bundles into its VST3 directory, and
retain the notices and corresponding source alongside redistribution.

The separate `installer` output contains
`tonetwist-unstable-5fac290-windows-x86_64-setup.exe`, `installer.nsi`, and
`NSIS-COPYING`. This is an **operator-packaged installer, not an upstream
installer**. It targets 64-bit Common Files `VST3`, `CLAP`, and
`ToneTwist/Notices`, with an x64 Windows guard. The unsigned NSIS bootstrap is
x86; the installed plugins are AMD64. It requests admin privileges and supplies
no uninstaller, registry integration or upgrade rollback.

The NSIS compiler is built by locked nixpkgs; its bootstrap/helper come from
the pinned upstream Windows NSIS distribution, not a source rebuild here.
NSIS source archive SHA-256:
`19e72062676ebdc67c11dc032ba80b979cdbffd3886c60b04bb442cdd401ff4b`;
Windows distribution NAR SHA-256:
`e574f335ab9d3ad73118f46615e5c9f2a52f3e4622ecbb7e5886badbc8601348`.

## Verification results

The initial test failed on the absent suite package. The completed test built
the real source and passed, including a missing-BoobTube mutation check.

- All **12** plugins: PE32+, AMD64 machine `0x8664`, DLL characteristic,
  zero PE timestamps, no embedded Authenticode signature.
- Every VST3 exports `GetPluginFactory`, `InitDll` and `ExitDll`; every CLAP
  exports `clap_entry`. Delay-import directories and parsed delayed imports
  are rejected in addition to checking the ordinary DLL imports.
- All import only these Windows system DLLs: `COMDLG32`, `dwmapi`, `GDI32`,
  `KERNEL32`, `MSIMG32`, `msvcrt`, `ntdll`, `USER32`. Graphics, C++, GCC,
  threading runtimes are statically linked.
- Exact ZIP entry names/bytes match the payload. 7-Zip extracts the installer
  without running it; every destination and SHA-256 matches that same payload.
  The sole extra file is the exact pinned NSIS `System.dll` helper. Every
  extra-parent mutation of an installer destination is rejected.
- Two independent **packaging derivations sharing one compiled suite** produce
  byte-identical ZIPs and installers. ZIP ordering/timestamps/modes and NSIS
  input timestamps are normalized.
- Separately, **`nix build --rebuild` on `package.plugin` passed** and matched
  the original compiled output. This is a local source repeat-build result,
  distinct from the packaging comparison and not cross-machine proof.

Final distributable SHA-256:

| Artifact | SHA-256 |
| --- | --- |
| Manual ZIP | `86184e2c483018c62e14fb11b3164b8ee12cf206a16ef670bd2850f4094ae9bc` |
| Operator NSIS EXE | `725a140e624efd3736a6f5aa050af658c2883ebbed9eb07782984b5527fc22d1` |

The check output records SHA-256 for all twelve individual plugin files.
7-Zip reports `NSIS-3 Unicode BadCmd=13` but extracts the complete payload
successfully. No Windows payload was executed, and host scanning, GUI rendering,
audio processing and runtime installer behavior have not been tested.

### Review-fix round 1

The test-first run rejected four gaps together: accepted delay-import metadata,
accepted missing `InitDll`, accepted missing `ExitDll`, and missing complete
CLAP MIT notice. After correction, all twelve actual PEs, all negative cases,
source notice correspondence, ZIP/installer byte and path checks, and two
independent packaging realizations passed. A separate forced source rebuild
also matched the corrected compiled output. All twelve plugin binary hashes
remain identical to the previous build; notice contents and distributable
ZIP/EXE hashes changed. Source, dependency and toolchain pins are unchanged.

The vendored CLAP notice is byte-identical to the verified Wolf Shaper and
DrumCloud notice, SHA-256
`50bf21def6095d5e50999675203ae1cd03a6333859bf5fa7c2238909b04dd7d3`.
Its complete grant and 2021 Alexandre BIQUE attribution were checked against
[CLAP 1.0.0 LICENSE at commit 84ad6fe9739d3070ed0eb05c24be303a899ab813](https://github.com/free-audio/clap/blob/84ad6fe9739d3070ed0eb05c24be303a899ab813/LICENSE).
The additional 2014-2022 Alexandre Bique attribution is retained from the pinned
DPF LICENSING.md. That DPF summary identifies MIT but its copied CLAP headers
lack the permission text; the separate notice supplies it. No additional SDK
is fetched at build time. The exact output paths, artifact/plugin hashes and
red/green/rebuild commands are recorded in
[`verification-round1.json`](../pkgs/tonetwist-windows/verification-round1.json).

## Build investigation and license classification

Recipe bring-up exposed and resolved concrete configuration failures: Cairo's
Python shebang needed normalization; Meson's default auto-features pulled in
unneeded LZO; fetched submodule directories needed write permissions before
assembly; newer DPF uses `USE_FILE_BROWSER=false`; the native pkg-config wrapper
and full static dependency search path were needed; and Cairo's
`CAIRO_WIN32_STATIC_BUILD` define had to be passed via DPF's C/C++ flags rather
than ignored CPPFLAGS. The final suite compilation completed without a binary
fallback. Only the explicit `cairo`, `vst3`, and `clap` Make targets are invoked;
the root LV2 generator and target executables are never run.

The public headers contain license notices, rather than a missing-license
assumption: wrappers say literally `GPL-2.0 license`, several helpers say
GPL-2.0-or-later, and zita-resampler says GPL-3.0-or-later. There is no root
LICENSE at the pinned suite revision. Mixed version statements and incompletely
marked assets/generated code leave redistribution classification **conditional**.
The build preserves those statements without declaring a fabricated suite GPL
grant. See `pkgs/tonetwist-windows/LICENSE-REVIEW.md`. This informational
classification does not gate the technical source route.
