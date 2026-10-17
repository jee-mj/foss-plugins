# AUDIO-069 — Firefly Synth 2 / Firefly Synth 2 FX

Assessment date: 2026-10-17. Repository: `sjoerdvankreel/firefly-synth-2`.
Pinned source: `03dfdd29156ff2618a5de4471614a8ffe40c0e79`; official GitHub commit, recursive tree and pinned contents inspection.

## Outcome and product enumeration

**complete; ai_role: none; execution_mode: not-applicable.** Two real products are recorded separately:

| Component | Product | Implemented route |
| --- | --- | --- |
| `firefly-synth-2` | FireflySynth2 instrument | Wave/FM/String/audio-input oscillators, voices, modulation and effects |
| `firefly-synth-2-fx` | FireflySynth2FX | Shared DSP engine with FX compile-time configuration |

Both use CPU C++/xsimd DSP, not neural inference. The Linux x86_64 architecture is explicit in CMake output paths.

## Pinned evidence

- [CMakeLists.txt](https://github.com/sjoerdvankreel/firefly-synth-2/blob/03dfdd29156ff2618a5de4471614a8ffe40c0e79/CMakeLists.txt): separate instrument/FX names and CLAP/VST3 targets, `FF_IS_FX=0/1`, shared base/DSP libraries and xsimd includes.
- [FFPlugProcessor.cpp](https://github.com/sjoerdvankreel/firefly-synth-2/blob/03dfdd29156ff2618a5de4471614a8ffe40c0e79/src/firefly_synth/firefly_synth/dsp/plug/FFPlugProcessor.cpp): voice processing, modulation, echo, global effects and buffer mixing.
- [FFOsciProcessor.cpp](https://github.com/sjoerdvankreel/firefly-synth-2/blob/03dfdd29156ff2618a5de4471614a8ffe40c0e79/src/firefly_synth/firefly_synth/modules/osci/FFOsciProcessor.cpp): explicit Wave/FM/String/AudioIn processing dispatch.
- [FFEffectProcessor.cpp](https://github.com/sjoerdvankreel/firefly-synth-2/blob/03dfdd29156ff2618a5de4471614a8ffe40c0e79/src/firefly_synth/firefly_synth/modules/effect/FFEffectProcessor.cpp): compressor envelope coefficients, CPU SIMD tanh/clipping and conventional effect processing.

## Disposition

One Linux x86_64 `xsimd-cpp-dsp` backend per product. xsimd is CPU SIMD; inspected source/build routes establish no NVIDIA/AMD neural or GPU-audio provider. Both are `not-packaged`, exports/runtime IDs null, pins/models empty. All six validation stages are `not-run`; no host or Wine acceptance claimed. Future AMD GPU execution remains policy-skipped for model/provider/host stages.

Next: pin shared dependencies and separately verify both products/formats and state/automation. Preserve upstream MIT and dependency notices and existing consumer judgement; this is an acceleration assessment, not a rights audit.
