# Basilica Miserere Windows source-build spike

## Result: blocked at JUCE's MinGW platform boundary

On 2026-10-17, the Linux-hosted Windows source build **failed** with JUCE
8.0.14 and the repository's existing MinGW-w64 GCC toolchain. There is **no
Windows plugin, manual-copy ZIP, source ZIP or installer output** from this
probe. The recipe and artifact tests are retained as an isolated, failing
feasibility probe, not an integrated or validated package.

The exact-version Linux `juceaide` **did build from source**, reporting
`JUCE v8.0.14`. It successfully generated the Windows icon, RC file and
BinaryData. Windows RC compilation and all 16 embedded-asset translation
units completed. The plugin build then failed in JUCE module compilation:

```text
juce_TargetPlatform.h:113:6: error: #error "MinGW is not supported. Please use an alternative compiler."
juce_Memory.h:40:71: error: 'memset' was not declared in this scope
juce_HashMap.h:61:109: error: cast from 'const void*' to 'juce::pointer_sized_uint' {aka 'unsigned int'} loses precision [-fpermissive]
juce_UIATextProvider_windows.h:324:40: error: 'CaretPosition_BeginningOfLine' was not declared in this scope
juce_UIATextProvider_windows.h:327:40: error: 'CaretPosition_EndOfLine' was not declared in this scope
juce_UIATextProvider_windows.h:329:36: error: 'CaretPosition_Unknown' was not declared in this scope
```

JUCE's Windows architecture macros in this pin are initialized only under
`_MSC_VER`; GCC consequently also encounters incorrect pointer-width types.
Its standard-header paths do not supply the same C string declarations for
this unsupported compiler. Simply deleting the explicit rejection would not
address those errors or the observed UI Automation header mismatch. No such
guard bypass, platform shim or GUI/DSP behavioral patch was applied.

This establishes a **specific failed MinGW route**, not a permanent requirement
to build on a Windows host. A Linux-hosted MSVC-compatible cross toolchain with
appropriately provisioned SDK inputs, or an upstream-supported JUCE MinGW port,
would require a separately bounded investigation. Neither was tested here.

## Immutable inputs and identity

| Input | Pin |
| --- | --- |
| Miserere selected release | `v0.7.0` |
| Annotated tag object | `db9a91bcd2095f69fd4a2d7708f8105aff17976a` |
| Release commit | `6ce6cc2deb616f337622e36c747a292f505ea0b7` |
| Miserere unpacked NAR | `sha256-gzAKD2fO8DzPaFRBVOYq7Apj7haEBgrTl0qsUzTJXME=` |
| JUCE requested by that release | `8.0.14` |
| JUCE commit | `2cdfca8feb300fb424002ba2c2751569e5bacb64` |
| JUCE unpacked NAR | `sha256-oXFYfFqySW2XtM1e5/ifxAp9qSIVLzY1WAUKE3EscoQ=` |
| nixpkgs lock | `fd1462031fdee08f65fd0b4c6b64e22239a77870` |
| Target | `x86_64-w64-mingw32` |
| Toolchain | GCC 15.2.0; binutils 2.46; MinGW-w64 13.0.0; MCF Gthread 2.3.2 |
| Resource cap | `--max-jobs 1 --cores 4` |

Pins were resolved using the official repositories' GitHub Git refs/tag APIs.
The release commit is distinct from the older product-report inspection pin
`19888064eb9a44f5ddf3cd32d5643fdadde3e85d`.

The canonical [product catalog](../catalog/products.json) records
repository identity `AUDIO-003`, alias `BA-013`, product
`AUDIO-003/miserere`, and source identity seeds `Yvsv` / `Msrr`. The selected
release's CMake confirms those same seeds. No VST3 class IDs were fabricated
or obtained by executing the plugin.

## Native-helper strategy and adaptations

The inspected JUCE files were `extras/Build/juceaide/CMakeLists.txt`,
`extras/Build/CMake/JUCEUtils.cmake`, and the top-level CMake configuration
at the JUCE pin above. This version normally recursively configures and
builds a host `juceaide`; it does **not** implement a
`JUCE_USE_EXTERNAL_JUCEAIDE` switch. Setting an assumed switch would not
solve the cross build.

The probe builds the helper separately with `JUCE_BUILD_HELPER_TOOLS=ON`
and imports that exact-version Linux executable as `juce::juceaide` in the
cross graph. Only the helper source is compiled natively; plugin modules
use the Windows compiler. `adapt.py` makes these build-graph changes:

- Replace CPM fetching with the immutable JUCE source provider; remove the
  Windows test executable/Catch2 discovery graph (Catch2 is not fetched).
- Select VST3 only and set `VST3_AUTO_MANIFEST FALSE` so no Windows manifest
  helper is executed; moduleinfo generation is optional and was not performed.
- Disable automatic plugin copying and omit the LTO optimization target.
- Import native `juceaide`; omit Windows `attrib` commands while retaining
  `desktop.ini` and `Plugin.ico` bundle generation.

Miserere's `src/` and JUCE's `modules/` remain unpatched. Conventional vocal
DSP has no external neural model requirement. Both EB Garamond fonts are
already in the selected public source and were included in BinaryData.
No external content or proprietary Windows SDK was downloaded.

An initial configuration failed because multiword CMake linker arguments
were split. Moving those settings to `cmakeFlagsArray` fixed that recipe
error; the next attempt reached the actual framework compile errors above.

## Reproduction and checks

Run from this repository's Git root. New files must be Git-visible. The
isolated probe does not require shared flake exports or package integration.
The URI below encodes the discovered Git root and preserves Git source filtering.
This intentionally reproduces the blocked route; it does not bypass JUCE's guard.

```bash
export FOSS_GIT_URI="$(python3 -c 'import pathlib, subprocess; print("git+" + pathlib.Path(subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).strip()).as_uri())')"
nix build --impure --no-link --print-out-paths -L --max-jobs 1 --cores 4 \
  --expr 'let
    f = builtins.getFlake (builtins.getEnv "FOSS_GIT_URI");
    p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  in p.callPackage (f.outPath + "/tests/basilica-miserere-windows.nix") {}'
```

The test was first run without the package and failed with the expected
missing-package path. Its actual-artifact assertions require PE32+ AMD64 DLL,
`GetPluginFactory` / `InitDll` / `ExitDll` exports, a Windows-system-only DLL
import allowlist, complete bundle icons, notices, source contents, exact ZIP
payloads and two independent byte-identical packaging realizations sharing
one plugin compilation. **Those checks remain blocked**, not passed.

For the independently runnable **synthetic ZIP mechanics test only**, append
`.packagingFixture` to the parenthesized `callPackage` result:

```nix
in (p.callPackage (f.outPath + "/tests/basilica-miserere-windows.nix") {}).packagingFixture
```

That fixture checks sorted paths, bytes, fixed timestamps/permissions and
byte-identical archives after input mtime/mode changes. It neither contains
a real Windows payload nor establishes real-artifact packaging repeatability
or source-compilation reproducibility.

The fixture passed; its synthetic archive SHA-256 is
`308d50ea470b9ca1dc2624c7c8267fd70b4129c639a2600011598a13339cfa21`.
Final evaluation confirms that the plugin derivation is still the exact
failed derivation below; subsequent source-archive/documentation edits did
not change the attempted compiler inputs.

Full compiler log:

```bash
nix log /nix/store/hy7232r2qbarbwxr7qf04342jr19s6mx-basilica-miserere-windows-vst3-x86_64-w64-mingw32-0.7.0.drv
```

Native helper output:
`/nix/store/c481hrd35vf12wbw7xgsqnxzgpqls6dp-miserere-native-juceaide-8.0.14`.
Machine-readable results and error excerpts are in
`pkgs/basilica-miserere-windows/verification.json`.

## Intended artifacts and licensing (not realized)

If a future source-compatibility solution passes the test, the recipe is set
up for a complete `payload/VST3/Miserere.vst3` bundle and a manual-copy ZIP,
plus a separate corresponding-source ZIP. That ZIP includes original Miserere,
JUCE and MCF Gthread source, recipes, patches-as-script, tests and a standalone
flake/lock in `source/packaging/` with the original relative layout. The latter
can be put into a Git checkout and invoked via CLI Git autodetection. It uses
the pinned public source providers, rather than the neighboring unpacked copies.
No optional NSIS installer was attempted after the compile blocker.

Miserere has an AGPLv3 license; JUCE offers AGPLv3 as its open-source path.
This is not an unknown-license package and needs no conditional unfree gate.
EB Garamond's OFL-1.1 terms must be retained. The recipe retains project/JUCE,
OFL, MinGW and MCF/GNU runtime notices, and the full JUCE source retains its
embedded third-party notices. Any later redistribution must accompany the
binaries with the corresponding source and applicable notices; this probe
has not published artifacts.

No Windows payload execution, Wine prefix work, system activation, driver,
input, Downloads or shared integration changes were performed.
