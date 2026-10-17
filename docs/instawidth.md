# InstaWidth source package

`pkgs/instawidth/default.nix` builds the canonical
[`hariel1985/InstaWidth`](https://github.com/hariel1985/InstaWidth) source on
`x86_64-linux`. The package version is `1.0.0-unstable` (CMake declares 1.0.0;
the source is pinned by commit, not a release tag).

## Immutable sources

| Source | Revision | Recursive SHA-256 |
| --- | --- | --- |
| hariel1985/InstaWidth | `fcefc76077b7ec8f03d1a52deef475146cf67fd1` | `sha256-W96k/YxYVIb1pcbVH6Qq/kdN/tvL40qyVeNeyR+6yb8=` |
| juce-framework/JUCE (8.0.12) | `29396c22c93392d6738e021b83196283d6e4d850` | `sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=` |

Upstream uses an unpinned sibling JUCE 8 checkout. This derivation replaces
that path with the fixed-output JUCE source. CMake is fully disconnected;
there are no build-time downloads, model weights, firmware, or installers.
The normal Nix source-fetch phase may use the network.

## Installed formats

- `lib/vst3/InstaWidth.vst3/Contents/x86_64-linux/InstaWidth.so`
- `lib/lv2/InstaWidth.lv2/libInstaWidth.so`, with `manifest.ttl`, `dsp.ttl`,
  and `ui.ttl` in the same bundle.

The package uses `pluginArtifacts` for exact bundle installation and
`juceRuntime` for Linux libraries and explicit runtime RPATH. Only VST3 and LV2
targets are built. AU is a macOS format. There is no standalone application.

## Build and verify

Run from this repository's Git root, with these new source files tracked or
staged so they are visible through the Git source boundary:

```sh
export ROOT="$(git rev-parse --show-toplevel)"
nix build --impure --no-link --print-out-paths --cores 4 --max-jobs 1 --expr '
  let
    f = builtins.getFlake ("git+file://" + builtins.getEnv "ROOT");
    p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    instawidth = p.callPackage (f.outPath + "/pkgs/instawidth") {
      juceRuntime = p.callPackage (f.outPath + "/lib/juce-runtime.nix") {};
      pluginArtifacts = p.callPackage (f.outPath + "/lib/plugin-artifacts.nix") {};
    };
  in {
    package = instawidth;
    check = p.callPackage (f.outPath + "/tests/instawidth.nix") { inherit instawidth; };
  }'
```

This builds the source and the artifact check sequentially. The check verifies
LV2 metadata and licenses, loads both shared libraries with immediate symbol
resolution, checks `GetPluginFactory`, `lv2_descriptor`, and `lv2ui_descriptor`,
and resolves JUCE's dynamically loaded X11 libraries through each binary's RPATH.
It does not open a GUI or require audio hardware. Both artifact checks were
first run against an empty output and correctly rejected it before the package
derivations were added. The real source build and installed-artifact check pass.

The locked nixpkgs API and live NixMCP search were checked before introducing
this derivation: neither provided `instawidth`. The same locked API provides
`reevr` 1.4.0, `wolf-shaper` 1.0.2, and `vaporizer2`
3.5.0-unstable-2024-09-14 for reuse by callers.

## Licensing

The upstream README explicitly grants GPL-3.0-or-later. The embedded Rajdhani
font is identified upstream as SIL OFL. JUCE 8.0.12's actual `LICENSE.md` says
AGPLv3 or commercial; the package records the open-source AGPLv3 terms as well
as the project/font licenses. The upstream LICENSE, README, and JUCE license
are installed under `share/doc/instawidth/`.
