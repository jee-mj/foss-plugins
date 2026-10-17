# AUDIO-008 — crispy

Assessment date: 2026-10-17. Repository: `ayanumich/crispy`.
Pinned source: `5faad5aecf5984e72ccc082dccf18af7ba7dc116`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** Public processing uses
conventional IIR EQ, band-split compression, de-essing and parallel tanh saturation.
There is no neural executor, training pipeline or inference client in the inspected
processor/header. Platform/build reproducibility remains a separate packaging gap.

## Pinned upstream evidence

- [PluginProcessor.cpp](https://github.com/ayanumich/crispy/blob/5faad5aecf5984e72ccc082dccf18af7ba7dc116/PluginProcessor.cpp): notch/shelf filtering, crossover bands, envelope-threshold/ratio gain calculation, de-esser subtraction and tanh warmth.
- [PluginProcessor.h](https://github.com/ayanumich/crispy/blob/5faad5aecf5984e72ccc082dccf18af7ba7dc116/PluginProcessor.h): explicit envelope follower and JUCE IIR filter state; no neural session/runtime.
- [Pinned tree](https://github.com/ayanumich/crispy/tree/5faad5aecf5984e72ccc082dccf18af7ba7dc116): targeted build-file discovery found processor/editor sources but no CMake or Projucer build manifest. This does not validate a source build.

Release `v1.0.0-beta` resolves to `b10aa832231569dcfb0eca864f57ed78a1d6f5fb`,
different from inspected source, and has no uploaded assets in the release API.

## Backend disposition and next action

One non-neural DSP component; no inference backend, runtime or model references.
Obtain an authoritative build manifest and establish CPU platform targets before
packaging. License uncertainty is informational, not the technical gate.
All campaign validation stages were not run.
