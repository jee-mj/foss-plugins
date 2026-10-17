# AUDIO-050 — Sub-Orbit

- Repository: `echoeslabmusic/Sub-Orbit`
- Inspected revision: `768bb5b65fd5da637c481f42c002041da24e4d22` (official GitHub APIs, canonical owner).
- Assessment: **complete / none / not-applicable**.

## Pinned upstream evidence

All references are `kind: upstream`, `stage: assessment`, revision above.

- [SubOrbitEngine.cpp](https://github.com/echoeslabmusic/Sub-Orbit/blob/768bb5b65fd5da637c481f42c002041da24e4d22/Source/DSP/SubOrbitEngine.cpp): low/high splits, low-mid quadrature processing with rate conversion, width mixing and sidechain-envelope ducking. No neural forward pass.
- [QuadratureAllpassPair.cpp](https://github.com/echoeslabmusic/Sub-Orbit/blob/768bb5b65fd5da637c481f42c002041da24e4d22/Source/DSP/QuadratureAllpassPair.cpp): fixed all-pass coefficients, scalar state recurrences and I/Q generation; not learned weights.
- [CMakeLists.txt](https://github.com/echoeslabmusic/Sub-Orbit/blob/768bb5b65fd5da637c481f42c002041da24e4d22/CMakeLists.txt): JUCE tag 8.0.12, Catch2 v3.7.1, core DSP and AU/VST3 targets; no inference provider or model acquisition.

## Disposition

`low-band-stereoizer` is non-neural DSP. Recorded Linux/unknown-architecture/CPU/`juce-cpp-allpass-dsp` backend is implemented/not-packaged, CPU supported. Source architecture stays unknown; release filename/catalog platform claims are not substituted for a tested tuple. Native Windows/macOS and Wine remain independently unvalidated.

No NVIDIA/AMD inference integration is indicated. Package attribute/runtime ID null; inference pins/model refs empty. Observed JUCE/Catch2 tags are not fetched package hashes or verified inference runtime pins. License metadata is informational, not a gate.

## Validation / next action

All six stages **not-run**. Resolve dependency commits/hashes, establish Linux VST3 CPU build, then measure mono-safety, latency and host behavior. No GPU hardware execution occurred; future AMD model/provider/host stages remain `not-run-policy` under campaign policy.
