# AUDIO-075 — BadHumors

Assessment date: 2026-10-17. Repository: `niflheimmer/badhumors`.
Pinned source: `afccd67ecd46773b348005174b0c59046e551590`; official GitHub commit, tree and pinned contents API inspection.

## Outcome and source evidence

**complete; ai_role: none; execution_mode: not-applicable.** Component `badhumors` is one Cabbage/Csound plugin with four internal effects, not four separately deployed neural products.

- [Pinned repository tree](https://github.com/niflheimmer/badhumors/tree/afccd67ecd46773b348005174b0c59046e551590): source discovery.
- [BadHumors.csd](https://github.com/niflheimmer/badhumors/blob/afccd67ecd46773b348005174b0c59046e551590/BadHumors.csd): actual plugin definition and orchestra/score. `startup`, `main` and `sequencer` operate controls; score starts `effects`. Its `inch` → conditional `trackerSplice`/`fold`/`distort`/`comb` → `outs` chain directly implements slicer, bitcrusher, distortion and comb reverb. The custom splicer uses a table/phasor sample buffer, not a neural model.

This CSD is the executable DSP source and plugin-definition input. Framework binary/export wrapping remains separate packaging work; no build or installer was executed.

## Disposition

Linux CPU `csound-cabbage-dsp`, architecture unknown; integration `not-packaged`. Export/runtime ID null and runtime pins/model refs empty. No neural/model loading, external inference or GPU-audio dispatch in the inspected CSD route. Existing catalog runtime-version descriptions are not promoted into a verified fetched runtime tuple.

All six validation stages `not-run`. No Windows/Wine GPU compatibility inferred. Any future AMD GPU model/provider/host stage remains `not-run-policy` because hardware execution is outside campaign policy; no speculative AMD backend is listed.

Next: pin compatible Cabbage/Csound inputs and verify actual Linux export format under separate authorization. Preserve the informational incomplete GPLv2 full-license evidence and review framework notices; missing license detail is not a technical assessment gate.
