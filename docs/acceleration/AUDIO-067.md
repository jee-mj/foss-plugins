# AUDIO-067 — Wolf Shaper

Assessment date: 2026-10-17. Repository: `wolf-plugins/wolf-shaper`.
Pinned source: `d38cc33d482de21ecc76d9b817ec5f8dea1fb5fb`, resolved with official GitHub API and inspected through pinned tree/contents APIs.

## Outcome and source route

**complete; ai_role: none; execution_mode: not-applicable.** One non-neural product component, `wolf-shaper`. `run` upsamples incoming buffers, evaluates the editable graph per sample, mixes dry/wet with gain, optionally removes DC, then downsamples. This positively identifies conventional spline waveshaping and filtering rather than a learned model.

- [WolfShaperPlugin.cpp](https://github.com/wolf-plugins/wolf-shaper/blob/d38cc33d482de21ecc76d9b817ec5f8dea1fb5fb/src/WolfShaperPlugin.cpp), lines 377–473: actual callback and sample arithmetic.
- [src/Makefile](https://github.com/wolf-plugins/wolf-shaper/blob/d38cc33d482de21ecc76d9b817ec5f8dea1fb5fb/src/Makefile): DSP sources include Graph, Oversampler, ParamSmooth and DSPFilters; DPF supplies plugin format targets.

## Disposition

Linux CPU backend `dpf-cpp-dsp`; architecture unknown. No source-supported neural or GPU-audio provider identified in the inspected callback/build route. GUI rendering does not establish GPU audio. Native Windows availability would not by itself validate Wine or a vendor GPU route.

Integration `not-packaged`; package attribute/runtime ID null. Pins/models empty; no model is required by the inspected processing algorithm and no dependency artifact was acquired. All six backend validation stages are `not-run`. Future AMD GPU hardware stages must remain `not-run-policy` under campaign policy; no speculative AMD backend is added.

Next: pin DPF and DSPFilters provenance, then separately authorize CPU build/load/host checks and inspect exact formats. Preserve existing GPL and format-SDK/dependency concerns; no rights finding here overrides consumer judgement.
