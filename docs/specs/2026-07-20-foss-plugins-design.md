# FOSS Plugins Flake Design

## Purpose

Create a GPL-3.0-or-later Nix flake that provides reproducible native Linux
audio-plugin packages which are not already available from nixpkgs.  Consumers
add the flake as an input and select package outputs directly in NixOS or Home
Manager package lists.

The repository initially supports `x86_64-linux` only.  It makes no claim of
macOS or Windows support merely because an upstream project may advertise
those targets.

## Scope

The flake packages these canonical upstream projects:

| Package attribute | Upstream | Expected license status |
| --- | --- | --- |
| `amsynth` | [amsynth/amsynth](https://github.com/amsynth/amsynth) | Free: GPL-2.0-or-later |
| `modal-synth` | [crispinha/modal-synth](https://github.com/crispinha/modal-synth) | Free: GPL-3.0-or-later |
| `rdpiano` | [giulioz/rdpiano](https://github.com/giulioz/rdpiano) | Free: GPL-3.0 |
| `space-dust-synthesizer` | [gadalleore/Space_Dust_Synthesizer](https://github.com/gadalleore/Space_Dust_Synthesizer) | Free: MIT at the selected tag |
| `squelchbox` | [Hornfisk/squelchbox](https://github.com/Hornfisk/squelchbox) | Free: GPL-3.0-or-later |
| `ultramaster-kr106` | [kayrockscreenprinting/ultramaster_kr106](https://github.com/kayrockscreenprinting/ultramaster_kr106) | Free: GPL-3.0 |
| `mechanodd` | [odoare/Mechanodd](https://github.com/odoare/Mechanodd) | Unknown; explicitly opt-in only |

`vaporizer2`, `string-machine`, and `tunefish` are deliberately not duplicated
because nixpkgs already supplies them.

## Public interface

The primary interface is the package output, intended to be used directly by
consumers:

```nix
inputs.foss-plugins.packages.${pkgs.stdenv.hostPlatform.system}.rdpiano
```

The flake also exports:

- `overlays.default`, which adds a collision-free `pkgs.fossPlugins` package
  set; and
- `nixosModules.default`, an opt-in module that installs an explicitly chosen
  package list.

The package set has no implicit default or aggregate package.  Consumers must
select packages explicitly.

## Repository layout

```text
flake.nix                 # Public flake outputs and root nixpkgs pin
pkgs/default.nix          # Pure package-set factory; no nixpkgs import
pkgs/<plugin>/default.nix # One source pin and package recipe per plugin
lib/plugin-artifacts.nix  # Manifest-driven artifact installer and validator
modules/default.nix       # Opt-in NixOS package-selection module
tests/                    # Structural, module, license, and fixture checks
README.md                 # Consumer documentation and upstream attribution
LICENSE                   # GPL-3.0-or-later text
```

`flake.nix` pins nixpkgs.  Each individual package recipe pins its own
immutable upstream revision and fixed source hash.  This keeps unrelated
upstream updates local to their package recipe while retaining reproducible
Nix-store inputs.

`pkgs/default.nix` receives `callPackage`, `lib`, and any other dependencies
from its caller.  It must never import nixpkgs itself.  The regular package
outputs call this factory with the flake's pinned package set; the overlay
calls it through `final.callPackage` so packages inherit the consumer's final
package set and overlays.

## Package output layout

Each recipe uses its native build system rather than forcing a generic plugin
builder:

- amsynth uses its Autotools build;
- the JUCE/CMake projects retain project-specific configuration and build
  flags;
- rdpiano retains its generated JUCE build path;
- squelchbox uses a pinned Rust dependency graph.

All recipes install into conventional store locations:

- VST3 artifacts: `$out/lib/vst3`;
- LV2 artifacts: `$out/lib/lv2`;
- CLAP artifacts: `$out/lib/clap`;
- standalone programs: `$out/bin`.

The installer preserves each declared native artifact layout.  A VST3, LV2,
or CLAP artifact may be a file or a bundle directory according to its package
manifest; directory bundles are copied intact and never flattened.  Standalone
program modes and names are preserved.

## Manifest-driven artifact installation

`lib/plugin-artifacts.nix` accepts a package-declared artifact manifest.  An
entry specifies:

- format (`vst3`, `lv2`, `clap`, or `standalone`);
- a fixed relative source path or a narrowly scoped relative pattern;
- the expected artifact type (regular file, executable, or directory bundle);
- the destination name; and
- whether the artifact is required.

The helper must not perform unconstrained discovery across a build tree.
Before copying an entry, it validates all of the following:

1. paths are relative, do not contain traversal components, and remain below
   the declared source root;
2. a fixed path exists, or a pattern matches exactly one result;
3. the result has the declared file, executable, or directory type;
4. required artifacts are present;
5. destination paths are unique and remain within the intended output
   directory; and
6. copied standalone files retain executable mode.

Any missing artifact, ambiguous pattern, wrong artifact type, duplicate
destination, traversal attempt, or mode loss is a hard build failure.

## Licensing and MechanOdd policy

The repository is licensed GPL-3.0-or-later.  It does not alter or relicense
upstream projects.

Every free package must declare `meta.license`.  Free-package validation
normalizes a single license or a list of licenses to a list and requires every
license object to have both:

- `free = true`; and
- a non-empty SPDX identifier.

MechanOdd has no upstream license declaration.  Its derivation therefore uses
an unfree/unknown-license metadata classification and is excluded from:

- default selections;
- free-package lists;
- free-license checks;
- aggregate checks; and
- all module defaults.

MechanOdd remains lazy throughout the flake.  Constructing normal flake
outputs, applying the overlay, evaluating the module with defaults, and
running checks must not evaluate it or require unfree permission.  It is
resolved only after explicit selection.  The flake never changes
`allowUnfree`, an unfree predicate, or any caller configuration.  Direct
builds require an explicit caller opt-in, for example:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mechanodd
```

NixOS consumers choose their own equivalent unfree policy before explicitly
selecting the package.

## NixOS module

The module is disabled by default:

```nix
programs.foss-plugins.enable = false;
```

It provides validated free-package selections using an enum derived from the
free package names.  MechanOdd is exposed only through a separate
empty-by-default unfree selection option, so default module evaluation remains
fully lazy.  Invalid names fail module evaluation.

When enabled, the module changes only `environment.systemPackages`.  It does
not import, enable, configure, or tune an audio stack; consumers retain full
control of their real-time and plugin-discovery configuration.

## Checks and test strategy

`nix flake check` runs fast structural and fixture checks.  Some checks build
small test derivations; it is not described as evaluation-only.

The check set covers:

- license normalization and explicit free/SPDX assertions for free packages;
- absence of MechanOdd from free and aggregate paths;
- package-manifest schema validation;
- valid NixOS module evaluation and package-name validation; and
- focused fixture tests for the artifact helper.

Artifact fixtures cover successful installation of regular files and bundle
directories, as well as expected failure for missing artifacts, ambiguous
patterns, incorrect artifact types, duplicate destinations, path traversal,
and standalone mode preservation failures.  Successful standalone fixtures
also assert that executable mode survives installation.

Each real package build invokes the same artifact validation during its
installation phase.  Thus `nix build .#<package>` validates the actual output
layout without requiring a costly build-all aggregate check.

## Documentation

The README must:

- link and describe every verified-FOSS upstream centralised by this flake;
- separately document MechanOdd's unknown-license status and opt-in command;
- show direct package-output use in NixOS and Home Manager;
- show optional overlay and NixOS-module use;
- state that real-time tuning is deliberately outside the module's scope; and
- avoid machine-, host-, and external-configuration-specific references.

Generated lock data is kept under version control.  Its generation and update
command are documented near the relevant development workflow rather than
presented as handwritten configuration.
