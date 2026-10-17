# AUDIO-016 — plaits-vst

- Repository: `masseyis/plaits-vst`
- Commit: `5ff03e7cefab044716e093189b1e3123f0a5fe5c`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[CMakeLists.txt](https://github.com/masseyis/plaits-vst/blob/5ff03e7cefab044716e093189b1e3123f0a5fe5c/CMakeLists.txt) builds the bundled Plaits oscillators, FM, drum, physical-model and LPC speech engines with JUCE 8.0.4. LPC/formant speech synthesis is not a neural speech model. [Voice processing](https://github.com/masseyis/plaits-vst/blob/5ff03e7cefab044716e093189b1e3123f0a5fe5c/src/dsp/voice.cpp) calls `plaitsVoice_.Render`, applies its envelope and resamples the output. Component `plaits-engine` is conventional non-neural DSP. No NN framework, training path or GPU audio provider is established by these paths.

Native Linux CPU build is the actionable route. Freeze JUCE and other fetched build inputs before packaging; no acceleration dependency justified. Backend/pin/model arrays remain empty because no inference or GPU backend is being proposed. Windows artifacts do not validate Wine.

Evaluation/build/load/model/provider/host validation: **not-run**. No binaries or models acquired, built or executed. Future AMD hardware model/provider/host stages are **not-run-policy** because AMD hardware execution is outside this campaign; no AMD provider is established here. Existing copyright evidence is preserved; firmware/dependency attribution remains a separate informational review.
