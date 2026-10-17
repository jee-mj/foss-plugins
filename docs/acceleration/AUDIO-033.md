# AUDIO-033 — MixMaid

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/MixMaid`, pinned `93ea69ceafa7d01cc27c0026207ef4fdd055ccb4`; official commits/tree/contents APIs inspected.

One mix-correction product. The callback analyzes band energy, blends reference targets and applies `SmartBands` IIR shelves/bells plus a safety limiter. `ReferenceMatcher` accumulates analysis snapshots; its learning/confidence terminology does not establish a neural model. Target correction and attack/release detectors are explicit numeric heuristics. CMake lists this analysis/DSP code and JUCE modules, with no inference provider dependency; AU/VST3/Standalone are source targets, not platform acceptance.

Pinned upstream assessment evidence:
- [Actual analysis/correction callback](https://github.com/GareBear99/MixMaid/blob/93ea69ceafa7d01cc27c0026207ef4fdd055ccb4/MixMaid_v9/Source/PluginProcessor.cpp)
- [Reference accumulation/blending](https://github.com/GareBear99/MixMaid/blob/93ea69ceafa7d01cc27c0026207ef4fdd055ccb4/MixMaid_v9/Shared/Analysis/ReferenceMatcher.cpp)
- [IIR correction](https://github.com/GareBear99/MixMaid/blob/93ea69ceafa7d01cc27c0026207ef4fdd055ccb4/MixMaid_v9/Shared/DSP/SmartBands.cpp)
- [Build/dependencies](https://github.com/GareBear99/MixMaid/blob/93ea69ceafa7d01cc27c0026207ef4fdd055ccb4/MixMaid_v9/CMakeLists.txt)

Backends empty: no neural/GPU route evidenced. Next action: pin external JUCE and establish CPU platform/format portability and host behavior, treating Windows/Wine independently. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. Existing MIT/paid-product rights scope concerns are preserved and informational, not a technical gate.
