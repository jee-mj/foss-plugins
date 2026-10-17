# AUDIO-019 — Tiptoe

- Repository: `conjius-dp/tiptoe`
- Commit: `7b05e3133cf207c92918ffc11e3a16e2e86e6917`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[SpectralGateTiptoe.cpp](https://github.com/conjius-dp/tiptoe/blob/7b05e3133cf207c92918ffc11e3a16e2e86e6917/Source/DSP/SpectralGateTiptoe.cpp) establishes the meaning of “learned profile”: `learnFrame` accumulates FFT magnitudes/powers, `stopLearning` computes means and variance-derived behavior, and `processFrame` applies soft-knee per-bin attenuation with spectral/temporal smoothing and inverse FFT overlap-add. This is noise-statistics estimation, not neural inference or ML training. Component `spectral-gate`: non-neural DSP.

[CMakeLists.txt](https://github.com/conjius-dp/tiptoe/blob/7b05e3133cf207c92918ffc11e3a16e2e86e6917/CMakeLists.txt) builds TiptoeDSP and JUCE plugin targets; no inference framework/GPU provider established. Windows source/artifact with separate Wine investigation is the catalog lead. Investigate native Linux portability independently. No model acquisition or GPU dependency is called for; backend list is empty intentionally.

All evaluation/build/load/model/provider/host validation **not-run**, including CPU audio and Wine. Any future AMD hardware model/provider/host stages must be **not-run-policy** because AMD hardware execution is outside the campaign. No license determination is used as a technical gate; catalog copyright unchanged.
