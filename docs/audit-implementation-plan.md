# Deliverable D — Nix Implementation Plan

**Date:** 2026-07-22  
**Repository:** `github:NixOS/nixpkgs` overlay → `foss-plugins` flake  
**Target:** NixOS 26.05, x86_64-linux

---

## 1. Repository structure

```
foss-plugins/
├── flake.nix                          # Existing: package overlay + NixOS module
├── pkgs/
│   ├── default.nix                    # Plugin package set
│   ├── accept-source/                 # Phase 1: approved source-buildable plugins
│   │   ├── setekh/default.nix
│   │   ├── neuralnote/default.nix
│   │   └── ripplerx/default.nix
│   ├── accept-experimental/           # Phase 2: quarantined experimental plugins
│   │   └── cavey/default.nix
│   ├── binary-only/                   # Phase 3: proprietary binary wrappers
│   │   └── mt-power-drum-kit/default.nix
│   └── lib/                           # Shared build infrastructure
│       ├── juce-fetchcontent.nix      # Replace FetchContent/CPM with pre-fetched deps
│       ├── onnxruntime-neuralnote.nix # Fixed-output derivation for ONNX Runtime
│       └── plugin-artifacts.nix       # Existing artifact helper
├── modules/
│   └── default.nix                    # NixOS module with reviewed/experimental/unfree groups
└── docs/
    ├── audit-executive-matrix.md      # Deliverable A
    ├── audit-source-manifest.json     # Deliverable C
    ├── neuralnote-review.md           # Detailed NeuralNote review
    └── audit-implementation-plan.md   # This file
```

---

## 2. Phase 1: accept-source candidates (immediate packaging)

### 2.1 Setekh

**Strategy:** Replace CPM.cmake with pre-fetched sources.

```
pkgs/accept-source/setekh/default.nix
```

```nix
{ lib, stdenv, fetchFromGitHub, cmake, pkg-config
, freetype, libGL, libX11, libXcursor, libXext, libXinerama, libXrandr
, alsa-lib, curl, fontconfig, libjack2, lv2
}:

let
  juce = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "8.0.8";  # Exact tag from CMakeLists
    hash = "sha256-...";  # To be filled
  };
  clap-juce-extensions = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "02f91b7";
    hash = "sha256-...";
  };
in
stdenv.mkDerivation rec {
  pname = "setekh";
  version = "unstable-2026-07-22";

  src = fetchFromGitHub {
    owner = "fullfxmedia";
    repo = "setekh";
    rev = "main";
    hash = "sha256-...";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    freetype libGL libX11 libXcursor libXext libXinerama libXrandr
    alsa-lib curl fontconfig libjack2 lv2
  ];

  # Patch CPM usage to use pre-fetched sources
  postPatch = ''
    substituteInPlace plugin/CMakeLists.txt \
      --replace-fail 'CPMAddPackage("gh:juce-framework/JUCE@8.0.8")' \
                      'add_subdirectory(${juce} juce)' \
      --replace-fail 'CPMAddPackage("gh:free-audio/clap-juce-extensions@02f91b7")' \
                      'add_subdirectory(${clap-juce-extensions} clap-juce-extensions)'
  '';

  installPhase = ''
    mkdir -p $out/lib/vst3 $out/lib/lv2 $out/lib/clap
    cp -r Setekh_artefacts/Release/VST3/Setekh.vst3 $out/lib/vst3/
    cp -r Setekh_artefacts/Release/LV2/Setekh.lv2 $out/lib/lv2/
    cp -r Setekh_artefacts/Release/CLAP/Setekh.clap $out/lib/clap/
  '';

  meta = with lib; {
    description = "GPL-3.0 multi-format distortion plugin";
    homepage = "https://fullfxmedia.com/plugins/setekh/";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    fossPlugins = {
      classification = "accept-source";
      formats = [ "vst3" "lv2" "clap" ];
      risk = "low";
    };
  };
}
```

**Patches needed:**
1. CPM.cmake bypass (replace with pre-fetched `JUCE` and `clap-juce-extensions`)
2. Add `juce::ScopedNoDenormals` to `processBlock`

**Expected effort:** 2–4 hours

---

### 2.2 NeuralNote

**Strategy:** Fixed-output derivation for ONNX Runtime. Pre-fetched submodules.

```
pkgs/accept-source/neuralnote/default.nix
```

(Draft derivation already in `docs/neuralnote-review.md` §11.)

**Patches needed:**
1. Bypass `curl` in `build.sh` — pre-place ONNX Runtime in `ThirdParty/onnxruntime/`
2. Audit and potentially disable update notification
3. Pin submodule commits

**Expected effort:** 3–5 hours

---

### 2.3 RipplerX

**Strategy:** Pin submodules. Simple CMake build.

```
pkgs/accept-source/ripplerx/default.nix
```

**Patches needed:**
1. Pin `libs/JUCE` submodule to explicit commit
2. Pin `libs/MTS-ESP` submodule to explicit commit
3. Optionally patch `MTS_RegisterClient` to be optional at build time

**Expected effort:** 1–3 hours

---

## 3. Phase 2: accept-experimental (quarantined)

### 3.1 Cavey

**Strategy:** Provide as opt-in experimental package. Requires Ollama runtime.

```nix
# pkgs/accept-experimental/cavey/default.nix
# Dependencies: vcpkg-based Boost builds OR system Boost
#               JUCE via pre-fetched source (FetchContent replacement)
#               Runtime: ollama service on localhost

# Mark explicitly as experimental:
meta.fossPlugins = {
  classification = "accept-experimental";
  runtimeDependencies = [ "ollama" ];
  networkSurface = "localhost:11434 only";
  risk = "low";
};
```

**Patches needed:**
1. Replace `FetchContent` JUCE and Catch2 with pre-fetched sources
2. Replace vcpkg Boost with nixpkgs Boost
3. Disable telemetry/logging to filesystem (or make configurable)

**Expected effort:** 4–6 hours

---

## 4. Phase 3: binary-only (manual approval)

### 4.1 MT Power Drum Kit 2

**Strategy:** Fixed-output derivation downloading vendor archive. Must not enter public binary cache.

```nix
# pkgs/binary-only/mt-power-drum-kit/default.nix
{ lib, stdenv, fetchurl, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "mt-power-drum-kit";
  version = "2.1.5.0";

  src = fetchurl {
    url = "https://cdn2.resources.manda-audio.com/DOWNLOADS/products/mtpdk2_free/${version}/MTPDK-${version}-VST3-64bit-Linux-FULL.zip";
    hash = "sha256-...";  # To be filled
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/lib/vst3
    cp -r *.vst3 $out/lib/vst3/
  '';

  meta = with lib; {
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    fossPlugins = {
      classification = "binary-only-manual-approval";
      redistribution = "prohibited-by-eula";
      risk = "high-uninspected";
    };
  };
}
```

**Pre-requisites:**
1. EULA review — must explicitly permit or prohibit redistribution
2. Binary inspection — `readelf`, `strings`, network/firewall testing
3. Runtime isolation testing — Carla with network denied

**Expected effort:** 2–4 hours (EULA + binary inspection only; packaging is trivial)

---

## 5. NixOS module extension

```
modules/default.nix
```

```nix
{ config, lib, pkgs, ... }:

let
  cfg = config.programs."foss-plugins";
in
{
  options.programs."foss-plugins" = {
    enable = lib.mkEnableOption "FOSS audio plugins";

    reviewed = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Approved source-buildable plugins for normal use";
    };

    experimental = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Opt-in experimental plugins requiring explicit review acceptance";
    };

    unfree = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Vendor binaries with explicit licensing controls";
    };
  };

  config = lib.mkIf cfg.enable {
    # Plugin paths auto-configured based on selected groups
    environment.variables = lib.mkMerge [
      (lib.mkIf (cfg.reviewed != []) {
        VST3_PATH = "${lib.makeSearchPath "lib/vst3" (map (p: pkgs.fossPlugins.${p}) cfg.reviewed)}";
        LV2_PATH = "${lib.makeSearchPath "lib/lv2" (map (p: pkgs.fossPlugins.${p}) cfg.reviewed)}";
        CLAP_PATH = "${lib.makeSearchPath "lib/clap" (map (p: pkgs.fossPlugins.${p}) cfg.reviewed)}";
      })
    ];
  };
}
```

---

## 6. Acceptance criteria per candidate

| Candidate | Criteria |
|-----------|----------|
| **Setekh** | VST3+LV2+CLAP build in sandbox. `nix build .#setekh` succeeds twice with identical output. No network during build. |
| **NeuralNote** | VST3 build with FOD ONNX Runtime. Audit confirms update notification is user-initiated only. Font/asset licences verified. |
| **RipplerX** | VST3+LV2 build with pinned submodules. Git history confirms GPL-3.0 continuity. |
| **Cavey** | Builds without network (pre-fetched deps). Only packages `accept-experimental`. Runtime requires Ollama (documented). |
| **OpenKick** | BLOCKED until LICENSE file exists and JUCE is pinned. |
| **Lumen** | BLOCKED until `lumena` submodule is populated or dependency is clarified. |
| **PedalKernel** | BLOCKED for VST3 use. CLI-only package acceptable as experimental if demand exists. |
| **PartialString** | BLOCKED pending upstream contact. No source available. |
| **MT Power Drum Kit 2** | BLOCKED pending EULA review and binary inspection. |

---

## 7. Rollback strategy

- Each plugin is an independent derivation. A broken plugin does not affect others.
- `fossPlugins` overlay isolates packages from main nixpkgs tree.
- NixOS module `reviewed`/`experimental`/`unfree` groups allow per-plugin opt-in/opt-out.
- Downgrade: pin to prior commit of `foss-plugins` flake.
- Binary cache: never publish `unfree` group. Experimental group published only with explicit warnings.

---

## 8. Build reproducibility checklist

For every accept-source candidate:
- [ ] `SOURCE_DATE_EPOCH` set to commit timestamp
- [ ] No `__DATE__`, `__TIME__`, or build timestamps in output
- [ ] No embedded build paths (patch CMake/JUCE to use relative paths or strip)
- [ ] Two consecutive builds produce bit-identical VST3 bundles (or documented differences)
- [ ] No random UUIDs, nonces, or timestamps in plugin identifiers
