# AUDIO-034 — GlueMaid

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/GlueMaid`, pinned `58548a7c4eddcfccc722eb3b4702e7b10243c06f`; official commits/tree/contents APIs inspected, including nested `GlueMaidJUCE` source.

One bus-compressor product. `analyzeBlock` derives RMS/crest; explicit formulas choose threshold, ratio, knee, attack and release. `processBlock` runs sidechain high-pass/envelope tracking, gain reduction, makeup, parallel mix and optional tanh clipping. Adaptive behavior is non-neural DSP. CMake requires caller-provided JUCE and links audio_utils/dsp/gui_extra; AU/VST3/Standalone are declared. No model, neural framework or GPU DSP provider is selected in these paths.

Pinned upstream assessment evidence:
- [Actual adaptive compressor implementation](https://github.com/GareBear99/GlueMaid/blob/58548a7c4eddcfccc722eb3b4702e7b10243c06f/GlueMaidJUCE/Source/PluginProcessor.cpp)
- [Build targets and links](https://github.com/GareBear99/GlueMaid/blob/58548a7c4eddcfccc722eb3b4702e7b10243c06f/GlueMaidJUCE/CMakeLists.txt)

Backends empty. Next action: pin JUCE, establish per-OS CPU build targets and separately verify host processing/state recall; Windows source or Wine readiness is not demonstrated by target names. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. Existing metadata/README rights discrepancy remains informational and preserved, not an implementation blocker.
