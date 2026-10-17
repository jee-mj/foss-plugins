# AUDIO-098 — AX330G

Assessment: **complete; ai_role none; execution_mode not-applicable**.
Official API pin: `neglectware/ax330g@ba2116a59721134e867459705a8582074505e04b`.

- [Processor](https://github.com/neglectware/ax330g/blob/ba2116a59721134e867459705a8582074505e04b/plugin-chain/src/PluginProcessor.cpp): device-rate resampling, input-stage processing, per-sample effect chain, upsampling and output FIR. “Model” describes measured hardware behavior here.
- [Chain](https://github.com/neglectware/ax330g/blob/ba2116a59721134e867459705a8582074505e04b/dsp/chain.h): dispatches enabled delay/modulation/chorus/EQ/reverb/compressor block implementations, not neural layers.
- [Model generator](https://github.com/neglectware/ax330g/blob/ba2116a59721134e867459705a8582074505e04b/analysis/hypr2/build_model.py): writes fitted thresholds, envelopes, resonator/filter and static-law parameters into JSON. These hardware fitting tools are not evidence of an NN DSP runtime.
- [CMake](https://github.com/neglectware/ax330g/blob/ba2116a59721134e867459705a8582074505e04b/plugin-chain/CMakeLists.txt): JUCE audio-utils/DSP target and platform-specific tooling, no NN provider linkage in the plugin.

Component `ax330g-chain`: conventional CPU hardware emulation. No GPU inference route established. Existing Windows VST3/Wine proposal remains an unvalidated lead; source declarations do not demonstrate Linux compilation or Wine compatibility. No campaign build/load/execution performed. Firmware-origin/copyright statements in the catalog remain separate and unchanged. Next: bind release/source tuple and perform authorized platform/host checks.
