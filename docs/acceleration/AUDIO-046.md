# AUDIO-046 — Suppressor

- Repository: `affinedsp/suppressor`
- Inspected revision: `a6c740120f2d6bb7ea11e5da043c4108412176d2` (official GitHub APIs).
- Assessment: **complete / none / not-applicable**.

## Pinned upstream evidence

All references are upstream evidence at assessment stage and the full revision above.

- [ChannelEngine.h](https://github.com/affinedsp/suppressor/blob/a6c740120f2d6bb7ea11e5da043c4108412176d2/Source/DSP/ChannelEngine.h): per-sample hum suppression, lookahead, transient cue and routing between one-split/multiband cores.
- [OneSplitDenoiser.h](https://github.com/affinedsp/suppressor/blob/a6c740120f2d6bb7ea11e5da043c4108412176d2/Source/DSP/OneSplitDenoiser.h): low/high crossover, high-band detector and gain application. “Denoiser” here is frequency-selective gating, not a model.
- [EnvelopeGate.h](https://github.com/affinedsp/suppressor/blob/a6c740120f2d6bb7ea11e5da043c4108412176d2/Source/DSP/EnvelopeGate.h): threshold/hysteresis/hold, attack/release and gain-floor logic, no NN inference.
- [CMakeLists.txt](https://github.com/affinedsp/suppressor/blob/a6c740120f2d6bb7ea11e5da043c4108412176d2/CMakeLists.txt): DSP interface library; optional plugin with JUCE 8.0.9 and clap-juce-extensions at `c1a5ad025f95d01e03267857fa8276ebeed16500`.
- [Source/CMakeLists.txt](https://github.com/affinedsp/suppressor/blob/a6c740120f2d6bb7ea11e5da043c4108412176d2/Source/CMakeLists.txt): VST3/Standalone and optional CLAP wiring; normal JUCE linkage, no inference provider.

## Disposition

`guitar-denoiser` is non-neural DSP. Recorded Linux/unknown-architecture CPU backend `native-cpp-envelope-dsp` is implemented/not-packaged. Architecture is deliberately unresolved rather than inferred from machine hardware or a generic cross-platform claim. Other native platforms and Wine require their own artifacts and checks.

No optional NVIDIA/AMD inference route is established; CPU is the implemented baseline. Package attribute/runtime ID null and inference runtime pins/model refs empty. Observed framework tags/commits are build provenance, not claimed acquired package hashes. License metadata is informational.

## Validation / next action

All six stages **not-run**. Resolve full dependencies, establish a Linux CPU artifact and test display/host integration under later authorization. No model was acquired. AMD hardware model/provider/host checks remain policy-skipped if any actual AMD route is introduced.
