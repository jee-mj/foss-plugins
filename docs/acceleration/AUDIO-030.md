# AUDIO-030 — ChainMaid

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/ChainMaid`, pinned `654ce51fd63859bea4f54c143a197d61239d6f94`; official commits/tree/contents APIs inspected.

The single product uses a per-channel `SideChainEngine::processSample` in its callback. Rectified sidechain level drives a one-pole dB envelope and soft-knee threshold/ratio gain curve with makeup and dry/wet mix. No trained weights or inference runtime is involved. CMake declares AU/VST3/Standalone and links JUCE audio_utils/dsp/gui_extra; it requires a caller-supplied JUCE installation/source without a pinned version. Suite membership does not import other Maid products into this repository identity.

Pinned upstream assessment evidence:
- [Callback routing](https://github.com/GareBear99/ChainMaid/blob/654ce51fd63859bea4f54c143a197d61239d6f94/ChainMaid/Source/PluginProcessor.cpp)
- [Actual sidechain compressor](https://github.com/GareBear99/ChainMaid/blob/654ce51fd63859bea4f54c143a197d61239d6f94/ChainMaid/Source/SideChainEngine.h)
- [Formats and dependency contract](https://github.com/GareBear99/ChainMaid/blob/654ce51fd63859bea4f54c143a197d61239d6f94/ChainMaid/CMakeLists.txt)

No neural/GPU backend record is warranted. Next action: pin JUCE and establish Linux/Windows CPU target feasibility, including platform-specific AU handling, before host or Wine testing. All evaluation/build/load/model_execution/provider_execution/host stages are **not-run**; future AMD execution would be **not-run-policy**. Rights fields are preserved; missing dependency licensing detail is informational.
