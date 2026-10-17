# FOSS Audio Plugin Packages

Reusable Nix plugin packages and source-artifact builders, including direct
reuse of three reviewed packages from the locked [nixpkgs](https://github.com/NixOS/nixpkgs).

All package builders run on `x86_64-linux`, with target-specific formats.
Windows artifact packages produce Windows x86-64 payloads and operator installers;
0xFX keeps its installer inside `out`, while the others use a separate output.

The default export set contains **32 free packages**. Explicit conditional opt-in
adds **14 packages**, for **46 total**. These exports remain unpublished source
work; consumer adoption requires explicit source promotion and review.
ToneTwist and DrumCloud remain pending consumer review/acceptance.

## Discover the full audio catalog

The [104-repository catalog](catalog/audio-104.json) also tracks Windows-only,
source-only and not-yet-packaged plugins. Read the [catalog guide](docs/audio-catalog.md)
and [Windows acquisition references](docs/windows-plugin-acquisition.md) for
platform evidence, upstream downloads, usage routes and copyright-safety notes.
Catalog inclusion is not a package export, a rights grant, or a compatibility claim.
The [product/route registry](catalog/products.json) expands all 104 captured
repositories plus the ten additional Basilica repositories into 165 established
source/delivery records. Applications, firmware, unresolved targets, shared
installers and plugin formats are not installed-plugin counts; see the
[product catalog contract](docs/product-catalog.md).
Missing license metadata does not block technical evaluation; consumers are
encouraged to exercise their own judgement. AI-assisted development does not
establish that code or bundled assets are copyright-free.

Query the catalog without building plugins:

```bash
nix eval --json .#catalog
nix eval --json .#productCatalog
python3 tests/audio-catalog.py
```

The catalog is metadata only: it does not install plugins, change existing
free/conditional package classification, or require this workstation's private
installer tooling. The package tables below describe actual package outputs,
not every catalog entry.

## Upstream packages

| Package attribute | Description | Plugin formats | Upstream |
| --- | --- | --- | --- |
| `amsynth` | Analog modelling synthesizer | LV2, standalone | [amsynth/amsynth](https://github.com/amsynth/amsynth) |
| `downspout` | Algorithmic composition, MIDI generation, synthesis and effects (46 bundles) | VST3 | [danja/downspout](https://github.com/danja/downspout) |
| `modal-synth` | Modal synthesis instrument | VST3, standalone | [crispinha/modal-synth](https://github.com/crispinha/modal-synth) |
| `space-dust-synthesizer` | Polyphonic JUCE synthesizer | VST3, standalone | [gadalleore/Space_Dust_Synthesizer](https://github.com/gadalleore/Space_Dust_Synthesizer) |
| `squelchbox` | TB-303-style acid bassline synthesizer | VST3, CLAP, standalone | [Hornfisk/squelchbox](https://github.com/Hornfisk/squelchbox) |
| `ultramaster-kr106` | Juno-6/60/106 emulation | VST3, LV2, CLAP, standalone | [kayrockscreenprinting/ultramaster_kr106](https://github.com/kayrockscreenprinting/ultramaster_kr106) |
| `setekh` | Minimalistic multi-format distortion | VST3, LV2, CLAP | [fullfxmedia/setekh](https://github.com/fullfxmedia/setekh) |
| `ripplerx` | Physical modelling synthesis (modal/waveguide/Karplus-Strong) | VST3, LV2 | [tiagolr/ripplerx](https://github.com/tiagolr/ripplerx) |
| `neuralnote` | Audio-to-MIDI transcription using deep learning | VST3, standalone | [DamRsn/NeuralNote](https://github.com/DamRsn/NeuralNote) |
| `peakeater` | Waveshaping clipper ([build evidence](docs/peakeater.md)) | VST3, LV2, CLAP | [vvvar/PeakEater](https://github.com/vvvar/PeakEater) |
| `toneshifteq` | Twelve-band EQ with spectrum analysis and IR matching ([build evidence](docs/toneshifteq.md)) | VST3, LV2, CLAP | [brummer10/ToneShiftEQ](https://github.com/brummer10/ToneShiftEQ) |
| `intersect` | Slicing sampler, CPU-default optional stem inference ([build evidence](docs/acceleration/intersect-build.md)) | VST3 | [tucktuckg00se/INTERSECT](https://github.com/tucktuckg00se/INTERSECT) |
| `audio-restoration-vst` | Vinyl restoration, CPU-default optional ONNX denoising ([build evidence](docs/acceleration/audio-restoration-vst-build.md)) | VST3 | [flarkflarkflark/AudioRestorationVST](https://github.com/flarkflarkflark/AudioRestorationVST) |
| `instawidth` | Stereo widening ([source evidence](docs/instawidth.md)) | VST3, LV2 | [hariel1985/InstaWidth](https://github.com/hariel1985/InstaWidth) |
| `sub-orbit` | Low-band stereo-width and sidechain-ducking effect ([source evidence](docs/sub-orbit.md)) | VST3 | [echoeslabmusic/Sub-Orbit](https://github.com/echoeslabmusic/Sub-Orbit) |
| `reevr` | REEV-R convolution reverb, locked nixpkgs reuse | VST3, LV2 | [tiagolr/reevr](https://github.com/tiagolr/reevr) |
| `wolf-shaper` | Native waveshaper, locked nixpkgs reuse | VST2, LV2, DSSI, standalone | [wolf-plugins/wolf-shaper](https://github.com/wolf-plugins/wolf-shaper) |
| `vaporizer2` | Wavetable synthesizer, locked nixpkgs reuse | VST3, LV2, CLAP | [VASTDynamics/Vaporizer2](https://github.com/VASTDynamics/Vaporizer2) |
| `wolf-shaper-windows` | Windows source-built artifact package ([evidence](docs/wolf-shaper-windows.md)) | Windows VST3, CLAP; ZIP and NSIS | [wolf-plugins/wolf-shaper](https://github.com/wolf-plugins/wolf-shaper) |

See [locked nixpkgs reuse and integration verification](docs/nixpkgs-audio.md)
for exact versions, observed formats, provenance and cached-build results.
Wolf Shaper's Windows artifact package has real `out` and `installer` outputs:

```bash
nix build --no-link .#wolf-shaper-windows .#wolf-shaper-windows.installer
```

Their payloads live under `payload/VST3` and `payload/CLAP`, with no Linux
`lib` output or plugin directory. Keep these artifacts out of Linux plugin
search paths; transfer the ZIP or installer to the intended Windows host.

The [full-set acceleration matrix](docs/acceleration-matrix.md) distinguishes
assessed source capabilities, CPU build/load checks and experimental GPU routes.
The two ONNX packages compile plugin source against explicitly pinned binary
runtime dependencies; they do not include or automatically acquire models.
Three experimental GPU aliases have linked build and scoped library-load evidence,
not inference or hardware acceptance. AMD hardware execution is deliberately
policy-skipped. Choose only one variant per product: their plugin identities and
bundle names are shared, so they are alternatives, not additive installations.

### Downspout capability notice

`downspout` pins **v0.16.2**, builds from source with vendored DPF, and runs
CTest fail-closed with assertions enabled. The AI coordinator is not built or
installed. Third-party license notices accompany the output.

**Review before activating Campione:** its MCP server defaults on at DSP
activation, listens without authentication on `127.0.0.1:7220–7229`, and can
overwrite source WAVs and write caller-selected patch paths. Sidecar defaults
to local generation but retains an optional localhost coordinator client.
Both plugins are included deliberately; packaging is not host-lifecycle or
security certification. Campione uses DPF's single-file browser instead of
launching `zenity`.

See the [pinned-source audit and host acceptance checklist](docs/downspout.md)
before DAW use. No coordinator, service, or plugin is activated by building this
package.

```bash
nix build --no-link .#downspout
```

### Basilica family: experimental native source definitions

All thirteen individual aliases below are portable, source-audited experimental
Linux VST3 recipes. Miserere reuses its existing reviewed recipe object.
Source definitions and catalog discovery records are distinct from build receipts:
an export does not establish DAW, GUI or audio acceptance.

| Public identity | Package alias | Version | Requested target format |
| --- | --- | --- | --- |
| BA-001 | `basilica-overture` | 0.5.0 | Linux x86-64 VST3 |
| BA-002 | `basilica-tenebrae` | 0.5.0 | Linux x86-64 VST3 |
| BA-003 | `basilica-nave` | 0.5.0 | Linux x86-64 VST3 |
| BA-004 / AUDIO-058 | `basilica-silentium` | 0.5.0 | Linux x86-64 VST3 |
| BA-005 | `basilica-requiem` | 0.5.0 | Linux x86-64 VST3 |
| BA-006 / AUDIO-007 | `basilica-seraph` | 0.4.0 | Linux x86-64 VST3 |
| BA-007 | `basilica-aureate` | 0.5.0 | Linux x86-64 VST3 |
| BA-008 | `basilica-firmament` | 0.4.0 | Linux x86-64 VST3 |
| BA-009 | `basilica-triptych` | 0.6.0 | Linux x86-64 VST3 |
| BA-010 | `basilica-apotheosis` | 0.6.1 | Linux x86-64 VST3 |
| BA-011 | `basilica-crypta` | 0.4.1 | Linux x86-64 VST3 |
| BA-012 | `basilica-lancet` | 0.5.0 | Linux x86-64 VST3 |
| BA-013 / AUDIO-003 | `basilica-miserere` | 0.7.0 | Linux x86-64 VST3 |

`pkgs/default.nix` exposes the helper API as `basilicaFamily`, merging its
`candidateDefinitions` into the free package set. `candidateChecks` supplies the
family checks; the root retains the existing Miserere artifact check and adds
the other twelve as `checks.x86_64-linux.basilica-<name>`.

The helper's receipt-bound `namedPackages`, `checks` and `aggregate` have a
stricter meaning: only the captured matching profile is verified. On locked
nixpkgs `fd146203…`, all thirteen receipts match; alternate public profile
`f5c082a4…` exposes the same thirteen source definitions/check definitions but
zero verified packages/checks and no aggregate. No receipt is transferred between
profiles. The verified aggregate stays helper-only, with complete license
metadata; it is absent from top-level exports and module package names to avoid
co-installing it alongside its members. Nave retains its disclosed scalar
compatibility patch. See the [family API and source-profile evidence](docs/basilica-native-suite.md).

### Conditional and unfree packages

Packages excluded from pure evaluation that require explicit opt-in.  They are
not part of any default or aggregate selection.  Each package is classified by
the reason it is gated:

| Category | Meaning |
| --- | --- |
| `licensing-uncertainty` | Missing or ambiguous upstream license |
| `experimental` | Experimental runtime dependencies or target-specific source-artifact routes requiring consumer review |
| `blocked-pending-upstream` | Source available but license file missing or unverified |
| `binary-only-manual-approval` | Proprietary freeware, must be downloaded manually |

| Package attribute | Description | Plugin formats | Upstream | Category |
| --- | --- | --- | --- | --- |
| `mechanodd` | Physical-modelling synthesizer | VST3, standalone | [odoare/Mechanodd](https://github.com/odoare/Mechanodd) | `licensing-uncertainty` |
| `rdpiano` | Physical modeling piano | VST3, LV2, standalone | [giulioz/rdpiano](https://github.com/giulioz/rdpiano) | `licensing-uncertainty` |
| `cavey` | AI-powered audio effect generator using local LLM (Ollama) | VST3, standalone | [TarcanGul/cavey](https://github.com/TarcanGul/cavey) | `experimental` |
| `openkick` | Lightweight sidechain volume-ducking utility | VST3, standalone | [navidsatarmaker/OpenKick](https://github.com/navidsatarmaker/OpenKick) | `blocked-pending-upstream` |
| `lumen` | Wavetable synthesizer with image-to-tone Lens engine | VST3, standalone | [pixelsncodes/lumen](https://github.com/pixelsncodes/lumen) | `blocked-pending-upstream` |
| `mt-power-drum-kit` | Acoustic drum sampler (MT Power Drum Kit 2) | VST3 | [MT Power Drum Kit](https://www.powerdrumkit.com) | `binary-only-manual-approval` |
| `intersect-cuda12` | INTERSECT with ORT CUDA 12 runtime | VST3 | [INTERSECT evidence](docs/acceleration/intersect-build.md) | `experimental` |
| `intersect-migraphx` | INTERSECT with experimental AMD MIGraphX runtime | VST3 | [INTERSECT evidence](docs/acceleration/intersect-build.md) | `experimental` |
| `audio-restoration-vst-cuda` | Restoration with optional ORT CUDA runtime | VST3 | [Restoration evidence](docs/acceleration/audio-restoration-vst-build.md) | `experimental` |
| `tonetwist-windows` | Six-product Windows source artifact suite; mixed source notices, review pending | Windows VST3, CLAP; ZIP and NSIS | [ToneTwist review](docs/tonetwist-windows.md) | `licensing-uncertainty` |
| `drumcloud-windows` | Windows source artifact package; custom copyright terms, review pending | Windows VST3, CLAP; ZIP and NSIS | [DrumCloud review](docs/drumcloud-windows.md) | `licensing-uncertainty` |
| `toneshifteq-windows` | Approved source-artifact packaging; Master/Live in two bundles | Windows VST3, CLAP; ZIP and separate NSIS output | [ToneShiftEQ evidence](docs/toneshifteq-windows.md) | `experimental` |
| `gunk-windows` | Approved JQ Gunk source-artifact packaging | Windows VST3; manual/source ZIPs and separate NSIS output | [Gunk evidence](docs/gunk-windows.md) | `experimental` |
| `0xfx-windows` | Approved source-artifact packaging; plugins plus GUI and console applications | Windows VST3, CLAP, GUI, console; ZIPs and in-output NSIS installer | [0xFX evidence](docs/0xfx-windows.md) | `experimental` |

These two Windows packages use the existing consumer opt-in policy for their
mixed/custom copyright metadata. This is not a technical feasibility gate or
completed parent acceptance. Their installers are actual separate outputs:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#tonetwist-windows.installer
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#drumcloud-windows.installer
```

ToneShiftEQ, Gunk and 0xFX use that same explicit gate as experimental Windows
source-artifact routes, not as proprietary-license assertions. Packaging approval
and static artifact receipts are not Windows runtime or host acceptance. Their
archived source recipes remain callable with their supplied locks. The linked
isolated-build notes predate this root export registration.

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#toneshifteq-windows.installer
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#gunk-windows.installer
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --print-out-paths .#0xfx-windows
```

For 0xFX, take `installer/0xfx-1.3.0-source-x86_64-setup.exe` beneath the printed
`out` directory. There is no `.#0xfx-windows.installer` selector. All three
artifact packages keep payloads outside Linux plugin directories.

The GPU variants use the existing explicit conditional gate. MIGraphX's placement
here is about validation maturity, **not** a claim that ROCm/MIGraphX is proprietary.
CUDA/cuDNN dependencies retain their vendor terms. Example, without activation:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#intersect-cuda12
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#intersect-migraphx
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#audio-restoration-vst-cuda
```

Review the model-acquisition and cache-only dependency procedures in the linked
build notes before reproducing GPU builds. Library relocation/loading is not GPU
node execution; no models or GPU sessions were exercised in these checks.

Build any conditional package with an explicit unfree opt-in:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#cavey
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mechanodd
```

`mt-power-drum-kit` additionally requires the vendor binary to be placed at
`repackaged/mt-power-drum-kit/pdk2_vst3_linux_2.1.5.0.zip` before building.

NixOS consumers choose their own equivalent unfree policy before selecting
either package.  No package in this flake changes caller unfree settings.

## Consumption

### Direct packages (NixOS)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    foss-plugins.url = "path:/path/to/this/repo";
  };

  outputs = { nixpkgs, foss-plugins, ... }: {
    nixosConfigurations.example = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            foss-plugins.packages.${pkgs.stdenv.hostPlatform.system}.squelchbox
          ];
        })
      ];
    };
  };
}
```

### Direct packages (Home Manager)

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    foss-plugins.url = "path:/path/to/this/repo";
  };

  outputs = { nixpkgs, foss-plugins, ... }: {
    homeConfigurations.example = nixpkgs.lib.homeManagerConfiguration {
      modules = [
        ({ pkgs, ... }: {
          home.packages = [
            foss-plugins.packages.${pkgs.stdenv.hostPlatform.system}.amsynth
          ];
        })
      ];
    };
  };
}
```

### Overlay

A collision-free `pkgs.fossPlugins` attribute set is available through the
default overlay:

```nix
nixpkgs.overlays = [ inputs.foss-plugins.overlays.default ];
environment.systemPackages = [ pkgs.fossPlugins.ultramaster-kr106 ];
```

### NixOS module

The flake exports an opt-in NixOS module that is **disabled by default**:

```nix
{
  imports = [ inputs.foss-plugins.nixosModules.default ];
  programs.foss-plugins = {
    enable = true;
    packages = [ "amsynth" "squelchbox" "ultramaster-kr106" ];
    # unfreePackages = [ "mechanodd" ];  # requires consumer unfree policy
  };
}
```

When enabled, the module adds `environment.systemPackages` and an activation
script that symlinks built plugins into each user's `~/.vst3`, `~/.lv2`, and
`~/.clap` directories.  It does not import, enable, configure, or tune an
audio stack, real-time scheduling, plugin search paths, or any audio service.
Real-time tuning and plugin-path policy remain consumer-owned.

[musnix](https://github.com/musnix/musnix) is compatible with these packages
but is neither imported nor configured by this module.

## License

This repository is licensed [GPL-3.0-or-later](LICENSE).  It does not alter or
relicense upstream projects.

Each free package declares `meta.license`.  Upstream licenses include
GPL-3.0-only, GPL-3.0-or-later, and AGPL-3.0-only in various combinations
across the combined build outputs.  Refer to the per-package source
repository, derivation metadata, and `flake.nix` checks for details.

Unfree packages (mechanodd, rdpiano, cavey, openkick, lumen, mt-power-drum-kit)
are gated behind explicit opt-in; see the conditional packages section for
details on each.

## Development

Clone the repository and enter a development shell:

```bash
git clone <repo-url> && cd <repo-dir>
nix develop
```

Run the structural checks:

```bash
nix flake check
```

Build a free package:

```bash
nix build --no-link .#amsynth
```

### Plugin discovery

After building, symlink plugins into standard DAW directories:

```bash
./link-plugins.sh
```

The NixOS module also provides an activation script that links plugins into
each user's `~/.vst3`, `~/.lv2`, and `~/.clap` directories on activation.

### Lock file

`flake.lock` is generated lock data produced by `nix flake lock` and committed
for reproducibility.  It is not hand-authored configuration.  Update it after
changing flake inputs:

```bash
nix flake update
```

Review the resulting diff before committing.
