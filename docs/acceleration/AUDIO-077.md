# AUDIO-077 — Autokit

Assessment date: 2026-10-17. Repository identity: `Hornfisk/autokit`.
Pinned source: `5856bb8729c5617c84827507fe373fdc96eeb9ac`; official GitHub commit/tree/contents API inspection. The stable catalog repository identity is preserved.

## Outcome and separate functional routes

**complete; ai_role: none; execution_mode: not-applicable.** Sample classification here is **hand-written DSP/rules**, not neural inference. Two components have different functional runtime paths:

- `sample-analysis-map`: background library scan, FFT/time-domain feature extraction, ordered threshold rules and filename/folder hints; graphical map uses explicit weighted features.
- `drum-sampler-sequencer`: audio voice playback/mixing and sequencer, using stored sample data rather than model inference.

The schema requires `not-applicable` execution mode for completed non-neural entries. Background analysis versus callback playback is described here and in component summaries without implying a neural worker mode.

## Pinned source and build evidence

- [features.rs](https://github.com/Hornfisk/autokit/blob/5856bb8729c5617c84827507fe373fdc96eeb9ac/src/analysis/features.rs): `extract` computes centroid/flatness/sub-energy/high-frequency/attack/decay features via local arithmetic and real FFT. `classify` trusts hints unless contradicted, then uses ordered percussive/non-percussive rules. For example, kick rules compare centroid/sub-energy to literal thresholds.
- [library.rs](https://github.com/Hornfisk/autokit/blob/5856bb8729c5617c84827507fe373fdc96eeb9ac/src/analysis/library.rs): background construction reuses cached features or calls `features::extract` and `features::classify` directly.
- [scanner.rs](https://github.com/Hornfisk/autokit/blob/5856bb8729c5617c84827507fe373fdc96eeb9ac/src/analysis/scanner.rs): folder/filename token hints.
- [sample_map.rs](https://github.com/Hornfisk/autokit/blob/5856bb8729c5617c84827507fe373fdc96eeb9ac/src/ui/sample_map.rs): fixed feature-coefficient formulas position samples; no learned embedding/service is required.
- [sampler.rs](https://github.com/Hornfisk/autokit/blob/5856bb8729c5617c84827507fe373fdc96eeb9ac/src/engine/sampler.rs): `VoicePool` triggers stored sample voices and renders active voices to audio buses.
- [Cargo.toml](https://github.com/Hornfisk/autokit/blob/5856bb8729c5617c84827507fe373fdc96eeb9ac/Cargo.toml): nih-plug cdylib/standalone, Symphonia, rubato and realfft; package version 0.5.5 and GPL-3.0-or-later metadata.

## Integration and follow-up

Two Linux CPU backends: `rust-realfft-rule-classifier` and `rust-nih-plug-sampler`, architectures unknown. No source-supported neural/NVIDIA/AMD GPU-audio route found in these inspected paths. Sample files are content, not model weights. Exports/runtime IDs null, integration `not-packaged`, pins/model refs empty.

All six validation stages per backend `not-run`. Native Windows/Wine execution not verified. Future AMD GPU model/provider/host execution remains `not-run-policy` under the hardware exclusion.

Next: reconcile 0.5.5 snapshot with selected release, pin the Rust closure and verify scanning/cache, playback and saved identity separately using authorized fixtures. The manifest license claim supplements but does not replace a full grant/notice review. Preserve sample rights and the catalog's incomplete license evidence as informational concerns, with consumer judgement retained.
