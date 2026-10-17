# AUDIO-063 — BRAUN MR-16

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `sneed-and-feed/braun_mr-16` at `a3943fed7963802e40a37d952e7a6cb3d784e5c0`.

- [Mr16Engine.cpp](https://github.com/sneed-and-feed/braun_mr-16/blob/a3943fed7963802e40a37d952e7a6cb3d784e5c0/source/dsp/Mr16Engine.cpp): `processBlock` sends excitation through a modal matrix, optional vactrol filter, saturator and spatial chorus, with explicit equations/process calls rather than learned weights.
- [CMakeLists.txt](https://github.com/sneed-and-feed/braun_mr-16/blob/a3943fed7963802e40a37d952e7a6cb3d784e5c0/CMakeLists.txt): JUCE DSP core plus optional web/CLAP frontend, no NN runtime/provider integration.

One non-neural modal-resonance synthesis component. No inference model or NVIDIA/AMD provider evidenced. Next: native packaging/GUI ABI work. Sample-to-modal analysis is not by itself neural inference. Existing MIT metadata remains informational; no models/samples acquired. All validation stages not-run; upstream headless test sources are not campaign passes. Wine unknown.
