# AUDIO-020 — Gunk

- Repository: `cemkod/gunk`
- Commit: `9cb7995ec4dbb982bf1c034f4499104422f1b0a9`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[PitchDetector.cpp](https://github.com/cemkod/gunk/blob/9cb7995ec4dbb982bf1c034f4499104422f1b0a9/Source/PitchDetector.cpp) uses aubio FFT, magnitude-squared spectrum and inverse FFT autocorrelation to estimate pitch. [PluginProcessor.cpp](https://github.com/cemkod/gunk/blob/9cb7995ec4dbb982bf1c034f4499104422f1b0a9/Source/PluginProcessor.cpp) runs envelope/gate, LFO, oscillators, transient sample player and filter; Cycfi Q's gate/envelope are conventional DSP. Components `pitch-analysis` and `bass-synth`, both non-neural DSP. Pitch recognition is not sufficient evidence of NN inference.

[CMakeLists.txt](https://github.com/cemkod/gunk/blob/9cb7995ec4dbb982bf1c034f4499104422f1b0a9/CMakeLists.txt) fetches JUCE 7.0.12, aubio 0.4.9 and Cycfi Q at mutable `master`; aubio uses its bundled Ooura FFT without optional file-I/O backends. These are CPU DSP dependencies, not CUDA/ROCm inference providers. Native Linux source packaging is a lead; freeze the mutable Q dependency and other inputs first. No inference backend/pins/models recorded.

All evaluation/build/load/model/provider/host validation **not-run**. No Wine/native Windows runtime inference from Linux support. Future AMD hardware model/provider/host validation must remain **not-run-policy** because AMD execution is excluded. Copyright/sample notices remain unchanged and informational; no license gate introduced.
