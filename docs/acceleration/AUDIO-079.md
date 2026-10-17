# AUDIO-079 — Tract Plugin Pack

Assessment: **complete** · AI role: **none** · inference execution: **not-applicable**.
Source snapshot: `xxx/tract-plugin-pack@d51775b383f339d0c72e02f6d59b99798ef93b89`.

## Source findings

This repository's `tract-dsp` is a local conventional DSP crate, not evidence of the similarly named Tract neural inference framework. The workspace declares thirteen plugin products. Their actual processing implementations were inspected through the GitHub contents API at the revision above:

| Component | Inspected implementation and backend finding |
| --- | --- |
| Gain Brain | `gain-brain/src/lib.rs`: host-buffer gain and linked parameter synchronization; CPU Rust. |
| GS Meter | `gs-meter/src/lib.rs`: stereo metering and per-sample LUFS; CPU Rust. |
| HD26 | `hd26/src/lib.rs`: transient detector, Hyper and Dimension sample processors; CPU Rust. |
| Imagine | `imagine/src/lib.rs`: FIR/IIR crossover, mid/side band processing and Hilbert recovery; CPU Rust. |
| Miff | `miff/src/lib.rs`: realfft/rustfft spectral processing and input spectrum analysis; CPU. |
| Multosis | `multosis/src/lib.rs`: grid-driven AudioEngine; conventional effect sequencing, not a model runtime. |
| Nap | `nap/src/lib.rs`: time-domain reverb or partitioned FFT convolution, with IR baking; not NN inference. |
| Pope Scope | `pope-scope/src/lib.rs`: host-buffer scope capture and renderer handoff; visualization. |
| Satch | `satch/src/lib.rs`: sample-based spectral saturation with an FFT bypass path; CPU. |
| Six Pack | `six-pack/src/lib.rs`: multiband saturation, oversampling and filter bands; CPU. |
| Tinylimit | `tinylimit/src/lib.rs`: true-peak detector and block limiter; CPU. |
| Warp Zone | `warp-zone/src/lib.rs`: 4096-sample spectral shifter; CPU FFT. |
| Wavetable Filter | `wavetable-filter/src/lib.rs`: realfft kernel synthesis, FIR/STFT convolution and fearless_simd; CPU SIMD. |

No model files, inference sessions or neural provider initialization were identified in these product processing paths. GUI OpenGL dependencies do not establish GPU audio processing. No neural backend records are warranted. `tract-dsp/Cargo.toml` explicitly gates realfft/rustfft features. `gain-brain/Cargo.toml` uses the upstream nih-plug fork and baseview; full packaging would need lockfile reconciliation rather than treating branch names as immutable pins.

## Evidence

All evidence below is **upstream / assessment**, not campaign verification:

- [Workspace](https://github.com/xxx/tract-plugin-pack/blob/d51775b383f339d0c72e02f6d59b99798ef93b89/Cargo.toml)
- [Shared DSP manifest](https://github.com/xxx/tract-plugin-pack/blob/d51775b383f339d0c72e02f6d59b99798ef93b89/tract-dsp/Cargo.toml)
- Product source links are recorded individually in the companion JSON, under this same full commit.

## Disposition

CPU-native source investigation is appropriate; no CUDA/ROCm inference dependency is supported by this inspection. No release payload or executable was downloaded. No campaign evaluation/build/load/model/provider/host checks were run. Native Windows, Wine and Linux acceptance remain separate.

Rights: preserve the catalog's GPL-3.0-or-later README claim and unresolved full-license notices as informational, with consumer judgement required. This assessment grants no model, asset or dependency rights.

Next action: reconcile Cargo.lock and thirteen product artifact identities before any authorized packaging.
