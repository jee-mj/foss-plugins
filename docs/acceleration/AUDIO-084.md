# AUDIO-084 — MXTune Reborn

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Inspected HEAD: `d388d8aba60576f653420a3e6d57dcdf6778e4a4`.

The actual `mx_tune.cpp` path selects Aubio YIN/YIN-fast or autotalent-style pitch detection, then SoundTouch, Rubber Band, SMB or talent pitch shifting with conventional delay/scale correction. `pitch_detector_aubio.cpp` calls `aubio_pitch_do` and converts detected frequency to pitch/confidence. CMake links JUCE and conventional audio libraries including FFTW. Pitch detection and automatic correction here are not trained inference. No neural backend/model record is warranted.

## Upstream assessment evidence

- [Build](https://github.com/alexander-shch/MXTune-reborn/blob/d388d8aba60576f653420a3e6d57dcdf6778e4a4/CMakeLists.txt)
- [Detector/shifter selection and audio loop](https://github.com/alexander-shch/MXTune-reborn/blob/d388d8aba60576f653420a3e6d57dcdf6778e4a4/src/mx_tune.cpp)
- [Aubio implementation](https://github.com/alexander-shch/MXTune-reborn/blob/d388d8aba60576f653420a3e6d57dcdf6778e4a4/src/pitch_detector_aubio.cpp)

`v2.0.0` resolves to `b9bc02965f7afcdd4bef7759a8d9e27d5823bc9f`, different from inspected HEAD. Its three OS ZIP names are release provenance, not evidence that this HEAD or any GPU runtime was tested. All campaign stages remain not-run. CPU-native packaging is the useful route; Wine behavior is not implied by native Windows releases.

Rights: retain GPL-3.0 and separate autotalent/FFT/dependency notices; obligations remain informational pending audit.

Next action: choose release or HEAD, pin conventional dependencies and check CPU latency/host behavior in a separately authorized build.
