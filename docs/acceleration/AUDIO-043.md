# AUDIO-043 — Dispenser

- Repository: `wheatBread1306/Dispenser`
- Inspected revision: `f5e4c926e5c3ff281b1bc9c56d60abf07871a8a3` (official GitHub API pin, tree and contents).
- Assessment: **complete / none / not-applicable**.

## Pinned upstream evidence

All references are upstream assessment evidence at the revision above.

- [CascadeAPF.cpp](https://github.com/wheatBread1306/Dispenser/blob/f5e4c926e5c3ff281b1bc9c56d60abf07871a8a3/Source/DSP/CascadeAPF.cpp): `processFilterImpl` computes coefficients from smoothed frequency/resonance/drift, updates eight filter stages and writes audio samples. This is stateful all-pass DSP, not learned inference.
- [Manager.cpp](https://github.com/wheatBread1306/Dispenser/blob/f5e4c926e5c3ff281b1bc9c56d60abf07871a8a3/Source/DSP/Manager.cpp): cascades the configured number of all-pass processors.
- [CMakeLists.txt](https://github.com/wheatBread1306/Dispenser/blob/f5e4c926e5c3ff281b1bc9c56d60abf07871a8a3/CMakeLists.txt): JUCE tag 9.0.0, VST3/Standalone, JUCE DSP linkage and CPU compilation flags. Non-ARM MSVC 64-bit enables `/arch:AVX2`; x86_64 non-MSVC release enables `-mavx2`. No NN provider is linked.

## Disposition

`disperser` is a non-neural DSP component. Recorded tuple: `windows / x86_64 / cpu / juce-cpp-dsp-avx2`, implemented, not packaged, CPU route supported. AVX2 is CPU ISA specialization, not NVIDIA/AMD acceleration. Generic non-MSVC branches are source leads, not proof of Linux/macOS build success; Wine is an independent host route.

Package attribute/runtime ID null; no inference runtime pins or model references. JUCE's source tag is observed build provenance, not a resolved fetched-artifact hash. No models were downloaded, and no GPU provider route is inferred. License metadata does not gate technical work.

## Validation / next action

All six validation stages **not-run**. Pin dependency commits/hashes and check CPU ISA compatibility before packaging. Validate plugin/standalone and Wine independently if selected. No AMD hardware was exercised; any later AMD model/provider/host stages must remain `not-run-policy` for this campaign.
