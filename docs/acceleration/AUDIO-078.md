# AUDIO-078 — SubDominant

Assessment date: 2026-10-17. Repository: `astriiddev/Sub_Dominant-VST`.
Pinned source: `00f7ae41bbdb19a67f810c134327f32e835c5afc`; official GitHub commit/tree/contents API inspection.

## Outcome and evidence

**complete; ai_role: none; execution_mode: not-applicable.** Component `sub-dominant` is rectifier/octave-divider/filter/fuzz DSP on CPU.

- [PluginProcessor.cpp](https://github.com/astriiddev/Sub_Dominant-VST/blob/00f7ae41bbdb19a67f810c134327f32e835c5afc/Source/PluginProcessor.cpp), lines 138–206: callback applies input gain and full-wave rectification, two-pole low-pass filtering, two pulse-counter octave divisions, mixing and one-pole filtering. Following definitions implement explicit RC-filter coefficient/recurrence arithmetic. This is component emulation using conventional DSP rather than neural circuit inference.
- [subdominant.jucer](https://github.com/astriiddev/Sub_Dominant-VST/blob/00f7ae41bbdb19a67f810c134327f32e835c5afc/subdominant.jucer): declares `buildVST3` and processor/editor/PulseGen source inputs. This establishes a build declaration, not contents of the Linux release archive.

## Disposition

Linux CPU `juce-cpp-octave-dsp`, architecture unknown; source processing is implemented, packaging/build portability unverified. No neural-model or GPU-audio provider identified in the inspected processing/build routes. No Windows/Wine GPU claim follows from shared source.

Integration `not-packaged`, package attribute/runtime ID null; runtime pins/model refs empty. All six backend validation stages `not-run`. No speculative AMD backend; future AMD GPU model/provider/host stages remain `not-run-policy` because AMD hardware execution is excluded.

Next: resolve JUCE/Projucer inputs and exact Linux exporter/bundle format, then separately authorize CPU build/load/host checks. Preserve GPL/source and dependency notices and consumer rights judgement. Archive-format uncertainty is a packaging follow-up, not a blocker to the source-backed non-neural assessment.
