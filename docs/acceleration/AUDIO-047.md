# AUDIO-047 — InstaWidth

- Repository: `hariel1985/InstaWidth`
- Inspected revision: `fcefc76077b7ec8f03d1a52deef475146cf67fd1` (official GitHub APIs).
- Assessment: **complete / none / not-applicable**.

## Pinned upstream evidence

All references are `kind: upstream`, `stage: assessment`, revision above.

- [WidthEngine.cpp](https://github.com/hariel1985/InstaWidth/blob/fcefc76077b7ec8f03d1a52deef475146cf67fd1/Source/WidthEngine.cpp): mid/side filter banks, LR4 band splits, per-band side gains, tilt shelves and monomaker high-pass processing.
- [PluginProcessor.cpp](https://github.com/hariel1985/InstaWidth/blob/fcefc76077b7ec8f03d1a52deef475146cf67fd1/Source/PluginProcessor.cpp): `processBlock` selects IIR width or FIR side convolution with mid delay, runs side de-essing, stereo conversion and correlation analysis. Filter impulses are not learned model weights.
- [CMakeLists.txt](https://github.com/hariel1985/InstaWidth/blob/fcefc76077b7ec8f03d1a52deef475146cf67fd1/CMakeLists.txt): VST3/AU/LV2 with sibling `../JUCE` and JUCE processing modules; no inference framework linkage.

## Disposition

`stereo-width` is `non-neural-dsp`. Recorded tuple is Linux/unknown-architecture/CPU/`juce-iir-fir-dsp`, implemented/not-packaged. Architecture is not inferred from generic CMake. Linux is a native packaging lead; format/platform declarations do not establish that every native target or Wine works. Convolution, spectral display and automatic safety are not NN evidence.

No NVIDIA/AMD compute provider was found in the inspected DSP/build paths. Package attribute/runtime ID null; no inference runtime pins/model refs. Resolve the sibling JUCE revision rather than inventing a framework lock/hash. License information does not block technical investigation.

## Validation / next action

Evaluation/build/load/model/provider/host stages **not-run**. Resolve framework source, select platform-supported formats, establish CPU artifact and validate latency, automation, state and GUI separately. Future AMD hardware execution remains `not-run-policy` for model/provider/host stages; no such backend is asserted here.
