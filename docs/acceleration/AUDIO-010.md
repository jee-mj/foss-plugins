# AUDIO-010 — SmartComp

Assessment date: 2026-10-17. Repository: `frankknebeljanssen-create/SmartComp`.
Pinned source: `b7d5b67bd17351cca7cb27068970ca4642479715`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** The inspected compressor
uses conventional oversampling, envelope/dynamics laws, lookahead and automatic
level/threshold control. “Smart” and “AUTO” controls are not evidence of trained
inference, GPU use or a remote service.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/frankknebeljanssen-create/SmartComp/blob/b7d5b67bd17351cca7cb27068970ca4642479715/CMakeLists.txt): C++17/JUCE VST3/AU/standalone plus local DSP probes; no ML runtime linkage.
- [PluginProcessor.cpp](https://github.com/frankknebeljanssen-create/SmartComp/blob/b7d5b67bd17351cca7cb27068970ca4642479715/Source/PluginProcessor.cpp): conventional oversampled compressor/limiter and latency-aligned mixing, metering and automatic control state.
- [RVoxCompressor.h](https://github.com/frankknebeljanssen-create/SmartComp/blob/b7d5b67bd17351cca7cb27068970ca4642479715/Source/DSP/RVoxCompressor.h): numerical lookahead, knee/ratio/threshold constants and attack/release control laws; `.cpp` delegates implementation to this inline header.

GitHub release API returned no releases. macOS-oriented build material does not
by itself prove Windows/Linux portability.

## Backend disposition and next action

One non-neural dynamics component; no inference provider, runtime or model pins.
Establish a CPU build platform and JUCE pin before selecting native or Wine route.
Undecided licensing is not the technical gate. All campaign validation stages were
not run; upstream comments/probes do not count as campaign results.
