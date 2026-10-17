# AUDIO-064 — PeakEater

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `vvvar/PeakEater` at `a99b8db4e67a125216634fdcab663050f7cc3add`, identical to the catalog's existing source package revision.

- [Clipper.cpp](https://github.com/vvvar/PeakEater/blob/a99b8db4e67a125216634fdcab663050f7cc3add/source/processor/Clipper.cpp): upsampling, IIR prefilter, pre-gain, selected analytic sigmoid/waveshaping, post-gain/filter and downsampling. Sigmoid/tanh here are transfer functions, not a neural network.
- [CMakeLists.txt](https://github.com/vvvar/PeakEater/blob/a99b8db4e67a125216634fdcab663050f7cc3add/CMakeLists.txt): JUCE, CLAP extensions and plugin artifacts; no model runtime integration.

Existing `peakeater` source-build and scoped artifact/load evidence belongs to existing catalog `distribution`/`verification` and `docs/peakeater.md`. **No inference/backend stage is passed by that evidence.** This report makes no change to those fields and introduces no backend package alias. Empty backends represents no recorded inference route, not an unpackaged claim about the existing DSP package. Next: retain source package baseline and separately undertake DAW/audio/GUI acceptance if authorized. No new evaluation/build/load/model/provider/host test was run; Wine remains unknown. Existing source-license judgement is unchanged and informational here.
