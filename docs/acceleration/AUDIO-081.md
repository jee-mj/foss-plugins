# AUDIO-081 — Hikaru Lumen Linux

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Inspected source: `hikarucorporation/hikaru-lumen-linux@19ba16ffe0ac57f5271159ab346f0193e7fcdc1b`.

## Actual implementation

The image-to-sound feature is not sufficient evidence of machine learning. `LensEngine.cpp` reads image luminance, constructs row-scan frames or spectral harmonic magnitudes with seeded phases, and uses JUCE inverse FFT. Chroma/luma/edge statistics map deterministically to macros. `Voice.cpp` performs conventional wavetable interpolation, oscillator rendering, filters and tanh drive. CMake links JUCE DSP, graphics, cryptography and OpenGL; it does not integrate Lumena or a neural framework at this snapshot. MIDI Learn is control mapping, not model training. OpenGL linkage concerns graphics and is not evidence of GPU inference or GPU audio DSP.

The pinned README itself describes a deterministic Lens engine. Any ML marketing or similarly named Lumen/Lumena project must be reconciled against this exact source, not carried across repository identities. The catalog's related `pixelsncodes/lumen` package is not an export of this port.

## Evidence — upstream / assessment

- [LensEngine.cpp](https://github.com/hikarucorporation/hikaru-lumen-linux/blob/19ba16ffe0ac57f5271159ab346f0193e7fcdc1b/Source/Lens/LensEngine.cpp)
- [Voice.cpp](https://github.com/hikarucorporation/hikaru-lumen-linux/blob/19ba16ffe0ac57f5271159ab346f0193e7fcdc1b/Source/Engine/Voice.cpp)
- [CMakeLists.txt](https://github.com/hikarucorporation/hikaru-lumen-linux/blob/19ba16ffe0ac57f5271159ab346f0193e7fcdc1b/CMakeLists.txt)

The `release` tag resolves separately to `4b2239d1bcd2685a708b1fe5fc0a2118f90992bd`; the release API lists only `Lumen.so`. That binary was not inspected, so the HEAD assessment does not validate that payload or its bundle layout.

No inference backends or model references are warranted. All campaign stages remain not-run. Rights: preserve the port's AGPL-3.0 evidence and original MIT-project distinction; dependency and related-package rights remain separate informational review items.

Next action: reconcile the release source, port/original bundle identity and Linux VST3 layout before CPU packaging.
