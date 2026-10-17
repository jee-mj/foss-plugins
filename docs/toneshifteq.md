# ToneShiftEQ 1.3.0

Source: `brummer10/ToneShiftEQ`, tag `v1.3.0`, commit
`2c9798ded641988d59e6d5e79fa88feb2d9ff13c`.
`fetchFromGitHub` uses `fetchSubmodules = true` and recursive hash
`sha256-y85UbyIbkFS8UDxzLg23nPQyqS/GRX1VEcVg5Rr/9Go=`.
The libxputty gitlink is `439d5cd5fed48618f773375ae6624e91ff82ee1e`
from `https://github.com/brummer10/libxputty.git`.

The source has native make targets, not DPF. Build `clap vst3 lv2`:

- `lib/clap/toneshifteq.clap`
- `lib/vst3/Toneshifteq.vst3/Contents/x86_64-linux/Toneshifteq.so`
- `lib/lv2/ToneShiftEQ.lv2/{manifest.ttl,toneshifteq.ttl,toneshifteq.so,toneshifteq_ui.so}`

Installation uses `lib/plugin-artifacts.nix`. The standalone target is omitted.
CPU flags are fixed to baseline x86_64 SSE2 rather than the builder's CPU probe.
Upstream recursive makes force one job; invoke Nix with at most four cores.

## Licensing

The root LICENSE is BSD-3-Clause. Vendored libxputty declares 0BSD,
AudioFFT MIT, travesty ISC, NanoSVG zlib, Roboto fonts Apache-2.0, and
xdgmime AFL-2.0 OR LGPL-2.0-or-later (this package selects AFL-2.0).
These notices are installed under `share/licenses/toneshifteq`.
libxputty's `b64_encode.c` contains Frank4DD/source provenance but no
file-local grant; the package metadata reflects the enclosing libxputty 0BSD
declaration rather than inventing a separate license for that file.

## Public build and artifact test

Run from your clone's Git root:

```sh
nix build --no-link --no-write-lock-file --cores 4 --max-jobs 1 .#toneshifteq
nix build --no-link --no-write-lock-file .#checks.x86_64-linux.toneshifteq
```

These verify source compilation and artifact layout, not DAW compatibility.

## Initial scoped verification record

This tests the package directly before parent-owned export registration:

```sh
nix build --impure --no-link --print-out-paths --cores 4 --max-jobs 1 -L --expr '
  let
    f = builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins";
    pkgs = import f.inputs.nixpkgs { system = "x86_64-linux"; };
    pluginArtifacts = pkgs.callPackage /home/kalki/agent-work/foss-plugins/lib/plugin-artifacts.nix {};
    toneshifteq = pkgs.callPackage /home/kalki/agent-work/foss-plugins/pkgs/toneshifteq { inherit pluginArtifacts; };
  in pkgs.callPackage /home/kalki/agent-work/foss-plugins/tests/toneshifteq.nix {
    packageSet.freePackages = { inherit toneshifteq; };
  }'
```

The test was written first and evaluated with `packageSet.freePackages = {}`;
it failed at the expected missing-`toneshifteq` assertion before implementation.
The test checks nonempty plugin binaries and LV2 metadata without launching a GUI.
The integrated regression additionally opens all four ELF objects with
`RTLD_NOW` and resolves CLAP, VST3, LV2 DSP and LV2 UI entrypoints. It does not
instantiate a plugin, create a GUI or process audio.
