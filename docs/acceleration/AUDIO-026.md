# AUDIO-026 — Noctuary

- Repository: `reneweller-coding/Noctuary`
- Commit: `a38f694fd6c54d47f774957e881121c3f31a2e17`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

## Component-level inspection

| Component | Kind | Pinned implementation finding |
| --- | --- | --- |
| `cluster-conductor` | non-neural-dsp | ClusterBrain scores candidate notes using harmonicity/consonance, register/interval rules, RNG and event timing; no learned weights/session. |
| `voice-sources` | non-neural-dsp | Oscillator/FM/additive/wavetable, granular/sample/stretch, noise and physical sources. Samples and cycles are sound content, not NN models. |
| `effects` | non-neural-dsp | CPU cloud, delays, reverbs, memory, shifting and spectral processing in render chain. |
| `room-convolution` | non-neural-dsp | Custom partitioned FFT convolution, stepped arithmetic and CPU SIMD helpers. |
| `offline-renderer` | application | Optional headless rendering/self-test tool, separate from live plugin acceptance. |
| `quest-frontend` | application | Android/OpenXR/GLES display and Oboe audio callback using the same core; graphics GPU use is not neural/audio acceleration. |

[ClusterBrain.h](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/Core/include/ambient/ClusterBrain.h) explicitly describes and implements these rules; for example `ruleWeight` penalizes candidate interval/register violations and `update` produces note events. “Brain” and “generative” are not inference evidence. [EngineRender.cpp](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/Core/src/EngineRender.cpp) drives conductors, voices, CPU effects and the room convolver. [Sources.cpp](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/Core/src/Sources.cpp) contains explicit synthesis/resynthesis/FFT code. [Convolution.cpp](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/Core/src/Convolution.cpp) implements custom FFT convolution scheduling, not a GPU compute provider.

[Root CMake](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/CMakeLists.txt) separates core, optional plugin and render/tools; [Core/CMakeLists.txt](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/Core/CMakeLists.txt) links Threads (and Windows sockets), includes dr_flac, and enables optional `AMBIENT_AVX2` with `-mavx2 -mfma` or `/arch:AVX2` for x86_64. **AVX2 is CPU SIMD, not AMD GPU/ROCm support**, and its architecture guard is more informative than general CPU-age prose. [Quest frontend](https://github.com/reneweller-coding/Noctuary/blob/a38f694fd6c54d47f774957e881121c3f31a2e17/Quest/src/main.cpp) uses EGL/GLES/OpenXR for graphics and Oboe for CPU core audio. Android is outside the backend platform enum, so no fabricated Linux backend is assigned to Quest.

## Disposition and validation

Native Linux CPU source packaging is the actionable lead, with explicit x86_64 AVX2 choice and separate architecture/ABI checks. CPU backend records describe the two relevant hot paths (voice sources and room convolution), not claimed GPU providers. Both are **not-packaged** with null attributes/runtime IDs and empty runtime pins/model references; no dependency closure was built and no neural model established. Optional large sample/IR content remains separate content provenance, not permission to acquire it. No sample archive or model downloaded. Native Windows and Wine are separate, untested contexts.

All evaluation/build/load/model/provider/host stages **not-run**. No timing or audio-quality result is claimed from upstream comments or tests present in the tree. Future AMD model/provider/host hardware stages must remain **not-run-policy**, reason: AMD execution is outside this campaign. Freeze JUCE/helper inputs, determine minimum CPU/ABI and content layout, then evaluate CPU packaging and host deadlines. Existing copyright and recording/IR credits remain intact and informational, not a technical gate.
