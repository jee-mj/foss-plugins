# PeakEater 0.8.2 source package

## Sources and offline build

These are `fetchFromGitHub` source pins, not release binaries:

| Repository | Full revision | Recursive SHA-256 (SRI) |
| --- | --- | --- |
| `vvvar/PeakEater` (`v0.8.2`) | `a99b8db4e67a125216634fdcab663050f7cc3add` | `sha256-u4Tqbgk6xU+EW52PRpx5iP0MrjltX+s8mnmY7FK2Kxw=` |
| `juce-framework/JUCE` (`7.0.5`) | `69795dc8e589a9eb5df251b6dd994859bf7b3fab` | `sha256-NRF9oSE04hk6KVSxuUBpP+z+DKRyb6pzBXtz/pLz0/0=` |
| `free-audio/clap-juce-extensions` (including submodules) | `b6cdda9f1fad06ba14e74e036f737d2ed11db2e7` | `sha256-izwjrtjadZ3i4gx8iG71J1wVj4FVCZGyTLCDxH3A7Yg=` |

The extension's gitlinks pin `clap-libs/clap` to
`af1e05ce6487151c6b36003fdb47566dbb50194e` and `clap-libs/clap-helpers`
to `f0b6802305ef628c18a597878e304f9f72aaac99`. The recursive fetch hash
covers both. Revisions and upstream build definitions were inspected through
`gh api`.

Upstream `conanfile.py` specifies JUCE 7.0.5 and C++20; `CMakeLists.txt`
specifies the extension revision above. The derivation keeps upstream's build
graph, supplies JUCE with `add_subdirectory`, overrides FetchContent's source
directory, and sets `FETCHCONTENT_FULLY_DISCONNECTED=ON`. Source downloads
are separate fixed-output fetches; configure and compilation require no network.
Conan's recipe/tooling submodules and pluginval are not needed for these targets.

Built targets: `peakeater_VST3`, `peakeater_CLAP`, `peakeater_LV2`.
The build supplies the project name, version, company and URL normally supplied
by Conan. CMake's minimum policy version is set to 3.5 for CMake 4 support.
Installation uses `lib/plugin-artifacts.nix`; all three ELF objects receive
`lib/juce-runtime.nix`'s runtime RPATH. Post-build plugin copying is disabled.

## License metadata

Upstream README says “GPL-3.0” and `LICENSE.md` contains GPL version 3.
The package records `lib.licenses.gpl3Only`: an explicit project-level
“or later” grant was not identified. The standard license's example notice
is not treated as such a grant. The upstream license is installed under
`share/doc/peakeater/LICENSE.md`.

## Independent verification

Public build and artifact checks, from your clone's Git root:

```bash
nix build --no-link --no-write-lock-file --cores 4 --max-jobs 1 .#peakeater
nix build --no-link --no-write-lock-file .#checks.x86_64-linux.peakeater
```

The following initial verification record predates public export registration.

Tested on `x86_64-linux` using the existing flake's locked nixpkgs revision
`fd1462031fdee08f65fd0b4c6b64e22239a77870`, NAR hash
`sha256-n3gKTBIV4ZA5VQpUakffBe3KGu4+mhPoA34rrqS0GkA=`.
Compiler: GCC 15.2.0; CMake: 4.1.6. All builds use four cores and one Nix job.

Run from `/home/kalki/agent-work/foss-plugins`. The Git flake URI supplies the
locked nixpkgs and existing helpers; only the narrow package/test paths are
passed to `callPackage`. No public package export is required for these checks.

Package build (exit 0):

```bash
nix build --impure --no-link --print-out-paths --cores 4 --max-jobs 1 --expr 'let f = builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins"; p = import f.inputs.nixpkgs { system = "x86_64-linux"; }; in p.callPackage /home/kalki/agent-work/foss-plugins/pkgs/peakeater { juceRuntime = p.callPackage (f.outPath + "/lib/juce-runtime.nix") {}; pluginArtifacts = p.callPackage (f.outPath + "/lib/plugin-artifacts.nix") {}; }'
```

Artifact/layout and dynamic-loading regression (exit 0):

```bash
nix build --impure --no-link --print-out-paths --cores 4 --max-jobs 1 --expr 'let f = builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins"; p = import f.inputs.nixpkgs { system = "x86_64-linux"; }; peakeater = p.callPackage /home/kalki/agent-work/foss-plugins/pkgs/peakeater { juceRuntime = p.callPackage (f.outPath + "/lib/juce-runtime.nix") {}; pluginArtifacts = p.callPackage (f.outPath + "/lib/plugin-artifacts.nix") {}; }; in p.callPackage /home/kalki/agent-work/foss-plugins/tests/peakeater.nix { inherit peakeater; }'
```

Before creating the derivation, the test build was run with the same expression
and `--cores 4 --max-jobs 1 --no-link` (without `--print-out-paths`). It failed
with `path '/home/kalki/agent-work/foss-plugins/pkgs/peakeater' does not exist`.
That established the expected missing-package failure before implementation.

Package output:

```text
/nix/store/bvdynw5my321yax8dpbjp99higw91bkk-peakeater-0.8.2
```

Final regression output:

```text
/nix/store/gaianpbiz6wpmr7jgxqzjqzk3s90a2ai-foss-plugins-peakeater-artifacts
```

Verified layout and exported entrypoints (all libraries open with `RTLD_NOW`):

| Installed path relative to output | Entrypoint |
| --- | --- |
| `lib/vst3/peakeater.vst3/Contents/x86_64-linux/peakeater.so` | `GetPluginFactory` |
| `lib/clap/peakeater.clap` | `clap_entry` |
| `lib/lv2/peakeater.lv2/libpeakeater.so` | `lv2_descriptor`, `lv2ui_descriptor` |

The LV2 bundle contains nonempty `manifest.ttl`, `dsp.ttl` and `ui.ttl`.
The manifest names `libpeakeater.so`, plugin URI
`https://github.com/vvvar/PeakEater`, and its `:UI` X11 UI. There is no `bin`
output. The regression also resolves and opens `libX11.so.6`, `libXcursor.so.1`,
`libXinerama.so.1` and `libXrandr.so.2` from the CLAP object's RPATH.

ELF inspection command (exit 0; `ldd` reported no `not found` dependencies):

```bash
for so in /nix/store/bvdynw5my321yax8dpbjp99higw91bkk-peakeater-0.8.2/lib/vst3/peakeater.vst3/Contents/x86_64-linux/peakeater.so /nix/store/bvdynw5my321yax8dpbjp99higw91bkk-peakeater-0.8.2/lib/clap/peakeater.clap /nix/store/bvdynw5my321yax8dpbjp99higw91bkk-peakeater-0.8.2/lib/lv2/peakeater.lv2/libpeakeater.so; do readelf -d "$so"; ldd "$so"; done
```

All three have direct `DT_NEEDED` entries for `libasound.so.2`,
`libfreetype.so.6`, `librt.so.1`, `libdl.so.2`, `libpthread.so.0`,
`libstdc++.so.6`, `libm.so.6`, `libgcc_s.so.1`, and `libc.so.6`.
VST3 additionally lists `ld-linux-x86-64.so.2`.
Transitive resolution includes bzip2, libpng, Brotli and zlib. Their RUNPATHs
also retain the shared helper's ALSA, Expat, Fontconfig, FreeType, libGL,
X11, Xcursor, Xext, Xinerama, Xrandr, Xrender and XScreenSaver libraries.

Verification covers packaging, dependency resolution and entrypoint presence.
It does not exercise audio processing, GUI behavior or DAW/host compatibility.
The upstream build emits nonfatal shadowing/overloaded-virtual and serial-LTO
warnings; all selected targets finish successfully.
