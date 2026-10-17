# AUDIO-035 — BassMaid

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/BassMaid`, pinned `64693881a539376dbcac2e8ffe07cd2fddfe0aa9`; official commits/tree/contents APIs inspected, including nested `BassMaidJUCE` source.

One low-end product. The callback splits low/high bands, derives a bandpass envelope, modulates a sine sub-oscillator, adds tanh-shaped harmonics and applies envelope compression, mixing and limiting. There is no trained model in this algorithm. CMake links JUCE audio_utils/dsp/gui_extra and declares AU/VST3/Standalone with external JUCE; no neural framework or GPU provider is selected.

Pinned upstream assessment evidence:
- [Actual sub/harmonic/envelope processing](https://github.com/GareBear99/BassMaid/blob/64693881a539376dbcac2e8ffe07cd2fddfe0aa9/BassMaidJUCE/Source/PluginProcessor.cpp)
- [Build targets and links](https://github.com/GareBear99/BassMaid/blob/64693881a539376dbcac2e8ffe07cd2fddfe0aa9/BassMaidJUCE/CMakeLists.txt)

Backends empty. Next action: pin JUCE and evaluate native CPU portability/format handling; establish native Windows and Wine host routes separately if needed. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. Existing metadata/README rights discrepancy is preserved and informational, not a technical gate.
