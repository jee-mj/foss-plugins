# AUDIO-007 — Seraph

Assessment date: 2026-10-17. Repository: `basilica-audio/Seraph`.
Pinned source: `dc35c49ebbcf6e80363e08d457a1e1cc2096c183`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** Choir/vocal processing
uses conventional de-essing, IIR air shelving, compression and doubling. Spectral
pitch shifting is conventional DSP, not evidence of neural inference.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/basilica-audio/Seraph/blob/dc35c49ebbcf6e80363e08d457a1e1cc2096c183/CMakeLists.txt): C++20/JUCE AU/VST3/standalone; Signalsmith Stretch and portable C++ FFT path, no ML provider integration.
- [SeraphEngine.cpp](https://github.com/basilica-audio/Seraph/blob/dc35c49ebbcf6e80363e08d457a1e1cc2096c183/src/dsp/SeraphEngine.cpp): `process` runs de-esser, high shelf, compressor, doubler and gain on slices with latency-compensated dry mixing.

Release `v0.4.0` resolves to `d851142d0b64a0a70970dc6f628956b03a3973af`,
different from the inspected current source. Windows/macOS release asset names
do not establish Linux support or Wine execution.

## Backend disposition and next action

One non-neural vocal-chain component, empty backend/model/runtime collections.
Reconcile source versus release and investigate CPU platform portability or the
Windows/Wine route. All campaign validation stages were not run.
