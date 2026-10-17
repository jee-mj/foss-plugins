# AUDIO-091 — Default Distortion

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Inspected source: `lsooxlla8/default_distortion@47c0232ec88f14223e8ebb43455e43c5c5ed4c37`.

`DistortionEngine.cpp` implements scalar nonlinear transfer functions, Vital-style tanh approximation, gain/threshold arithmetic and spectral FFT processing. Its algorithm selection and gain tables are conventional DSP; no learned graph/session is identified. CMake builds JUCE 8.0.15 audio/DSP code, the multiband processor and static gain-table sources. An auto-gain lookup table is not by itself a neural runtime.

## Upstream assessment evidence

- [Distortion algorithms](https://github.com/lsooxlla8/default_distortion/blob/47c0232ec88f14223e8ebb43455e43c5c5ed4c37/Source/DistortionEngine.cpp)
- [Build/source declarations](https://github.com/lsooxlla8/default_distortion/blob/47c0232ec88f14223e8ebb43455e43c5c5ed4c37/CMakeLists.txt)

`v0.9.0` resolves to `7a047b90e38c42208ddc95948ecf1e326411a7cb`, distinct from inspected HEAD. The release API lists Linux x64 `.run`, Windows x64 installer, macOS universal package and checksum metadata. Their bytes/layout were not inspected, and no installer was executed. No inference backend/model references are warranted. All campaign stages remain not-run. Native Windows artifacts do not prove Wine support.

Rights: preserve the AGPL-3.0-only claim and separately attributed GPL-3.0-only CHOW/BYOD and other adapted code; this is informational, not a technical gate or a new grant.

Next action: choose release or HEAD, review JUCE and adapted DSP notices, and establish a CPU source baseline with separate installer-layout investigation.
