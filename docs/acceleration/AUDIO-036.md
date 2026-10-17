# AUDIO-036 — FreeEQ8 / ProEQ8

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/FreeEQ8`, pinned `11376c1c496569c975e4d195c3fe5fd44b53d415`; official commits/tree/contents APIs inspected.

Two distinct product components are required: **FreeEQ8** (VST3/AU/Standalone) and **ProEQ8** (VST3/AU, separate PROEQ8 compilation). They share conventional EQ source with biquad/oversampling processing, a linear-phase FIR engine and spectral matching. Pro adds conditional saturation controls and separate licensing/network dependencies; those are not external inference services. `MatchEQ` computes FFT reference/current spectra and applies per-bin correction with overlap-add. `ResonanceDetector` is signal analysis; Smart/Intent labels are not proof of neural inference. A background rebuild thread owns linear-phase FIR construction; execution_mode remains not-applicable per the non-neural schema rule.

Pinned upstream assessment evidence:
- [Both products and dependency links](https://github.com/GareBear99/FreeEQ8/blob/11376c1c496569c975e4d195c3fe5fd44b53d415/CMakeLists.txt)
- [Actual callback and FIR rebuild worker](https://github.com/GareBear99/FreeEQ8/blob/11376c1c496569c975e4d195c3fe5fd44b53d415/Source/PluginProcessor.cpp)
- [FFT matching/correction](https://github.com/GareBear99/FreeEQ8/blob/11376c1c496569c975e4d195c3fe5fd44b53d415/Source/DSP/MatchEQ.h)
- [Resonance analysis](https://github.com/GareBear99/FreeEQ8/blob/11376c1c496569c975e4d195c3fe5fd44b53d415/Source/DSP/ResonanceDetector.h)

No neural/GPU provider evidenced; backends empty. Next action: establish each CPU product's dependency/feature contract and native Linux packaging, then separately validate host and Windows/Wine behavior. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. Existing rights fields preserved; free/pro and dependency terms require consumer judgement without becoming an invented technical gate.
