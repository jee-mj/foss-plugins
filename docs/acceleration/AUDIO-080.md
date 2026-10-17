# AUDIO-080 — They/Them

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Pinned source: `nanokataclysm/they-them@cab36f2eda28e00fcb455a713e8e330bd9174c6b`.

`Source/VocalEngine.cpp` implements bounded 64-sample processing, pitch/formant smoothing, envelope removal/restoration, high-pass filtering and latency-aligned dry/wet paths. It calls the streaming transform, backed by vendored stftpitchshift. These are conventional CPU spectral/vocoder operations, not trained inference. CMake builds a DSP library from the vendored headers and the plugin from JUCE; the current pin is JUCE 9.0.2 at full commit `72782788ce18c2d4d760b28e0921d6ffc6431102`, rather than a runtime ML framework.

## Upstream assessment evidence

- [VocalEngine processing](https://github.com/nanokataclysm/they-them/blob/cab36f2eda28e00fcb455a713e8e330bd9174c6b/Source/VocalEngine.cpp)
- [Build and dependency declarations](https://github.com/nanokataclysm/they-them/blob/cab36f2eda28e00fcb455a713e8e330bd9174c6b/CMakeLists.txt)

No model/provider backend is identified; backend and model arrays are empty. CPU-native build investigation is appropriate. Live microphone/headphone acceptance and plugin-host behavior are untested; upstream QA documents do not constitute campaign passes. All campaign stages remain not-run, and no build or executable was run.

Rights: retain AGPL-3.0, separate MIT DSP and JUCE obligations as informational pending audit; no change to consumer judgement.

Next action: review the streaming DSP dependency and latency, then authorize a Linux CPU baseline build separately.
