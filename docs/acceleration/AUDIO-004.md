# AUDIO-004 — Giannitune

Assessment date: 2026-10-17. Repository: `jonnygucci1/Giannitune`.
Pinned source: `6b5da7f1d7774c0b9789fc4b4d7906585f9406b5`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** Pitch correction is
implemented through numerical YIN detection, scale quantization and Signalsmith
pitch shifting, with conventional exciter/output shaping. Pitch detection and
automatic correction do not by themselves imply neural inference.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/jonnygucci1/Giannitune/blob/6b5da7f1d7774c0b9789fc4b4d7906585f9406b5/CMakeLists.txt): C++17/JUCE plugin targets and DSP sources, macOS universal settings; no ML runtime linkage.
- [FetchDependencies.cmake](https://github.com/jonnygucci1/Giannitune/blob/6b5da7f1d7774c0b9789fc4b4d7906585f9406b5/cmake/FetchDependencies.cmake): build dependency declaration inspected alongside the processor.
- [PluginProcessor.cpp](https://github.com/jonnygucci1/Giannitune/blob/6b5da7f1d7774c0b9789fc4b4d7906585f9406b5/src/PluginProcessor.cpp): `processBlock` runs pitch detector, quantizer and Signalsmith shifter, then exciter/soft output protection.
- [PitchDetector.cpp](https://github.com/jonnygucci1/Giannitune/blob/6b5da7f1d7774c0b9789fc4b4d7906585f9406b5/src/dsp/PitchDetector.cpp): conventional numerical pitch-estimation implementation.

GitHub release API returned no releases. This assesses the pinned source, not
the uninspected Gumroad download.

## Backend disposition and next action

One non-neural DSP component; no model/runtime/provider requirement. Inspect
Signalsmith/JUCE dependency pins and Windows or Linux build portability before
packaging. Native Windows availability would not prove Wine behavior. All campaign
validation stages were not run.
