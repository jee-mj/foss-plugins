# AUDIO-017 — Sherpa

- Repository: `tparker48/sherpa-synthesizer`
- Commit: `680cc36547b61408398cd1b571980c7669229326`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[TopoDataLoader.cpp](https://github.com/tparker48/sherpa-synthesizer/blob/680cc36547b61408398cd1b571980c7669229326/Source/TopoDataLoader.cpp) converts terrain image pixel brightness into normalized waveform data. [TopoOsc.cpp](https://github.com/tparker48/sherpa-synthesizer/blob/680cc36547b61408398cd1b571980c7669229326/Source/TopoOsc.cpp) advances waveform phases and writes oscillator samples per voice. This is image-driven wavetable synthesis, not image-model inference. [topoSynth.jucer](https://github.com/tparker48/sherpa-synthesizer/blob/680cc36547b61408398cd1b571980c7669229326/topoSynth.jucer) enumerates JUCE and local oscillator/filter sources for VST3/AU. Component `terrain-oscillator`: non-neural DSP. No model/runtime or GPU audio integration is established.

Investigate Windows source build and exact plugin architecture for the existing Wine lead, or a separately scoped Linux port; source portability is not yet build validation. Keep backend/pin/model arrays empty rather than inventing an inference tuple. GPU graphics modules in a JUCE project are not audio acceleration evidence.

All evaluation/build/load/model/provider/host validation **not-run**. Future AMD hardware stages (model/provider/host) remain **not-run-policy** because AMD execution is excluded; no AMD provider recorded here. Copyright metadata remains unchanged and informational, not a technical gate.
