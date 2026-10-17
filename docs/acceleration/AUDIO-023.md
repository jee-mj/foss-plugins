# AUDIO-023 — polez-vst

- Wrapper: `audiohacking/polez-vst` at `9f720bf9b1086f1866d422cff0f66826a465b564`
- Actual backend: `szichedelic/polez` at wrapper gitlink `b7cb70f9c4ec42668ee5e90d25478b09a5b87b4d`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

## Wrapper and actual processing

[.gitmodules](https://github.com/audiohacking/polez-vst/blob/9f720bf9b1086f1866d422cff0f66826a465b564/.gitmodules) resolves `third_party/polez` to the official backend. [Cargo.toml](https://github.com/audiohacking/polez-vst/blob/9f720bf9b1086f1866d422cff0f66826a465b564/Cargo.toml) consumes that path with `default-features = false`, disabling the backend's optional GUI server; the wrapper uses Truce v0.44.0, ndarray and crossbeam queues. It does not request an inference server or GPU feature.

[processor.rs](https://github.com/audiohacking/polez-vst/blob/9f720bf9b1086f1866d422cff0f66826a465b564/src/rt/processor.rs) wraps `FingerprintRemover` in fixed-window overlap-add cleaning. [detect_worker.rs](https://github.com/audiohacking/polez-vst/blob/9f720bf9b1086f1866d422cff0f66826a465b564/src/rt/detect_worker.rs) sends analysis windows to a CPU worker using `WatermarkDetector::detect_all`. Components `fingerprint-cleaner` and `watermark-detector` are non-neural DSP; their scheduling differs, but the schema uses not-applicable for a completed non-neural assessment without GPU DSP.

The pinned backend's [Cargo.toml](https://github.com/szichedelic/polez/blob/b7cb70f9c4ec42668ee5e90d25478b09a5b87b4d/Cargo.toml) declares RustFFT, realfft, ndarray, rubato, rand and Rayon, not ONNX/PyTorch/CUDA/ROCm. [watermark.rs](https://github.com/szichedelic/polez/blob/b7cb70f9c4ec42668ee5e90d25478b09a5b87b4d/src/detection/watermark.rs) implements autocorrelation, spectral/phase/LSB statistics and threshold heuristics. Its own comments state thresholds are heuristic and uncalibrated; these are not a learned classifier or evidence of detection efficacy. [fingerprint.rs](https://github.com/szichedelic/polez/blob/b7cb70f9c4ec42668ee5e90d25478b09a5b87b4d/src/sanitization/fingerprint.rs) applies randomized temporal/phase and related transformations using explicit DSP and RNGs. “AI fingerprint” vocabulary describes the claimed target, not an inference implementation. AI-assisted authorship, if any, is distinct from runtime AI.

## Disposition and validation

Two Linux CPU backend records document actual processing, architecture unknown in these inspected source paths. They are **not-packaged**, attributes/runtime IDs null, pins/models empty: dependency version ranges are not a packaged locked runtime tuple, and no NN model was established. Backend source revisions identify the actual polez submodule; wrapper provenance is separately pinned above. Native Linux source packaging is a lead; freeze Cargo.lock/toolchain/Truce closure and inspect CPU latency before accepting host use. No established NVIDIA/AMD provider and no Wine acceleration claim.

All six validation stages **not-run**; no builds, model downloads or execution. Future AMD model/provider/host hardware stages must be **not-run-policy**, reason: AMD hardware execution is deliberately outside this campaign. Existing wrapper/backend copyright evidence is preserved and informational. Detection/sanitization efficacy remains unverified, independent of packaging.
