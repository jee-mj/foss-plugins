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

### Conditional packages

Two packages are excluded from pure evaluation and require explicit opt-in
because of upstream licensing uncertainty.  They are not part of any default
or aggregate selection.

| Package attribute | Description | Plugin formats | Upstream | Restriction |
| --- | --- | --- | --- | --- |
| `mechanodd` | Physical-modelling synthesizer | VST3, standalone | [odoare/Mechanodd](https://github.com/odoare/Mechanodd) | No declared upstream license |
| `rdpiano` | Physical modeling piano | VST3, LV2, standalone | [giulioz/rdpiano](https://github.com/giulioz/rdpiano) | Embeds ROM assets without identified redistribution license |

Build either conditional package with an explicit unfree opt-in:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mechanodd
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#rdpiano
```

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

When enabled, the module only adds `environment.systemPackages`.  It does not
import, enable, configure, or tune an audio stack, real-time scheduling,
plugin search paths, or any audio service.  Real-time tuning and plugin-path
policy remain consumer-owned.

[musnix](https://github.com/musnix/musnix) is compatible with these packages
but is neither imported nor configured by this module.

## License

This repository is licensed [GPL-3.0-or-later](LICENSE).  It does not alter or
relicense upstream projects.

Each free package declares `meta.license`.  Upstream licenses include
GPL-3.0-only, GPL-3.0-or-later, and AGPL-3.0-only in various combinations
across the combined build outputs.  Refer to the per-package source
repository, derivation metadata, and `flake.nix` checks for details.

MechanOdd has no declared upstream license.  RDPiano embeds ROM binary assets
without an identified redistribution license.  Both are classified as unfree
for metadata purposes and require explicit opt-in.

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

### Lock file

`flake.lock` is generated lock data produced by `nix flake lock` and committed
for reproducibility.  It is not hand-authored configuration.  Update it after
changing flake inputs:

```bash
nix flake update
```

Review the resulting diff before committing.
