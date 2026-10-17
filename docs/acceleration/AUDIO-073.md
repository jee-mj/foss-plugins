# AUDIO-073 — Niner

Assessment date: 2026-10-17. Repository: `hyperfocusdsp/niner`.
Pinned source: `4ae990f1b5ff54061031f89de1311e4ade8b1648`; official GitHub commit/tree/contents API inspection.

## Outcome

**complete; ai_role: none; execution_mode: not-applicable.** Component `niner` includes kick and clap voices, scheduling/sequencing and mastering DSP. These layers share the same CPU runtime requirements, rather than needing distinct model providers.

- [src/dsp/engine.rs](https://github.com/hyperfocusdsp/niner/blob/4ae990f1b5ff54061031f89de1311e4ade8b1648/src/dsp/engine.rs): KickVoice holds sine oscillators, pitch/amplitude envelopes, noise and click state. `KickEngine::process` advances scheduled hits, sums voice ticks, mixes a procedural clap and applies saturation/master EQ. This positively establishes conventional synthesis rather than learned inference.
- [Cargo.toml](https://github.com/hyperfocusdsp/niner/blob/4ae990f1b5ff54061031f89de1311e4ade8b1648/Cargo.toml): cdylib/rlib and standalone with pinned nih-plug fork; realfft is explicitly for output-display spectrum analysis. Snapshot package version is 1.0.2, so it must be reconciled with captured release 1.0.1 before packaging.

## Disposition

Linux CPU `rust-nih-plug-dsp`, architecture unknown; no inference/GPU-audio dependency or provider identified in the inspected engine/manifest. Random variation and graphical spectrum display are not neural/GPU-audio evidence. Integration `not-packaged`, package attribute/runtime ID null; runtime pins/models empty, with actual closure pinning left to packaging.

All six validation stages `not-run`; no native Windows or Wine execution verified. Future AMD GPU model/provider/host execution is `not-run-policy`, with no speculative AMD backend added here.

Next: reconcile release and dependency lock closure, then verify CPU formats and saved-project identity/state behavior under separate authorization. Preserve GPL/dependency notices and existing consumer rights judgement.
