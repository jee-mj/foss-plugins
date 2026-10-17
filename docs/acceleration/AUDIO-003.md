# AUDIO-003 — Miserere

Assessment date: 2026-10-17. Repository: `basilica-audio/Miserere`.
Pinned source: `19888064eb9a44f5ddf3cd32d5643fdadde3e85d`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** Conventional vocal DSP:
de-essing, EQ, tape saturation, direct FET processing and parallel crush, opto,
spread and slap buses. No inference/training/server requirement is integrated in
the inspected engine or build. This is one product with several conventional DSP
stages, not several independently accelerated suite products.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/basilica-audio/Miserere/blob/19888064eb9a44f5ddf3cd32d5643fdadde3e85d/CMakeLists.txt): C++20 JUCE AU/VST3/standalone and test targets; JUCE DSP linkage, no ML provider.
- [MiserereEngine.cpp](https://github.com/basilica-audio/Miserere/blob/19888064eb9a44f5ddf3cd32d5643fdadde3e85d/src/dsp/MiserereEngine.cpp): `process` directly calls de-essers, console EQ, saturation, FET/opto processors, pitch spread and slap delay, then sums buses and limits output.

Source is newer than release `v0.7.0`, whose tag resolves to
`6ce6cc2deb616f337622e36c747a292f505ea0b7`. GitHub lists Windows/macOS
assets; current-source conclusions do not establish the contents of those archives.

## Backend disposition and next action

Non-neural vocal-chain component; no inference/GPU backend or model references.
Reconcile the source pin with the selected release before investigating native
portability or the Windows/Wine route. Wine is unverified, independently of native
Windows availability. No campaign validation stages were run.
