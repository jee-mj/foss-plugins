# AUDIO-031 — MeterMaid

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `GareBear99/MeterMaid`, pinned `48f06f7f8288dca777889afc7d5a6bddf4537382`; official commits/tree/contents APIs inspected.

One metering product: `MeterEngine` computes peak/RMS, correlation, oversampled true peak, K-weighted loudness/LRA and windowed FFT spectrum/chroma. These are conventional signal measurements, not model inference. The callback feeds this engine and its frame pipe. CMake declares AU/VST3/Standalone, caller-supplied JUCE, and an optional reference-tone test. Presence of upstream test source is not a passing calibration result in this campaign.

Pinned upstream assessment evidence:
- [Processor](https://github.com/GareBear99/MeterMaid/blob/48f06f7f8288dca777889afc7d5a6bddf4537382/MeterMaid/Source/PluginProcessor.cpp)
- [Actual measurement/FFT algorithms](https://github.com/GareBear99/MeterMaid/blob/48f06f7f8288dca777889afc7d5a6bddf4537382/MeterMaid/Source/MeterEngine.h)
- [Build and optional calibration target](https://github.com/GareBear99/MeterMaid/blob/48f06f7f8288dca777889afc7d5a6bddf4537382/MeterMaid/CMakeLists.txt)

No neural/GPU provider evidenced; backends empty. Next action: pin JUCE, resolve Linux/Windows target portability and separately establish meter calibration/host behavior. Native Windows and Wine require separate acceptance. All evaluation/build/load/model_execution/provider_execution/host stages are **not-run**; future AMD hardware stages **not-run-policy**. Existing rights fields preserved, informational rather than technical gate.
