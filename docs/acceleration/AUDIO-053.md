# AUDIO-053 — Jove

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `DatanoiseTV/jove` at `9c738fd90ddc42515bbd89ea12c0f811a74c836a`.

## Source evidence
- [SynthEngine.cpp](https://github.com/DatanoiseTV/jove/blob/9c738fd90ddc42515bbd89ea12c0f811a74c836a/src/engine/SynthEngine.cpp): `render` sums individually modulated voices and runs saturation, chorus, phaser, delay and limiting. This is conventional synthesis, not learned inference.
- [CMakeLists.txt](https://github.com/DatanoiseTV/jove/blob/9c738fd90ddc42515bbd89ea12c0f811a74c836a/CMakeLists.txt): JUCE submodule, engine sources and audio/UI modules; no inference provider integration in the inspected build.

## Disposition
One non-neural synthesizer component; no NN models or provider runtime tuple identified. No NVIDIA/AMD inference route evidenced; empty backends does not claim hardware incompatibility. The current source assessment does not validate the catalog's v1.1.1 release bytes. Native package/ABI work is the next action; Wine remains separately unverified. No evaluation, build, load, model, provider or host execution was run. License metadata is informational and remains in the existing catalog.
