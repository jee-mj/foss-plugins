# AUDIO-089 — Sledge Distortion / NAM

Assessment: **complete** · AI role: **inference** · execution: **audio-callback**.
Inspected current source: `elarmuzik1993/Distortion@c65f1e04efa808203d95c2c90828e173117501ca`.

## Critical release distinction

The catalog's `v2.3.0` resolves to **`377f2832d33dec48ecf9929b8f39401ff52e34df`**. Its CMake has no NAM/Eigen integration and its recursive tree has no `Source/Nam` implementation. The NAM evidence below belongs to the later inspected HEAD, **not the v2.3.0 Linux/Windows/macOS release payloads**. Those payloads were not downloaded or tested. A package must deliberately select a NAM-bearing revision rather than labeling v2.3.0 as neural on the basis of today's README.

## Actual inference and build path

- Current CMake fetches NeuralAmpModelerCore at `0b3d3c97b0859a3a8c92a8628c4dd89a25eb5842`, compiles its C++20 sources as an object library and attaches them to plugin formats so static model registrars are retained.
- Eigen is pinned to `bc3b39870ecb690a623a3f49149a358b95c5781d`, with archive SHA-256 `5f6557d1aca6e959a4b955c55f2935261fd30de59c0c79e35bc6d5cbe1de22d1`. Compile definitions include `NAM_SAMPLE_FLOAT`, `NAM_ENABLE_A2_FAST` and `EIGEN_MPL2_ONLY`.
- `NamProfile::load` parses user `.nam` profiles with `nam::get_dsp`, duplicates model configuration for channels and checks supported mono input/output. `prepare` resets/prewarms the model; `process` uses a resampling island and directly invokes `model.process` on audio buffers.
- The pinned NAM Core's WaveNet source uses `Eigen::MatrixXf`; its LSTM performs CPU Eigen `noalias` matrix/vector products. This is actual CPU C++ inference, not ONNX, CUDA or ROCm. No GPU implementation is established by this source.
- Built-in clipping/filtering remains a separate non-neural DSP component. Choosing built-in clipping is not a model-equivalent GPU fallback.

## Upstream assessment evidence

- [Current CMake](https://github.com/elarmuzik1993/Distortion/blob/c65f1e04efa808203d95c2c90828e173117501ca/CMakeLists.txt)
- [NAM profile load/prewarm/process](https://github.com/elarmuzik1993/Distortion/blob/c65f1e04efa808203d95c2c90828e173117501ca/Source/Nam/NamProfile.cpp)
- [NAM Core WaveNet implementation](https://github.com/sdatkinson/NeuralAmpModelerCore/blob/0b3d3c97b0859a3a8c92a8628c4dd89a25eb5842/NAM/wavenet/model.cpp)
- [NAM Core LSTM implementation](https://github.com/sdatkinson/NeuralAmpModelerCore/blob/0b3d3c97b0859a3a8c92a8628c4dd89a25eb5842/NAM/lstm.cpp)
- [v2.3.0 CMake](https://github.com/elarmuzik1993/Distortion/blob/377f2832d33dec48ecf9929b8f39401ff52e34df/CMakeLists.txt)
- [Current third-party notices](https://github.com/elarmuzik1993/Distortion/blob/c65f1e04efa808203d95c2c90828e173117501ca/THIRD-PARTY-NOTICES.md)

## Models, routes and validation

The useful baseline is `nam-eigen` CPU inference. Native Linux, Windows and macOS source routes are described separately in the JSON; architecture remains unknown rather than inferred from an uninspected artifact. Wine has no campaign evidence. No named export exists for this catalog-only entry: all integration statuses are not-packaged and package attributes null.

Profiles are **user-supplied**, with unknown selected bytes, hash, size and terms. No model was acquired. NAM Core example models are test fixtures referenced by CMake and upstream notices, not evidence that an end-user profile was licensed or executed. NAM Core is MIT and Eigen MPL-2.0 per upstream notices; these do not license arbitrary `.nam` profiles. Preserve GPL-3.0 plugin, profile and third-party rights review separately. Reporting/telemetry concerns already in the catalog remain informational and need review before any host run.

All six validation stages on each recorded CPU backend are **not-run**. No upstream test or speed claim is a campaign result. No GPU route is advertised; AMD hardware was not exercised.

Next action: select a NAM-bearing source revision, finish dependency/profile provenance review, then separately authorize a CPU baseline and callback/deadline/host tests.
