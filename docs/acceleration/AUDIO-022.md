# AUDIO-022 — Open Synth

- Repository: `Blackshield-Company/open-synth`
- Commit: `243a2e3ce3cb3b457f1512c1a30e32fe5a716aa9`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[synth_engine.cpp](https://github.com/Blackshield-Company/open-synth/blob/243a2e3ce3cb3b457f1512c1a30e32fe5a716aa9/dsp/synth_engine.cpp) drains parameter events, runs arpeggiator/voice allocation, envelopes, oscillators or physical models, filters, instrument-realism processing, FX and tanh limiting, then mixes block sample playback and drums. This is conventional synthesis and sample replay, not model inference. Components `synth-engine`, `sample-rompler`, `effects`, all non-neural DSP. Physical “models” and audio sample libraries are not neural model assets.

[CMakeLists.txt](https://github.com/Blackshield-Company/open-synth/blob/243a2e3ce3cb3b457f1512c1a30e32fe5a716aa9/CMakeLists.txt) explicitly lists local DSP sources and JUCE linking for plugin/standalone, with CLAP extensions and sample handling. No inference/GPU provider is established by the build/render paths. Native Linux CPU packaging is a lead; pin submodules and determine sample layout/content separately. No model acquisition authorized or performed; empty backend array avoids invented acceleration variants.

All evaluation/build/load/model/provider/host validation **not-run**. Windows native and Wine remain separate untested routes. Future AMD hardware model/provider/host stages are **not-run-policy** because AMD execution is outside the campaign. Existing project/sample/framework copyright evidence is retained without a technical license gate.
