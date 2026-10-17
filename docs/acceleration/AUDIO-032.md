# AUDIO-032 — MultiMaid

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/MultiMaid`, pinned `bcf15d9cdb6265b9c481cd6ac4c541dbe139e810`; official commits/tree/contents APIs inspected.

One three-band dynamics product: callback sets crossover frequencies and per-band compressor settings, then runs `MultiMaidEngine`. It splits into low/mid/high buffers and uses threshold/ratio gain reduction with attack/release smoothing in `BandCompressor`. This is ordinary CPU DSP, not neural inference. CMake declares AU/VST3/Standalone and JUCE DSP linkage, requiring externally supplied JUCE rather than an immutable dependency pin.

Pinned upstream assessment evidence:
- [Callback](https://github.com/GareBear99/MultiMaid/blob/bcf15d9cdb6265b9c481cd6ac4c541dbe139e810/multimaid/Source/PluginProcessor.cpp)
- [Three-band engine](https://github.com/GareBear99/MultiMaid/blob/bcf15d9cdb6265b9c481cd6ac4c541dbe139e810/multimaid/Source/DSP/MultiMaidEngine.h)
- [Compressor gain algorithm](https://github.com/GareBear99/MultiMaid/blob/bcf15d9cdb6265b9c481cd6ac4c541dbe139e810/multimaid/Source/DSP/BandCompressor.h)
- [Build](https://github.com/GareBear99/MultiMaid/blob/bcf15d9cdb6265b9c481cd6ac4c541dbe139e810/multimaid/CMakeLists.txt)

No neural/GPU backend evidenced. Next action: pin JUCE, handle target formats per OS and evaluate native CPU portability before selecting Linux/Windows/Wine routes. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. Existing rights fields preserved and informational.
