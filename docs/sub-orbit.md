# Sub-Orbit source package

`pkgs/sub-orbit/default.nix` builds the canonical
[`echoeslabmusic/Sub-Orbit`](https://github.com/echoeslabmusic/Sub-Orbit) source
on `x86_64-linux`. Its package version is `1.0.0-unstable` (CMake declares
1.0.0; the source is pinned by commit, not a release tag).

## Immutable sources

| Source | Revision | Recursive SHA-256 |
| --- | --- | --- |
| echoeslabmusic/Sub-Orbit | `768bb5b65fd5da637c481f42c002041da24e4d22` | `sha256-0R75shW2yTDAtUEj+JE2sEAnoIF9E5a//koeqVpqpdI=` |
| juce-framework/JUCE (8.0.12) | `29396c22c93392d6738e021b83196283d6e4d850` | `sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=` |
| catchorg/Catch2 (v3.7.1) | `fa43b77429ba76c462b1898d6cd2f2d7a9416b14` | `sha256-Zt53Qtry99RAheeh7V24Csg/aMW25DT/3CN/h+BaeoM=` |

The dependency commits resolve upstream's declared tags. Both CMake
FetchContent source directories are supplied explicitly, with
`FETCHCONTENT_FULLY_DISCONNECTED=ON`. Configuration and compilation require no
network, models, firmware, or installers. Nix may download fixed-output sources
in its normal fetch phase. Pluginval is disabled; upstream Catch2 tests are
built and executed instead.

## Installed format

- `lib/vst3/SUB ORBIT.vst3/Contents/x86_64-linux/SUB ORBIT.so`

The exact bundle is installed through `pluginArtifacts`, with Linux runtime
libraries/RPATH from `juceRuntime`. The upstream Linux-compatible format is
VST3; AU is macOS-only. No LV2, CLAP, or standalone format is claimed.
Position-independent compilation also covers the static core DSP library
linked into the plugin.

## Build and verify

Run from this repository's Git root, with the new source files tracked or
staged for the Git source boundary. Run after the InstaWidth build finishes:

```sh
export ROOT="$(git rev-parse --show-toplevel)"
nix build --impure --no-link --print-out-paths --cores 4 --max-jobs 1 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "ROOT");
    p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    sub-orbit = p.callPackage (f.outPath + "/pkgs/sub-orbit") {
      juceRuntime = p.callPackage (f.outPath + "/lib/juce-runtime.nix") {};
      pluginArtifacts = p.callPackage (f.outPath + "/lib/plugin-artifacts.nix") {};
    };
  in {
    package = sub-orbit;
    check = p.callPackage (f.outPath + "/tests/sub-orbit.nix") { inherit sub-orbit; };
  }'
```

The source build runs `ctest --test-dir build --output-on-failure` with the
requested core limit: all **47 upstream tests pass**, covering DSP, sidechain
behavior, parameter/state round-trips, mono checking, and scope buffering.
The separate installed-artifact check verifies licenses, loads the VST3 with
immediate symbol resolution, checks `GetPluginFactory`, and resolves JUCE's
dynamically loaded X11 libraries through RPATH. It passes without a display or
audio device. The artifact check was first run against an empty output and
correctly failed before the package derivation was added.

The locked nixpkgs API and live NixMCP search were checked before introducing
the derivation: neither provided `sub-orbit`.

## Licensing

Project code is MIT. The embedded PxPlus IBM VGA font is CC BY-SA 4.0, as
recorded in upstream NOTICE. That NOTICE calls JUCE GPLv3, but the pinned JUCE
8.0.12 `LICENSE.md` actually says **AGPLv3 or commercial**. Package metadata
records MIT, AGPLv3, and CC BY-SA 4.0, and installs the unmodified upstream
LICENSE/NOTICE plus the actual JUCE license under `share/doc/sub-orbit/`.
