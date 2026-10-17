# AUDIO-062 — BRAUN AS-42

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `sneed-and-feed/braun_as-42` at `33d6191e30ca52593a4a9d1f10e60220ce981563`.

- [DspEngine.cpp](https://github.com/sneed-and-feed/braun_as-42/blob/33d6191e30ca52593a4a9d1f10e60220ce981563/plugin/source/dsp/DspEngine.cpp): deterministic voice allocation, MIDI events, felt-piano and two drone voices feed tape delay, shimmer reverb and limiting. The generative/synthesis terminology is not evidence of learned inference.
- [CMakeLists.txt](https://github.com/sneed-and-feed/braun_as-42/blob/33d6191e30ca52593a4a9d1f10e60220ce981563/CMakeLists.txt): JUCE 8.0.6 DSP/plugin and embedded web assets, no NN runtime integration.

Piano/drone synthesis and effects are conventional DSP components. No NN model/provider tuple identified; no NVIDIA/AMD inference backend claimed. Next: native package and GUI/ABI/source-vs-release reconciliation. No execution validation performed; Wine remains unknown. Sample/model rights must not be inferred from MIT source metadata; no sample acquisition occurred and rights metadata is not a technical gate.
