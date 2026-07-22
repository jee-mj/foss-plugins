# NeuralNote — Preliminary Security, Provenance, and Nix Packaging Review

**Reviewed:** 2026-07-22  
**Source:** https://github.com/DamRsn/NeuralNote  
**Default branch:** `master`  
**Latest tag:** `v1.1.0` (commit `113f0586bcb0c55202e005a989d50858728e78fb`, 2025-01-11)  
**Licence:** Apache-2.0 (confirmed: `LICENSE` file in repository root, copyright Damien Ronssin)  
**Primary languages:** C++ (93%), CMake, Shell, Python  
**Status:** `accept-source` — preliminary classification, subject to deep review

---

## 1. Identity and provenance

| Field | Value |
|-------|-------|
| Repository | https://github.com/DamRsn/NeuralNote |
| Owner | Damien Ronssin (`DamRsn`) |
| Co-author | Tibor Vass (`tiborvass`) |
| Contributors | jatinchowdhury18 (RTNeural author, file browser), trirpi (scale options, zoom), polygon & SamuMazzi (Linux support), Perrine Morel (UI design) |
| Stars | ~2,800 |
| Commits | 204 on `master` |
| First release | v0.0.1 (2022-03-24) |
| Latest release | v1.1.0 (2025-01-11) |
| Release cadence | Annual major releases; active community |
| Signed tags | v1.0.0 and v1.1.0 signed with GitHub verified signature |
| CI | GitHub Actions present (exact workflows require deeper inspection) |
| Issue tracker | 21 open issues, active response from maintainers |

**Maintainer assessment:** Damien Ronssin is an established developer with a consistent commit history across 2022–2025. Tibor Vass is a known open-source contributor. The project is mature (3+ years), well-starred, and has a healthy contributor graph. Linux support was community-contributed (polygon, SamuMazzi), indicating genuine open-source engagement. No red flags in provenance.

---

## 2. Reviewed revision

| Field | Value |
|-------|-------|
| Tag | `v1.1.0` |
| Commit SHA | `113f0586bcb0c55202e005a989d50858728e78fb` |
| Commit date | 2025-01-11 |
| Signature | GitHub verified (key ID: B5690EEEBB952194) |
| Deep review required | Yes — exact submodule commits must be pinned |

---

## 3. Licence analysis

### Source code
- **Apache-2.0** — full text in repository root. Clean, permissive, redistribution-friendly.

### Dependencies and their licences

| Dependency | Licence | Compatible with Apache-2.0? |
|------------|---------|---------------------------|
| JUCE (submodule) | JUCE Starter (personal/commercial) | **Requires verification** — JUCE Starter grants per-developer personal use. Redistribution of binaries built with the Starter licence may be restricted. Must verify whether the personal licence permits Nix redistribution or if a JUCE Indie/Pro licence is assumed. |
| RTNeural (submodule) | BSD-3-Clause | Yes |
| ONNX Runtime (pre-built) | MIT | Yes |
| basic-pitch (Spotify) | Apache-2.0 | Yes |
| basic-pitch-ts (Spotify) | Apache-2.0 | Yes |
| minimp3 (vendored in `ThirdParty/minimp3`) | CC0-1.0 | Yes |
| ort-builder (build tool) | MIT | Yes |

### Asset licences
- **Model weights** (`Lib/ModelData/*.json`, `Lib/ModelData/features_model.ort`): Derived from Spotify basic-pitch (Apache-2.0). The `.json` weight files were manually extracted from TensorFlow.js → ONNX → NumPy → keras. Train-time data provenance is Spotify's research, not NeuralNote's.
- **Fonts**: `NeuralNote/Assets/*.ttf` — licence must be verified.
- **Icons/images**: `NeuralNote/Assets/*.png`, `*.svg` — licence must be verified.
- **Logo**: `NeuralNote/Assets/logo.png` — copyright Dr. Audio.

### Redistribution assessment
- **Source**: Can be fetched ✅
- **Build**: Can be built in sandbox (with pre-fetched ONNX Runtime) ✅
- **Binary redistribution**: Apache-2.0 permits it, but JUCE Starter licence may restrict commercial redistribution. The plugin binaries published by the project under "Dr. Audio" branding may carry additional constraints.
- **Model weights**: Apache-2.0 permits redistribution ✅
- **Fonts**: Requires verification ⚠️
- **Cache publication**: Safe for source and model weights; binary-cache redistribution requires JUCE licence clarification ⚠️

---

## 4. Repository and dependency structure

```
NeuralNote/
├── CMakeLists.txt          # CMake build, C++17, JUCE plugin
├── build.sh                # Linux/macOS build + ONNX Runtime fetch
├── build.bat               # Windows build + ONNX Runtime fetch
├── .gitmodules             # JUCE, RTNeural submodules
├── Lib/
│   ├── Components/         # UI components (piano roll, waveform, etc.)
│   ├── DSP/                # Audio processing (resampling, synth)
│   ├── MidiPostProcessing/ # Scale/time quantization, MIDI export
│   ├── Model/              # Transcription engine (BasicPitch, Features, Notes)
│   │   ├── BasicPitch.cpp/h        # Main transcription orchestrator
│   │   ├── BasicPitchCNN.cpp/h     # CNN inference via RTNeural
│   │   ├── Features.cpp/h          # CQT + harmonic stacking via ONNX
│   │   ├── Notes.cpp/h             # Note event creation from posteriorgrams
│   │   ├── BasicPitchConstants.h   # Model architecture constants
│   │   └── Utils.h                 # Utility functions
│   ├── ModelData/          # Pre-trained model weights (committed)
│   │   ├── features_model.ort     # ONNX model for CQT+harmonic stacking
│   │   ├── *.json                 # CNN weight matrices
│   ├── Player/             # Audio playback engine
│   └── Utils/              # General utilities
├── NeuralNote/
│   ├── Source/             # Plugin processor, editor
│   ├── PluginSources/      # JUCE module sources
│   └── Assets/             # Fonts, icons, logo
├── ThirdParty/
│   ├── JUCE/               # Git submodule
│   ├── RTNeural/           # Git submodule
│   ├── onnxruntime/        # Pre-built library (not committed — downloaded by build.sh)
│   └── minimp3/            # Vendored MP3 decoder
├── Tests/                  # Unit tests (optional, BUILD_UNIT_TESTS=ON)
└── Installers/             # macOS .pkg and Windows Inno Setup scripts
```

### Build-time network fetches

**CRITICAL:** `build.sh` executes `curl -fsSLO` to download a pre-built ONNX Runtime static library from a GitHub release:

```
https://github.com/tiborvass/libonnxruntime-neuralnote/releases/download/${version}/${archive}
```

Where:
- `version = v1.14.1-neuralnote.0` (Linux)
- `archive = onnxruntime-v1.14.1-neuralnote.0-linux-x86_64.tar.gz`

This archive contains:
- `libonnxruntime.a` (static library)
- `include/` (headers)
- `model.with_runtime_opt.ort` (features model with ONNX Runtime baked in)

For Nix packaging, this fetch must be replaced with a fixed-output derivation using an immutable URL and a known hash. The archive is versioned and tagged on GitHub, making this straightforward.

### Git submodules

| Submodule | URL | Purpose |
|-----------|-----|---------|
| `ThirdParty/JUCE` | `https://github.com/juce-framework/JUCE.git` | Plugin framework |
| `ThirdParty/RTNeural` | `https://github.com/jatinchowdhury18/RTNeural.git` | Real-time neural network inference |

Both are public, well-known repositories. Submodule commits must be recorded during deep review.

### Committed binary/model data

The following binary/model files are committed directly to the repository and included via `juce_add_binary_data`:
- `Lib/ModelData/features_model.ort` — ONNX model
- `Lib/ModelData/*.json` — CNN weight matrices (~8 files)

These are embedded into the plugin binary at compile time. They are not downloaded or modified at runtime. This is a positive finding for supply-chain security — the model is fully vendor-pinned.

---

## 5. Security-sensitive source findings

### Preliminary scan (based on README, CMakeLists.txt, build.sh, repository structure)

#### Network/update behaviour

| Finding | Status |
|---------|--------|
| `JUCE_WEB_BROWSER=0` (compile definition) | ✅ Network disabled at compile time |
| `JUCE_USE_CURL=0` (compile definition) | ✅ HTTP client disabled |
| `JUCE_VST3_CAN_REPLACE_VST2=0` | ✅ No VST2 migration paths |
| v1.1.0 release notes: "Notification when a NeuralNote update is available" | ⚠️ **UPDATE CHECK** — Must verify the implementation. If it uses HTTP, it contradicts the compile-time JUCE_WEB_BROWSER/JUCE_USE_CURL=0 settings. May use platform-native mechanisms. |
| Release notes mention "check for update" | ⚠️ Needs source-level verification |

#### File I/O

| Finding | Status |
|---------|--------|
| Audio file import: .wav, .aiff, .flac, .mp3, .ogg (vorbis) | ⚠️ Parses untrusted formats. .mp3 via minimp3 (vendored, CC0). Others via JUCE internals. Fuzzing recommended. |
| Recording: writes to user data directory (platform-specific: `~/Library/NeuralNote` on macOS, `%APPDATA%` on Windows) | ⚠️ Filesystem write outside plugin state. Linux path must be confirmed. |
| File picker for audio import | ⚠️ JUCE file browser — user-initiated, not arbitrary. |
| Plugin state save/restore (DAW session) | ✅ Standard JUCE state serialisation |

#### Model execution

| Finding | Status |
|---------|--------|
| ONNX Runtime inference | ⚠️ Executes a static ONNX model (features_model.ort). Model is committed, not user-supplied. No user-controlled model inputs. Risk is low but must verify there are no paths for arbitrary ONNX model injection. |
| RTNeural CNN inference | ✅ Weights are committed `.json` files. No runtime model loading. |
| Audio-to-MIDI pipeline | ✅ Non-real-time by design. The CQT requires >1s audio chunks. No real-time callback concerns for the neural inference. |

#### Process/subprocess

| Finding | Status |
|---------|--------|
| `system()`, `popen()`, `fork()`, `exec()` | None observed in build scripts or CMake. Deep source review needed. |
| `dlopen()` / `LoadLibrary()` | None observed. ONNX Runtime is statically linked. |

#### Unsafe code

| Finding | Status |
|---------|--------|
| Python scripts in repository | `Tests/` may include Python for test data generation. Must verify Python is not invoked at build time in the Nix sandbox. |
| Model weight extraction script (described in README) | Historical process using tf2onnx, Netron, manual steps. Not automated. Not in repository. |

### Missing evidence requiring deep review

- [ ] Source-level audit of update notification mechanism (introduced in v1.1.0)
- [ ] Linux filesystem path for recording storage
- [ ] Audio file format parsers — fuzzing surface (especially minimp3 and JUCE audio readers)
- [ ] ONNX Runtime API usage — verify no arbitrary model loading paths
- [ ] All Python scripts in repository — verify none execute during build
- [ ] String search for URLs, IP addresses, API endpoints in source and binary
- [ ] Hardening compilation flags (stack protector, PIE, etc.)

---

## 6. Real-time audio safety

NeuralNote is **not a real-time effect**. The architecture is fundamentally offline:

1. Audio is gathered (recorded or imported from file)
2. CQT features are computed (requires >1s audio chunks — non-causal)
3. CNN inference runs (additional ~120ms latency)
4. Note events are created by processing posteriorgrams backward (future → past, non-causal)

The transcription pipeline does not execute in the audio callback. However, the internal synth/player does. Key areas to verify:

| Area | Risk | Notes |
|------|------|-------|
| Internal synth playback | Low | Simple oscillator + MIDI output. JUCE `juce_dsp` based. |
| Audio resampling | Low | JUCE resampling, well-tested. |
| Parameter changes | Low | Parameters control transcription thresholds, not real-time DSP. |
| State serialisation | Low | Standard JUCE `ValueTree` or similar. |
| MIDI output | Low | Standard JUCE MIDI buffer output. |

**Assessment:** Real-time safety risk is low. The heavy computation (CQT, CNN, note creation) is offline.

---

## 7. Build findings

### Build system
- CMake 3.16+, C++17
- JUCE CMake API (`juce_add_plugin`)
- Formats: VST3, AU (macOS), Standalone
- Linux: VST3 and Standalone (x86_64 only)

### Network-independent build
The source builds without network access **if** the ONNX Runtime library is pre-fetched:
1. Clone with `--recurse-submodules --shallow-submodules`
2. Pre-place `onnxruntime-*-linux-x86_64.tar.gz` (or its extracted contents) in `ThirdParty/`
3. Run CMake configure + build

The `build.sh` script includes a `curl` fetch, but this is optional — if the archive is already present it uses the cached version. For Nix, we replace this with a fixed-output derivation.

### Nix buildability
- **JUCE submodule**: Must be pinned to exact commit. JUCE uses CMake, which Nix can handle.
- **RTNeural submodule**: Header-only C++ library, straightforward.
- **ONNX Runtime**: Must be provided as a fixed-output derivation. The `tiborvass/libonnxruntime-neuralnote` release provides versioned archives. Hash must be recorded and verified.
- **Model weights**: Already committed — no additional fetch needed.
- **minimp3**: Vendored (single `.c` and `.h` file), straightforward.
- **LTO**: Enabled by default (`-DLTO=ON`). May increase build time; can be toggled.
- **Tests**: Optional (`-DBUILD_UNIT_TESTS=ON`). Requires ONNX Runtime. Test suite runs as part of `build.sh` on macOS; Linux test support is `OFF` by default.

### Reproducibility concerns
- Build timestamps likely embedded by JUCE's `juce_add_plugin`
- LTO may produce non-deterministic output
- Binary data embedding (`juce_add_binary_data`) should be deterministic
- ONNX Runtime static library is pre-built — its provenance must be verified

---

## 8. Binary findings (preliminary)

### Upstream Linux release (v1.1.0)
The v1.1.0 GitHub release includes:
- `NeuralNote-v1.1.0-Linux-x86_64.tar.gz` (VST3 + Standalone)
- No installer — raw binaries, manual installation

### Binary analysis needed
- [ ] Architecture: x86_64 only confirmed
- [ ] ELF type, RPATH/RUNPATH, interpreter, linked libraries
- [ ] Exported/imported symbols
- [ ] Embedded URLs and strings (especially update check URLs)
- [ ] Bundled libraries (ONNX Runtime, JUCE, RTNeural — statically linked)
- [ ] Hardening: PIE, stack protector, NX, RELRO, FORTIFY
- [ ] Build paths and debug information
- [ ] Hash comparison with locally-built binary

---

## 9. Runtime isolation findings

Not yet performed. Testing plan should include:

- [ ] Plugin discovery in Carla or isolated host
- [ ] Instantiation and UI open/close
- [ ] Audio file import (valid and malformed .wav, .aiff, .flac, .mp3, .ogg)
- [ ] Recording functionality
- [ ] MIDI export (drag and drop)
- [ ] State save/restore
- [ ] Repeated load/unload
- [ ] Network denied by default — verify no outbound connections
- [ ] Filesystem writes — verify recording paths, temp files
- [ ] Process tracing — verify no subprocess execution
- [ ] Long-duration stability

---

## 10. Known defects and upstream issues

| Issue | Severity | Notes |
|-------|----------|-------|
| Update notification (v1.1.0 feature) | Medium | Must verify no silent network access. If it respects JUCE_WEB_BROWSER=0, it may use OS-level mechanisms or be disabled. |
| JUCE Starter licence for redistribution | Medium | The JUCE Starter licence is per-developer for personal use. Redistribution via Nix binary cache may require clarification. Many JUCE open-source projects operate under this model successfully. |
| ONNX Runtime pre-built binary provenance | Low | Versioned and tagged, but must hash-verify. Compiled with ort-builder. |
| Recording storage path on Linux | Low | Must confirm path and permissions. macOS uses `~/Library/NeuralNote`, Windows uses `%APPDATA%`. Linux path unknown. |
| mp3 parsing via minimp3 | Low | minimp3 is a well-tested single-header library. Fuzzing coverage is unknown. |
| Model weight provenance | Informational | Weights derived from Spotify basic-pitch via manual process. Not reproducible from source alone (requires TensorFlow, tf2onnx, Netron). This is common for ML projects but means model weights are a binary artefact with no build script. |

---

## 11. Nix packaging design

### Proposed derivation structure

```nix
{ lib, stdenv, fetchFromGitHub, fetchurl, cmake, pkg-config
, freetype, libGL, libX11, libXcursor, libXext, libXinerama, libXrandr
, alsa-lib, curl, fontconfig, webkitgtk ? null
}:

let
  # ONNX Runtime pre-built for NeuralNote
  onnxruntime-neuralnote = stdenv.mkDerivation rec {
    pname = "onnxruntime-neuralnote";
    version = "1.14.1-neuralnote.0";  # Linux-specific version

    src = fetchurl {
      url = "https://github.com/tiborvass/libonnxruntime-neuralnote/releases/download/v${version}/onnxruntime-v${version}-linux-x86_64.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";  # To be filled
    };

    installPhase = ''
      mkdir -p $out/lib $out/include
      cp libonnxruntime.a $out/lib/
      cp -r include/* $out/include/
    '';
  };

in
stdenv.mkDerivation rec {
  pname = "neuralnote";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "DamRsn";
    repo = "NeuralNote";
    rev = "v${version}";
    hash = "sha256-BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=";  # To be filled
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    freetype libGL libX11 libXcursor libXext libXinerama libXrandr
    alsa-lib curl fontconfig
    onnxruntime-neuralnote
  ];

  # Pre-place ONNX Runtime so CMake can find it
  preConfigure = ''
    mkdir -p ThirdParty/onnxruntime
    cp -r ${onnxruntime-neuralnote}/lib ThirdParty/onnxruntime/
    cp -r ${onnxruntime-neuralnote}/include ThirdParty/onnxruntime/
  '';

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DLTO=ON"
    "-DBUILD_UNIT_TESTS=OFF"
    # Ensure network-disabled compile definitions are present
  ];

  # Install only VST3 and optionally Standalone
  installPhase = ''
    mkdir -p $out/lib/vst3 $out/bin
    cp -r NeuralNote_artefacts/Release/VST3/NeuralNote.vst3 $out/lib/vst3/
    cp -r NeuralNote_artefacts/Release/Standalone/NeuralNote $out/bin/
  '';

  meta = with lib; {
    description = "Audio to MIDI transcription plugin using deep learning";
    homepage = "https://github.com/DamRsn/NeuralNote";
    license = licenses.asl20;
    # JUCE 8+ supports Linux on x86_64
    platforms = [ "x86_64-linux" ];
    maintainers = [];  # To be filled
    # Classification metadata
    fossPlugins = {
      classification = "accept-source";
      reviewed-commit = "113f0586bcb0c55202e005a989d50858728e78fb";
      reviewed-date = "2026-07-22";
      formats = [ "vst3" "standalone" ];
      risk = "low";
      redistribution = "permitted-with-juce-clarification";
    };
  };
}
```

### Key packaging decisions

1. **ONNX Runtime**: Source-build of ONNX Runtime from Microsoft is complex and slow. The NeuralNote project maintains a custom build (`tiborvass/libonnxruntime-neuralnote`) with specific operators and configuration. Using this pre-built library with a fixed hash is pragmatic and follows the project's own build approach. If source-building is required, the `ort-builder` tool could be used.

2. **JUCE**: The submodule must be pinned. The JUCE Starter licence is the project's declared licence for JUCE usage. This is common in the JUCE ecosystem for open-source plugins. The Nix package should document this.

3. **Model weights**: Committed to source — no additional fetch. However, the `.ort` file in `ThirdParty/onnxruntime/` (from the ONNX Runtime archive) also contains model data and must be copied alongside `features_model.ort` from `Lib/ModelData/`.

4. **Update notification**: Should be audited and, if it performs network access, patched out or disabled via compile definition for the Nix build.

5. **Recording path**: Should be verified on Linux. If non-standard, consider patching to XDG-compliant paths.

---

## 12. Residual risks

| Risk | Severity | Mitigation |
|------|----------|------------|
| JUCE Starter licence redistribution ambiguity | Medium | Document prominently. Accept for source distribution; binary cache distribution is common practice but legally ambiguous. |
| Update notification mechanism unknown | Medium | Source audit before final acceptance. Patch out if network-dependent. |
| Audio file format parsing surface | Low-Medium | minimp3 (single file, widely used). JUCE parsers (well-tested). Fuzz testing recommended. |
| ONNX Runtime CVE exposure | Low | v1.14.1 is a known version. Check CVEs against this version. Runtime is used for static model inference only — attack surface is limited to crafted audio inputs (not crafted ONNX models). |
| Model weight provenance not reproducible | Informational | Weights are Apache-2.0 licensed. Reproducibility of weights is not required for security review, but should be noted. |

---

## 13. Final disposition

**Preliminary classification: `accept-source`**

**Justification:**
NeuralNote is a mature (3+ year, 2.8k stars), actively maintained, Apache-2.0 licensed audio plugin with genuine Linux support. The source is complete, the model is committed, and the build is standard CMake+JUCE. The project disables network features at compile time (`JUCE_WEB_BROWSER=0`, `JUCE_USE_CURL=0`).

**Blockers requiring resolution before final acceptance:**
1. Audit the v1.1.0 update notification mechanism for network access
2. Verify JUCE Starter licensing permits Nix redistribution
3. Hash-verify the ONNX Runtime pre-built library
4. Confirm font and asset licences in `NeuralNote/Assets/`
5. Verify Linux recording storage path

**Confidence level:** Medium-High — substantial evidence gathered, but deep source review, binary analysis, and runtime testing not yet performed.

---

## Key questions for deep review

Following the handoff format, these are the specific questions the deep review must answer:

- Does the v1.1.0 update notification use any network access (HTTP, OS notification services, or otherwise)?
- Are `JUCE_WEB_BROWSER=0` and `JUCE_USE_CURL=0` respected throughout the codebase?
- Where exactly does the Linux recording store audio files?
- Are the fonts and icons in `NeuralNote/Assets/` properly licensed (compatible with Apache-2.0)?
- What is the exact JUCE Starter licence implication for binary redistribution via Nix cache?
- Does any Python script execute during the CMake configure or build phase?
- Are there any embedded URLs, IP addresses, or API endpoints in the source or binary?
- Does the ONNX Runtime version (1.14.1) have any known CVEs relevant to the static inference use case?
- Are minimp3 and JUCE audio format parsers (FLAC, Ogg Vorbis, AIFF, WAV) robust against malformed inputs?
- Is the plugin real-time safe in its internal synth playback path?
- Are build artefacts deterministic across rebuilds?
- Does the plugin hold any mutexes, allocate, or perform I/O during MIDI output in the audio callback?
