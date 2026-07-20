# FOSS Plugins Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package the supported novel audio plugins as reproducible native Linux Nix derivations with safe free/unfree boundaries, standard plugin layouts, and a consumer-facing flake interface.

**Architecture:** A single pinned nixpkgs input supplies the build environment. `pkgs/default.nix` is a pure factory invoked by both flake outputs and the consumer overlay; it separates free packages from lazy conditional packages. Per-plugin recipes use a manifest-driven artifact installer to copy only declared artifacts into standard VST3, LV2, CLAP, and standalone locations.

**Tech Stack:** Nix flakes, nixpkgs 26.05, Autotools, CMake/Ninja/JUCE, Rust `buildRustPackage`, Bash fixture derivations, NixOS modules.

## Global Constraints

- Support `x86_64-linux` only.
- Keep `pkgs/default.nix` free of nixpkgs imports; inject dependencies with `callPackage`.
- Construct overlay packages with the consumer's `final.callPackage`.
- Keep `mechanodd` and `rdpiano` lazy, absent during pure inspection, free-only paths, defaults, and aggregate checks.
- Never set `allowUnfree` or `allowUnfreePredicate` internally.
- Conditional package builds require caller-controlled `NIXPKGS_ALLOW_UNFREE=1` and `--impure`.
- Normalize every free package `meta.license` to a list; every listed object must have `free = true` and a non-empty `spdxId`.
- Preserve declared VST3, LV2, and CLAP files or bundle directories without flattening them; preserve standalone executable modes.
- The NixOS module defaults to disabled, validates names, and changes only `environment.systemPackages`.
- Do not add machine-specific or external-configuration-specific references to repository files.
- `nix flake check` runs fast structural and fixture derivations; real package builds validate their installed artifact manifests.

## Source Pins and Artifact Contracts

| Package | Revision | Fixed source hash | Artifact manifest |
| --- | --- | --- | --- |
| amsynth | `release-2.0.0` / `ac565864246f9cc45082c77efb96e9ad14ce9833` | `sha256-5vZkMWY5mk31H40F9Bvb77+mGfULaWAcdCDHGHQXClM=` | `amsynth.lv2` directory, `amsynth` executable |
| modal-synth | `50ffe92f34866685bb5f4c55d827039cfee6ef26` | `sha256-QXACmFM0NaiLdDik1ESlIO4QDQxxa0EylpQKu1F5GZI=` | `Modal synthesiser.vst3` directory, `Modal synthesiser` executable |
| space-dust-synthesizer | `1d07997ce14e4c72a1e50c7cf4ff3c74595c23fb` | `sha256-yyonO+s+VCm8ikfGTdFb82zu3DRhhjotNJQLsnPusCs=` | `Space Dust.vst3` directory, `Space Dust` executable |
| ultramaster-kr106 | `bc15caee5843ab238a25d0969e68d57db2b1615f` | `sha256-R0nvtdhhrT+ucpBSsWjJEUCInd4/0jDammlUsaCgL6M=` | VST3/LV2 directories, CLAP and standalone executables |
| squelchbox | `6d0cebc304237cf8df19998d4fbad50b828b862a` | `sha256-e4bAWUhApUfQ70QE5rOdrwgJ/AFoXH1pY4M9orDOLAs=` | VST3 directory, CLAP and standalone executables |
| rdpiano | `995e0679d6b9f1c8546d4924742f46f6e0d4741c` | `sha256-nBJ3NInwuT4KMGY5HpycfbZ4GjuEGQIqMqpoyUGT/TA=` | VST3/LV2 directories, standalone executable |
| mechanodd | `d9970ad0a25fff49740f9cfa5f5b0f1390fe2911` | `sha256-Ydjaho9iu8sACW8ANEyLS3PAO0olwCezvpXf80aoz78=` | VST3 directory, standalone executable |

Shared JUCE source pin: `29396c22c93392d6738e021b83196283d6e4d850`, `sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=`.

## File Structure

```text
flake.nix                         # Public outputs, lazy conditional gate, checks
lib/package-metadata.nix          # License normalization and free-package assertions
lib/plugin-artifacts.nix          # Manifest validation and controlled artifact copying
lib/juce-runtime.nix              # Shared JUCE runtime library/RPATH data
pkgs/default.nix                  # Free and conditional package-set factory
pkgs/amsynth/default.nix
pkgs/modal-synth/default.nix
pkgs/space-dust-synthesizer/default.nix
pkgs/ultramaster-kr106/default.nix
pkgs/squelchbox/default.nix
pkgs/squelchbox/Cargo.lock         # Generated, pinned Cargo resolution
pkgs/rdpiano/default.nix
pkgs/rdpiano/projucer.nix
pkgs/mechanodd/default.nix
modules/default.nix
tests/plugin-artifacts.nix         # Small positive and negative helper fixtures
tests/module-options.nix           # Module option evaluation fixtures
tests/unfree-laziness.sh           # Pure/impure public-interface regression test
README.md
LICENSE
```

---

### Task 1: Harden the spike into a lazy package-set interface

**Files:**
- Modify: `flake.nix`
- Modify: `pkgs/default.nix`
- Modify: `modules/default.nix`
- Move: `tests/mechanodd-laziness.sh` to `tests/unfree-laziness.sh`

**Interfaces:**
- Consumes: the existing pure/impure MechanOdd preflight structure.
- Produces: `packageSet.freePackages`, `packageSet.unfreePackages`, `freePackageNames`, and `unfreePackageNames` while retaining the two temporary spike derivations until their real recipes exist.

- [ ] **Step 1: Write a failing package-set check for the split maps.**

Replace the current check body with:

```nix
free-package-set =
  assert packageSet ? freePackageNames;
  assert packageSet ? unfreePackageNames;
  assert !(builtins.elem "mechanodd" packageSet.freePackageNames);
  assert builtins.elem "mechanodd" packageSet.unfreePackageNames;
  pkgs.runCommand "foss-plugins-free-package-set" { } ''
    touch "$out"
  '';
```

- [ ] **Step 2: Run the check and confirm the existing flat package set fails it.**

Run: `nix build --no-link .#checks.x86_64-linux.free-package-set`  
Expected: evaluation failure because `unfreePackageNames` is missing.

- [ ] **Step 3: Replace the flat spike package set with lazy free and conditional maps.**

Implement this intermediate shape. Keep only existing spike derivations until
their real packages are added in later tasks:

```nix
{ callPackage }:

rec {
  freePackages = {
    "free-spike" = callPackage ./free-spike.nix { };
  };

  unfreePackages = {
    mechanodd = callPackage ./mechanodd-spike.nix { };
  };

  freePackageNames = builtins.attrNames freePackages;
  unfreePackageNames = builtins.attrNames unfreePackages;
}
```

Use the same conditional map in both public interfaces:

```nix
packageSet.freePackages // nixpkgs.lib.optionalAttrs unfreeOptIn packageSet.unfreePackages
```

and in the overlay:

```nix
fossPlugins = packageSet.freePackages // final.lib.optionalAttrs unfreeOptIn packageSet.unfreePackages;
```

Keep `unfreeOptIn = builtins.getEnv "NIXPKGS_ALLOW_UNFREE" == "1";`; do not add any nixpkgs configuration.

- [ ] **Step 4: Make module selection lazy and validated.**

Use the names supplied by the package set:

```nix
packages = lib.mkOption {
  type = lib.types.listOf (lib.types.enum packageSet.freePackageNames);
  default = [ ];
};

unfreePackages = lib.mkOption {
  type = lib.types.listOf (lib.types.enum packageSet.unfreePackageNames);
  default = [ ];
};

config = lib.mkIf cfg.enable {
  environment.systemPackages =
    map (name: packageSet.freePackages.${name}) cfg.packages
    ++ map (name: packageSet.unfreePackages.${name}) cfg.unfreePackages;
};
```

- [ ] **Step 5: Run the pure and impure interface regression.**

Run: `bash tests/unfree-laziness.sh`  
Expected: pure `flake show` and `flake check` succeed; the impure attribute list contains MechanOdd.

- [ ] **Step 6: Commit the public boundary.**

```bash
git add flake.nix flake.lock pkgs/default.nix modules/default.nix tests/unfree-laziness.sh
git rm tests/mechanodd-laziness.sh
git commit -m "feat: add lazy conditional package boundary"
```

### Task 2: Add manifest-driven artifact installation and fixtures

**Files:**
- Create: `lib/plugin-artifacts.nix`
- Create: `tests/plugin-artifacts.nix`
- Modify: `flake.nix`

**Interfaces:**
- Consumes: package `installPhase` paths.
- Produces: `pluginArtifacts.install { sourceRoot; artifacts; }`, returning a shell fragment that installs exact artifacts under `$out`.

- [ ] **Step 1: Write fixtures before the helper.**

Create fixtures that run a tiny shell build tree and assert these cases:

```nix
{
  valid-file-and-bundle = { source = "build/Plugin.clap"; type = "executable"; destination = "Plugin.clap"; };
  missing-artifact = { source = "build/missing.clap"; type = "executable"; destination = "missing.clap"; };
  ambiguous-pattern = { pattern = "build/*.clap"; type = "executable"; destination = "Plugin.clap"; };
  wrong-type = { source = "build/Plugin.vst3"; type = "executable"; destination = "Plugin.vst3"; };
  duplicate-destination = [ "first.clap" "first.clap" ];
  traversal = "../escape.clap";
}
```

The positive fixture creates an executable `build/Plugin.clap` with mode `751` and a `build/Plugin.vst3` directory. It asserts the installed CLAP mode remains `751` and the VST3 bundle retains `Contents/x86_64-linux/Plugin.so`. Each negative fixture succeeds only when the helper fails.

- [ ] **Step 2: Run the fixture expression and confirm it fails because the helper is absent.**

Run: `nix build --no-link .#checks.x86_64-linux.plugin-artifacts`  
Expected: evaluation failure for missing `lib/plugin-artifacts.nix`.

- [ ] **Step 3: Implement the helper with static and runtime validation.**

Expose this contract:

```nix
pluginArtifacts.install {
  sourceRoot = "build";
  artifacts = [
    {
      format = "vst3";
      source = "Plugin.vst3";
      type = "directory";
      destination = "Plugin.vst3";
    }
  ];
}
```

Reject an entry unless exactly one of `source` and `pattern` is supplied. Allow only `vst3`, `lv2`, `clap`, and `standalone`; map them to `lib/vst3`, `lib/lv2`, `lib/clap`, and `bin`. Reject absolute paths, empty segments, `.` segments, `..` segments, `**` patterns, unsupported types, and duplicate `${format}/${destination}` values before the build shell runs.

The generated shell must use `compgen -G "$source_root/$pattern"` for declared patterns, require exactly one result, and never call `find`. It must use `cp -a` for files and directories, verify the requested type before copying, and compare standalone source/destination modes with `stat -c %a`.

- [ ] **Step 4: Register the fixture check.**

Add this exact output:

```nix
plugin-artifacts = pkgs.callPackage ./tests/plugin-artifacts.nix {
  inherit pluginArtifacts;
};
```

- [ ] **Step 5: Run the helper fixtures and the full fast check.**

Run: `nix build --no-link .#checks.x86_64-linux.plugin-artifacts && nix flake check`  
Expected: both commands complete; each negative fixture observes the expected failure internally.

- [ ] **Step 6: Commit helper and fixtures.**

```bash
git add lib/plugin-artifacts.nix tests/plugin-artifacts.nix flake.nix
git commit -m "feat: validate declared plugin artifacts"
```

### Task 3: Enforce free package metadata and module option checks

**Files:**
- Create: `lib/package-metadata.nix`
- Create: `tests/module-options.nix`
- Modify: `flake.nix`

**Interfaces:**
- Produces: `normalizeLicenses`, `isFreeLicense`, and `assertFreePackages`.
- Consumes: `packageSet.freePackages` only; never traverse `unfreePackages`.

- [ ] **Step 1: Write metadata and module evaluation fixtures.**

The metadata fixture must reject `lib.licenses.unfree`, a missing `spdxId`, and a license list containing one non-free entry. The module fixture must accept `[ "free-spike" ]` and reject `[ "not-a-plugin" ]` through `builtins.tryEval`.

- [ ] **Step 2: Confirm the fixtures fail before metadata helpers exist.**

Run: `nix build --no-link .#checks.x86_64-linux.package-metadata`  
Expected: missing helper evaluation failure.

- [ ] **Step 3: Implement explicit license normalization.**

Use this exact logic:

```nix
normalizeLicenses = license: if builtins.isList license then license else [ license ];

isFreeLicense = license:
  (license.free or false) && (license ? spdxId) && license.spdxId != "";

assertFreePackage = package:
  assert lib.all isFreeLicense (normalizeLicenses package.meta.license);
  package;

assertFreePackages = packages:
  lib.mapAttrs (_: assertFreePackage) packages;
```

Use license lists such as `[ lib.licenses.gpl3Plus lib.licenses.agpl3Only ]`; do not use a compound `licenses.AND` wrapper because the required top-level `free` and `spdxId` fields would be absent.

- [ ] **Step 4: Register metadata and module checks.**

Evaluate `assertFreePackages packageSet.freePackages`, assert that neither conditional name occurs in `freePackageNames`, and expose `tests/module-options.nix` as `checks.${system}.module-options`.

- [ ] **Step 5: Run checks.**

Run: `nix flake check`  
Expected: all fast structural and fixture checks pass without `NIXPKGS_ALLOW_UNFREE`.

- [ ] **Step 6: Commit metadata safeguards.**

```bash
git add lib/package-metadata.nix tests/module-options.nix flake.nix
git commit -m "test: enforce free package metadata"
```

### Task 4: Package amsynth from its released source archive

**Files:**
- Create: `pkgs/amsynth/default.nix`
- Modify: `pkgs/default.nix`
- Modify: `tests/module-options.nix`
- Delete: `pkgs/free-spike.nix`

**Interfaces:**
- Produces: free package `amsynth` with `$out/lib/lv2/amsynth.lv2` and `$out/bin/amsynth`.

- [ ] **Step 1: Demonstrate the absent package build.**

Run: `nix build --no-link .#amsynth`  
Expected: attribute-not-found failure.

- [ ] **Step 2: Add the released-source derivation.**

Use the official archive, not a mutable Git checkout:

```nix
src = fetchurl {
  url = "https://github.com/amsynth/amsynth/releases/download/release-2.0.0/amsynth-2.0.0.tar.gz";
  hash = "sha256-5vZkMWY5mk31H40F9Bvb77+mGfULaWAcdCDHGHQXClM=";
};

configureFlags = [
  "--prefix=/usr"
  "--with-gui" "--with-alsa" "--with-jack" "--with-dssi" "--with-nsm"
  "--with-lv2" "--with-vst" "--with-mts-esp" "--without-lash" "--without-oss"
];
```

Use `pkg-config`, `intltool`, `gettext`, and `pandoc` as native inputs; use ALSA, JACK2, DSSI, liblo, FreeType, libpng, zlib, curl, and the required X11 libraries as build inputs. Run `make install DESTDIR="$PWD/stage"`, then use the artifact helper with `sourceRoot = "stage/usr"` to install the exact `lib/lv2/amsynth.lv2` bundle and `bin/amsynth` executable. Set `meta.license = lib.licenses.gpl3Only` because the bundled JUCE route determines the combined free output license.

Replace the `"free-spike"` entry with `amsynth` in `freePackages`, delete `pkgs/free-spike.nix`, and update the positive module fixture to select `[ "amsynth" ]`.

- [ ] **Step 3: Build and assert installed artifacts.**

Run:

```bash
amsynth_out="$(nix build --no-link --print-out-paths .#amsynth)"
test -x "$amsynth_out/bin/amsynth"
test -f "$amsynth_out/lib/lv2/amsynth.lv2/manifest.ttl"
test -x "$amsynth_out/lib/lv2/amsynth.lv2/amsynth_lv2.so"
```

Expected: all assertions pass.

- [ ] **Step 4: Commit amsynth.**

```bash
git add pkgs/amsynth/default.nix pkgs/default.nix tests/module-options.nix
git rm pkgs/free-spike.nix
git commit -m "feat: package amsynth"
```

### Task 5: Package Modal Synth, Space Dust, and Ultramaster KR-106

**Files:**
- Create: `lib/juce-runtime.nix`
- Create: `pkgs/modal-synth/default.nix`
- Create: `pkgs/space-dust-synthesizer/default.nix`
- Create: `pkgs/ultramaster-kr106/default.nix`
- Modify: `pkgs/default.nix`

**Interfaces:**
- Produces: three free packages using declared CMake artifact paths and shared runtime-RPATH data.

- [ ] **Step 1: Prove each package output is absent.**

Run: `nix build --no-link .#modal-synth .#space-dust-synthesizer .#ultramaster-kr106`  
Expected: attribute-not-found failures.

- [ ] **Step 2: Add shared JUCE runtime data.**

Create `lib/juce-runtime.nix` returning the exact `runtimeLibs` and `runtimeRpath`:

```nix
{ lib, alsa-lib, expat, fontconfig, freetype, libGL, libX11, libXcursor
, libXext, libXinerama, libXrandr, libXrender, libXScrnSaver
}:
let
  runtimeLibs = [
    alsa-lib expat fontconfig freetype libGL libX11 libXcursor libXext
    libXinerama libXrandr libXrender libXScrnSaver
  ];
in {
  inherit runtimeLibs;
  runtimeRpath = lib.makeLibraryPath runtimeLibs;
}
```

- [ ] **Step 3: Implement Modal Synth.**

Fetch `50ffe92f34866685bb5f4c55d827039cfee6ef26` with `fetchSubmodules = true` and hash `sha256-QXACmFM0NaiLdDik1ESlIO4QDQxxa0EylpQKu1F5GZI=`. Use `gccStdenv`, `cmake`, `ninja`, `pkg-config`, and `patchelf`; configure with:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DMODAL_BUILD_DOCS=OFF -DMODAL_BUILD_TESTS=OFF \
  -DMODAL_INSTALL_PLUGIN=OFF \
  -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
  -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib
cmake --build build --target ModalSynthPlug_VST3 ModalSynthPlug_Standalone -j"$NIX_BUILD_CORES"
```

Declare the `build/ModalSynthPlug_artefacts/Release/VST3/Modal synthesiser.vst3` directory and `build/ModalSynthPlug_artefacts/Release/Standalone/Modal synthesiser` executable in the helper manifest. Add `runtimeRpath` to the VST3 ELF and standalone executable. Use `[ lib.licenses.gpl3Plus lib.licenses.agpl3Only ]`.

- [ ] **Step 4: Implement Space Dust.**

Fetch `1d07997ce14e4c72a1e50c7cf4ff3c74595c23fb` with hash `sha256-yyonO+s+VCm8ikfGTdFb82zu3DRhhjotNJQLsnPusCs=`. Copy the fixed JUCE 8.0.12 source into a writable `JUCE/` directory, run `python3 patches/apply-juce-mpe-patch.py --juce "$PWD/JUCE"`, and configure with:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DJUCE_DIR="$PWD/JUCE" \
  -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
  -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib \
  -DCMAKE_CXX_FLAGS="-DJUCE_WEB_BROWSER=0 -DJUCE_USE_CURL=0" \
  -DENABLE_VLD=OFF -DENABLE_ASAN=OFF -DENABLE_TSAN=OFF \
  -DENABLE_MEMORY_SAFETY_LOGGING=OFF -DENABLE_TRANSIENT_TEST=OFF
cmake --build build --target SpaceDust_VST3 SpaceDust_Standalone -j"$NIX_BUILD_CORES"
```

Declare `build/SpaceDust_artefacts/Release/VST3/Space Dust.vst3` and `build/SpaceDust_artefacts/Release/Standalone/Space Dust`. Apply the same RPATH treatment and use `[ lib.licenses.gpl3Only lib.licenses.agpl3Only ]`.

- [ ] **Step 5: Implement Ultramaster KR-106.**

Fetch `bc15caee5843ab238a25d0969e68d57db2b1615f` with `fetchSubmodules = true` and hash `sha256-R0nvtdhhrT+ucpBSsWjJEUCInd4/0jDammlUsaCgL6M=`. Configure and build:

```sh
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DKR106_COPY_AFTER_BUILD=OFF
cmake --build build --config Release -j"$NIX_BUILD_CORES"
```

Declare these exact artifacts:

```nix
[
  { format = "vst3"; source = "build/KR106_artefacts/Release/VST3/Ultramaster KR-106.vst3"; type = "directory"; destination = "Ultramaster KR-106.vst3"; }
  { format = "lv2"; source = "build/KR106_artefacts/Release/LV2/Ultramaster KR-106.lv2"; type = "directory"; destination = "Ultramaster KR-106.lv2"; }
  { format = "clap"; source = "build/KR106_artefacts/Release/CLAP/Ultramaster KR-106.clap"; type = "executable"; destination = "Ultramaster KR-106.clap"; }
  { format = "standalone"; source = "build/KR106_artefacts/Release/Standalone/Ultramaster KR-106"; type = "executable"; destination = "Ultramaster KR-106"; }
]
```

Apply runtime RPATHs to the VST3, LV2, CLAP, and standalone ELFs. Use `[ lib.licenses.gpl3Only lib.licenses.agpl3Only ]`.

- [ ] **Step 6: Build each derivation and check its declared layout.**

Run:

```bash
modal_out="$(nix build --no-link --print-out-paths .#modal-synth)"
space_dust_out="$(nix build --no-link --print-out-paths .#space-dust-synthesizer)"
ultramaster_out="$(nix build --no-link --print-out-paths .#ultramaster-kr106)"
test -x "$modal_out/bin/Modal synthesiser"
test -x "$space_dust_out/bin/Space Dust"
test -x "$ultramaster_out/bin/Ultramaster KR-106"
test -x "$ultramaster_out/lib/clap/Ultramaster KR-106.clap"
test -f "$ultramaster_out/lib/lv2/Ultramaster KR-106.lv2/manifest.ttl"
```

Expected: each target build and every declared artifact exists with its expected type.

- [ ] **Step 7: Commit the JUCE packages.**

```bash
git add lib/juce-runtime.nix pkgs/modal-synth/default.nix \
  pkgs/space-dust-synthesizer/default.nix pkgs/ultramaster-kr106/default.nix \
  pkgs/default.nix
git commit -m "feat: package JUCE synthesizers"
```

### Task 6: Package squelchbox with a committed Cargo resolution

**Files:**
- Create: `pkgs/squelchbox/default.nix`
- Create: `pkgs/squelchbox/Cargo.lock`
- Modify: `pkgs/default.nix`

**Interfaces:**
- Produces: free `squelchbox` with VST3, CLAP, and standalone outputs.

- [ ] **Step 1: Demonstrate the missing output.**

Run: `nix build --no-link .#squelchbox`  
Expected: attribute-not-found failure.

- [ ] **Step 2: Add the generated Cargo lockfile with an integrity assertion.**

Commit the generated Cargo 4 lockfile for source `6d0cebc304237cf8df19998d4fbad50b828b862a` after pinning `nih_plug_xtask` to `28b149ec4d62757d0b448809148a0c3ca6e09a95`. Its exact Nix hash is:

```text
sha256-fYi16qqFJ9642sGcU6QFbKEZrY1XtHmw+4bgSX35DiU=
```

Verify it before using it:

```bash
test "$(nix hash file --type sha256 pkgs/squelchbox/Cargo.lock)" = \
  "sha256-fYi16qqFJ9642sGcU6QFbKEZrY1XtHmw+4bgSX35DiU="
```

- [ ] **Step 3: Implement the fixed-output Rust derivation.**

Use `cargoHash = "sha256-mS8uUc9+8kiAOw9uxfXG3KdD6u/ODMMunCgRukAb/TE="`, copy the committed lockfile in `postPatch`, and pin the xtask dependency with:

```sh
substituteInPlace xtask/Cargo.toml \
  --replace-fail \
  'nih_plug_xtask = { git = "https://github.com/robbert-vdh/nih-plug" }' \
  'nih_plug_xtask = { git = "https://github.com/robbert-vdh/nih-plug", rev = "28b149ec4d62757d0b448809148a0c3ca6e09a95" }'
cp ${./Cargo.lock} Cargo.lock
```

Set `CARGO_NET_OFFLINE = "true"`, `auditable = false`, and build exactly:

```sh
cargo xtask bundle squelchbox --release --target x86_64-unknown-linux-gnu
```

Use the artifact helper for `target/bundled/squelchbox.vst3`, `target/bundled/squelchbox.clap`, and `target/x86_64-unknown-linux-gnu/release/squelchbox-standalone`. Use `lib.licenses.gpl3Plus`.

- [ ] **Step 4: Build offline and verify outputs.**

Run:

```bash
squelchbox_out="$(nix build --no-link --print-out-paths .#squelchbox)"
test -x "$squelchbox_out/bin/squelchbox"
test -x "$squelchbox_out/lib/clap/squelchbox.clap"
test -x "$squelchbox_out/lib/vst3/squelchbox.vst3/Contents/x86_64-linux/squelchbox.so"
```

Expected: build completes without sandbox network access and all three paths exist.

- [ ] **Step 5: Commit squelchbox.**

```bash
git add pkgs/squelchbox/default.nix pkgs/squelchbox/Cargo.lock pkgs/default.nix
git commit -m "feat: package squelchbox"
```

### Task 7: Package RDPiano behind the conditional interface

**Files:**
- Create: `pkgs/rdpiano/default.nix`
- Create: `pkgs/rdpiano/projucer.nix`
- Modify: `pkgs/default.nix`

**Interfaces:**
- Produces: lazy conditional `rdpiano`; never add it to a free path.

- [ ] **Step 1: Add an impure-only build assertion to the regression.**

Replace the single conditional-name check in `tests/unfree-laziness.sh` with:

```bash
for conditional_name in mechanodd rdpiano; do
  case "$pure_package_names" in
    *"$conditional_name"*)
      printf '%s\n' "$conditional_name must not appear in pure package output inspection." >&2
      exit 1
      ;;
  esac
done

impure_package_names="$(NIXPKGS_ALLOW_UNFREE=1 "${nix_cmd[@]}" eval --impure --json \
  --no-write-lock-file "$repo_root#packages.$system" --apply 'builtins.attrNames')"
for conditional_name in mechanodd rdpiano; do
  case "$impure_package_names" in
    *"$conditional_name"*) ;;
    *)
      printf '%s\n' "$conditional_name must appear after explicit opt-in." >&2
      exit 1
      ;;
  esac
done
```

Use `NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#rdpiano` as a manual conditional-build test. Do not add it to `nix flake check`.

- [ ] **Step 2: Confirm pure output remains absent.**

Run: `env -u NIXPKGS_ALLOW_UNFREE nix build --no-link .#rdpiano`  
Expected: attribute-not-found failure, not an internal unfree-policy mutation.

- [ ] **Step 3: Implement a pinned Projucer 8.0.1 helper.**

Fetch JUCE commit `46c2a95905abffe41a7aa002c70fb30bd3b626ef` with hash `sha256-2Bx3QHRcYRPrnw2zZzwleUQ+Q1zOKr4bl8cmsT7vUNs=`. Build `extras/Projucer/Builds/LinuxMakefile` with `make CONFIG=Release`, then install `build/Projucer` as `$out/bin/Projucer`. Do not invoke upstream download scripts.

- [ ] **Step 4: Implement the conditional RDPiano derivation.**

Fetch `995e0679d6b9f1c8546d4924742f46f6e0d4741c` with hash `sha256-nBJ3NInwuT4KMGY5HpycfbZ4GjuEGQIqMqpoyUGT/TA=`. Link the fixed JUCE source at `rdpiano_juce/JUCE`, resave the project with the local Projucer, then build:

```sh
${projucer}/bin/Projucer --resave rdpiano_juce/rdpiano_juce.jucer
make -C rdpiano_juce/Builds/LinuxMakefile -j"$NIX_BUILD_CORES" CONFIG=Release
```

Declare and install only:

```nix
[
  { format = "vst3"; source = "rdpiano_juce/Builds/LinuxMakefile/build/rdpiano_juce.vst3"; type = "directory"; destination = "rdpiano_juce.vst3"; }
  { format = "lv2"; source = "rdpiano_juce/Builds/LinuxMakefile/build/rdpiano_juce.lv2"; type = "directory"; destination = "rdpiano_juce.lv2"; }
  { format = "standalone"; source = "rdpiano_juce/Builds/LinuxMakefile/build/rdpiano_juce"; type = "executable"; destination = "rdpiano_juce"; }
]
```

Use `meta.license = lib.licenses.unfree` because the upstream ROM assets have no confirmed redistribution license. Document that the source code is GPL-3.0 while the packaged output remains conditional due to those assets.

- [ ] **Step 5: Build only with explicit caller opt-in.**

Run:

```bash
rdpiano_out="$(NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --print-out-paths .#rdpiano)"
test -x "$rdpiano_out/bin/rdpiano_juce"
test -f "$rdpiano_out/lib/lv2/rdpiano_juce.lv2/manifest.ttl"
test -x "$rdpiano_out/lib/vst3/rdpiano_juce.vst3/Contents/x86_64-linux/rdpiano_juce.so"
```

Expected: the conditional build succeeds and pure outputs remain unchanged.

- [ ] **Step 6: Commit RDPiano.**

```bash
git add pkgs/rdpiano/default.nix pkgs/rdpiano/projucer.nix pkgs/default.nix \
  tests/unfree-laziness.sh
git commit -m "feat: add conditional rdpiano package"
```

### Task 8: Package MechanOdd behind the same conditional interface

**Files:**
- Create: `pkgs/mechanodd/default.nix`
- Modify: `pkgs/default.nix`
- Delete: `pkgs/mechanodd-spike.nix`

**Interfaces:**
- Produces: lazy conditional `mechanodd` with VST3 and standalone artifacts.

- [ ] **Step 1: Confirm the pure interface has no MechanOdd output.**

Run: `env -u NIXPKGS_ALLOW_UNFREE nix flake show --no-write-lock-file .`  
Expected: success; no `mechanodd` package is listed.

- [ ] **Step 2: Compose immutable sources in the package recipe.**

Fetch:

```nix
mechanodd = "d9970ad0a25fff49740f9cfa5f5b0f1390fe2911";
fxmeFX = "391348633cf72b1d773e3b372c4a68f8622a2286";
fxmeTools = "cd19f4b9ff10ce77a4db091abe31ca1f7e7f7c6b";
```

with hashes `sha256-Ydjaho9iu8sACW8ANEyLS3PAO0olwCezvpXf80aoz78=`, `sha256-TdOLKUWNt6ra+eIWnhhDLDI8bbCLa6cNj1QBDlvilrQ=`, and `sha256-/UzxaiqRD81h0MIwza1sa8u0KQs8X+osg1HDMqkWHM8=` respectively. Copy the nested sources into `lib/FxmeFX`, make that tree writable, and patch only these CMake assumptions:

```sh
substituteInPlace CMakeLists.txt \
  --replace-fail 'add_subdirectory(../JUCE JUCE)' "add_subdirectory(${juceSrc} JUCE)" \
  --replace-fail 'COPY_PLUGIN_AFTER_BUILD     TRUE' 'COPY_PLUGIN_AFTER_BUILD     FALSE'
```

- [ ] **Step 3: Build and install declared artifacts only.**

Configure a Release CMake/Ninja build, build `MechanOddBinaryData` serially, then build remaining targets with parallelism two. Use the manifest:

```nix
[
  { format = "vst3"; source = "build/MechanOdd_artefacts/Release/VST3/MechanOdd.vst3"; type = "directory"; destination = "MechanOdd.vst3"; }
  { format = "standalone"; source = "build/MechanOdd_artefacts/Release/Standalone/MechanOdd"; type = "executable"; destination = "MechanOdd"; }
]
```

Set `meta.license = lib.licenses.unfree`; neither this derivation nor the flake may grant unfree permission.

- [ ] **Step 4: Run the required explicit conditional build.**

Run:

```bash
mechanodd_out="$(NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --print-out-paths .#mechanodd)"
test -x "$mechanodd_out/bin/MechanOdd"
test -x "$mechanodd_out/lib/vst3/MechanOdd.vst3/Contents/x86_64-linux/MechanOdd.so"
```

Expected: build and artifact checks pass only with caller opt-in.

- [ ] **Step 5: Commit MechanOdd.**

```bash
git add pkgs/mechanodd/default.nix pkgs/default.nix
git rm pkgs/mechanodd-spike.nix
git commit -m "feat: add conditional mechanodd package"
```

### Task 9: Add consumer documentation, repository license, and final checks

**Files:**
- Create: `README.md`
- Create: `LICENSE`
- Create: `tests/readme-links.sh`
- Modify: `flake.nix`
- Modify: `docs/specs/2026-07-20-foss-plugins-design.md`

**Interfaces:**
- Produces: documented direct-package, overlay, and module consumption without external configuration references.

- [ ] **Step 1: Write README checks before documentation.**

Create `tests/readme-links.sh` with this check:

```bash
#!/usr/bin/env bash
set -euo pipefail

readme_path="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/README.md"

for upstream_url in \
  https://github.com/amsynth/amsynth \
  https://github.com/crispinha/modal-synth \
  https://github.com/gadalleore/Space_Dust_Synthesizer \
  https://github.com/Hornfisk/squelchbox \
  https://github.com/kayrockscreenprinting/ultramaster_kr106 \
  https://github.com/odoare/Mechanodd \
  https://github.com/giulioz/rdpiano; do
  grep -Fqx "$upstream_url" <(grep -o 'https://[^)]*' "$readme_path")
done

grep -Fq "Conditional packages" "$readme_path"
grep -Fq "NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mechanodd" "$readme_path"
grep -Fq "NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#rdpiano" "$readme_path"

if grep -Eq '/home/|hosts/' "$readme_path"; then
  printf '%s\n' "README contains a prohibited external configuration reference." >&2
  exit 1
fi
```

- [ ] **Step 2: Write consumer examples.**

Include direct-package examples:

```nix
environment.systemPackages = [
  inputs.foss-plugins.packages.${pkgs.stdenv.hostPlatform.system}.squelchbox
];

home.packages = [
  inputs.foss-plugins.packages.${pkgs.stdenv.hostPlatform.system}.amsynth
];
```

Include the collision-free overlay example:

```nix
nixpkgs.overlays = [ inputs.foss-plugins.overlays.default ];
environment.systemPackages = [ pkgs.fossPlugins.ultramaster-kr106 ];
```

Include the disabled-by-default module example and state that it only adds `environment.systemPackages`. State that real-time tuning and plugin-path policy remain consumer-owned; musnix is compatible but is neither imported nor configured by this module.

- [ ] **Step 3: Document source and licensing boundaries exactly.**

List the five verified free packages in the main upstream table. Place MechanOdd and RDPiano in a conditional section with this exact command pattern:

```bash
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#mechanodd
NIXPKGS_ALLOW_UNFREE=1 nix build --impure .#rdpiano
```

State that MechanOdd lacks a declared upstream license and that RDPiano embeds ROM assets without an identified redistribution license. State that no package in the flake changes caller unfree settings.

- [ ] **Step 4: Add GPL-3.0-or-later text and generated-lock guidance.**

Add the canonical GPL-3.0 text in `LICENSE`. In README development instructions, state that `flake.lock` is generated by `nix flake lock` and reviewed as generated lock data.

- [ ] **Step 5: Run repository checks and package builds.**

Run:

```bash
nix flake check
bash tests/unfree-laziness.sh
bash tests/readme-links.sh
nix build --no-link .#amsynth .#modal-synth .#space-dust-synthesizer .#squelchbox .#ultramaster-kr106
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link .#mechanodd .#rdpiano
git diff --check
```

Expected: checks and all selected builds complete; only the two explicitly opted-in packages evaluate as conditional outputs.

- [ ] **Step 6: Commit documentation and final validation.**

```bash
git add README.md LICENSE tests/readme-links.sh flake.nix \
  docs/specs/2026-07-20-foss-plugins-design.md
git commit -m "docs: document foss plugin flake"
```
