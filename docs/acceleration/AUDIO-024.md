# AUDIO-024 — Botanica

- Repository: `Aelmgren/botanica-vst`
- Commit: `6a74b1ad9ecb43b92c2d16637ac66adc57314d8c`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[SoundGenerators.cpp](https://github.com/Aelmgren/botanica-vst/blob/6a74b1ad9ecb43b92c2d16637ac66adc57314d8c/Source/SoundGenerators.cpp) contains distinct `WaterGenerator`, `FrogGenerator`, `NatureGenerator` and `JungleGenerator` implementations: RNG/noise, oscillatory calls, envelopes and lowpass/bandpass/formant filters create the ambience procedurally. Components `water`, `frogs`, `nature`, `jungle` are all non-neural DSP. Generative audio here is algorithmic, not neural generation.

[CMakeLists.txt](https://github.com/Aelmgren/botanica-vst/blob/6a74b1ad9ecb43b92c2d16637ac66adc57314d8c/CMakeLists.txt) builds the processor/editor/generators and links JUCE audio/DSP; no model runtime or GPU provider established. The official tree pins JUCE to `51d11a2be6d5c97ccf12b4e5e827006e19f0555a`. Native Linux CPU source packaging is the next technical lead, not a verified artifact. Backend/pin/model arrays remain empty rather than asserting an inference route.

All evaluation/build/load/model/provider/host validation **not-run**. No build, plugin host or model execution. Future AMD hardware model/provider/host stages must be **not-run-policy** because AMD execution is outside this campaign. Existing copyright/framework evidence remains unchanged and informational, not a technical gate.
