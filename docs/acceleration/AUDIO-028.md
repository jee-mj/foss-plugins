# AUDIO-028 — Hott Master

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `pndias/hott-master-vst`, pinned `c8955be0318840c57484e8b904d278ffa64ceedf`; official commits/tree/contents APIs inspected.

The single mastering product runs resonance suppression → linear-phase EQ → compressor → soft clipper → limiter directly from `processBlock`. Suppression measures band RMS, tracks attack/release envelopes and subtracts attenuated band content. It is conventional DSP, not neural inference. CMake enumerates these DSP sources and links JUCE audio_utils/dsp, fetching JUCE 8.0.12; it selects no inference framework or GPU provider.

Pinned upstream assessment evidence:
- [Actual processing chain](https://github.com/pndias/hott-master-vst/blob/c8955be0318840c57484e8b904d278ffa64ceedf/Source/PluginProcessor.cpp)
- [RMS/envelope suppression algorithm](https://github.com/pndias/hott-master-vst/blob/c8955be0318840c57484e8b904d278ffa64ceedf/Source/DSP/ResonanceSuppressor.cpp)
- [VST3 build and dependency links](https://github.com/pndias/hott-master-vst/blob/c8955be0318840c57484e8b904d278ffa64ceedf/CMakeLists.txt)

No source-backed neural/GPU backend to package; backend array is empty. CMake provides a VST3 source lead, not Linux or Wine acceptance. Next action: establish CPU build/platform dependencies and Windows host/Wine behavior separately before selecting a distribution route. All evaluation/build/load/model_execution/provider_execution/host stages are **not-run**; no execution/performance claims. AMD hardware execution is outside policy and would be **not-run-policy** for a future AMD backend. Existing rights metadata remains unchanged; licensing is informational, not a technical gate.
