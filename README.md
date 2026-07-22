# FOSS Audio Plugin Packages

Reproducible Nix packages for free-software audio plugins not already
available in [nixpkgs](https://github.com/NixOS/nixpkgs).

All packages are built for `x86_64-linux`.

## Upstream packages

| Package attribute | Description | Plugin formats | Upstream |
| --- | --- | --- | --- |
| `amsynth` | Analog modelling synthesizer | LV2, standalone | [amsynth/amsynth](https://github.com/amsynth/amsynth) |
| `modal-synth` | Modal synthesis instrument | VST3, standalone | [crispinha/modal-synth](https://github.com/crispinha/modal-synth) |
| `space-dust-synthesizer` | Polyphonic JUCE synthesizer | VST3, standalone | [gadalleore/Space_Dust_Synthesizer](https://github.com/gadalleore/Space_Dust_Synthesizer) |
| `squelchbox` | TB-303-style acid bassline synthesizer | VST3, CLAP, standalone | [Hornfisk/squelchbox](https://github.com/Hornfisk/squelchbox) |
| `ultramaster-kr106` | Juno-6/60/106 emulation | VST3, LV2, CLAP, standalone | [kayrockscreenprinting/ultramaster_kr106](https://github.com/kayrockscreenprinting/ultramaster_kr106) |
| `setekh` | Minimalistic multi-format distortion | VST3, LV2, CLAP | [fullfxmedia/setekh](https://github.com/fullfxmedia/setekh) |
| `ripplerx` | Physical modelling synthesis (modal/waveguide/Karplus-Strong) | VST3, LV2 | [tiagolr/ripplerx](https://github.com/tiagolr/ripplerx) |
| `neuralnote` | Audio-to-MIDI transcription using deep learning | VST3, standalone | [DamRsn/NeuralNote](https://github.com/DamRsn/NeuralNote) |

### Conditional and unfree packages

Packages excluded from pure evaluation that require explicit opt-in.  They are
not part of any default or aggregate selection.  Each package is classified by
the reason it is gated:

| Category | Meaning |
| --- | --- |
| `licensing-uncertainty` | Missing or ambiguous upstream license |
| `experimental` | Runtime dependencies (e.g. local LLM) that require consumer review |
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
