# AUDIO-085 — Humus

Assessment: **complete** · AI role: **mixed** (local and external inference) · execution: **mixed** (tracker workers and external service requests).
Pinned source: `phobos-instruments/humus@141d8c1e543c5d85dff4268f965c625126162561`.

## Component-specific findings

The modular audio environment must not be treated as one uniform inference backend:

| Component | Actual source path and conclusion |
| --- | --- |
| Audio graph/instruments/effects | Conventional modular application/DSP; hosting another plugin does not establish that plugin's inference provider. |
| AV Hands | Worker-thread camera landmark inference. Portable `HumNet` interpreter runs detector/landmark models; on macOS a CoreML model path can be preferred. |
| AV Skeleton | Separate worker-thread body/pose detector and landmark model; portable HumNet plus macOS CoreML path. Different models from Hands. |
| AI assistant | `AiClient.h` launches background HTTP requests to a configurable Ollama service or Anthropic messages API. This is external inference, not an embedded LLM or an established CUDA/ROCm runtime. |

`HumNet.h` contains explicit convolution, depthwise, fully-connected and other neural operators plus a CPU worker pool. `HandsPortable.cpp` and `BodyPortable.cpp` load `.humnet` detector/landmark data; corresponding macOS paths load CoreML `.mlpackage` models. `CoreMLNetMac.mm` calls `predictionFromFeatures` with `MLComputeUnitsAll`: it permits system-selected CPU/GPU/Neural Engine execution but does not prove a particular device executed. The JSON records useful Linux CPU and macOS Apple routes; portable Windows intent is not Windows or Wine acceptance.

The assistant's default model strings (including `llama3.1` and the source's `claude-sonnet-5`) are configuration literals, not evidence those models exist, are downloaded, licensed, reachable or executed. Hardware/provider selection is owned by the external service and stays unknown.

## Model provenance and build behavior

Hands and Skeleton use different MediaPipe-derived model pairs. Upstream READMEs attribute Apache-2.0 to the respective MediaPipe Hands and BlazePose GHUM model cards. Source distributions omit the generated models. CMake can automatically download Google's task bundles, convert them to `.humnet`, check declared hashes, and on macOS generate CoreML packages. **No configure step was run and no model was downloaded here.** This behavior must be isolated before any later evaluation/build.

| Asset | Upstream-declared SHA-256 (not campaign-acquired bytes) |
| --- | --- |
| Google hand_landmarker.task | `fbc2a30080c3c557093b5ddfc334698132eb341044ccee322ccf8bcf3607cde1` |
| Converted hands.humnet | `29f7f8ab9e50dc1eb82cc904262198edb150c7473a856b79352e4b85c7976b85` |
| Google pose_landmarker_full.task | `5134a3aad27a58b93da0088d431f366da362b44e3ccfbe3462b3827a839011b1` |
| Converted body.humnet | `a4039232262fc38c7220b58372792ab7358856441191386ecb1988519d9495cb` |

Model refs describe the derived assets as manual/unacquired. Converted CoreML artifacts have no established hashes or sizes. Source/model terms are separate: preserve AGPL-3.0 catalog evidence, the inspected AV files' GPL-3.0-only headers, third-party/trademark notices and model-card attribution without treating them as a new grant. Missing or unresolved terms are informational rather than the technical gate.

## Pinned upstream assessment evidence

- [Build entry point](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/engine/CMakeLists.txt)
- [HumNet neural operators / CPU workers](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/common/HumNet.h)
- [Hands portable loading](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/organisms/Hands/HandsPortable.cpp)
- [Hands worker](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/organisms/Hands/Hands.cpp)
- [Skeleton portable loading](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/organisms/Skeleton/BodyPortable.cpp)
- [Skeleton worker](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/organisms/Skeleton/Skeleton.cpp)
- [CoreML execution configuration](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/common/CoreMLNetMac.mm)
- [Hands model build pins](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/engine/cmake/HandsModel.cmake)
- [Body model build pins](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/engine/cmake/PoseModel.cmake)
- [CoreML conversion/fallback](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/engine/cmake/CoreMLModels.cmake)
- [Hands provenance/terms](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/assets/Models/hands/README.md)
- [Body provenance/terms](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/packs/av/assets/Models/body/README.md)
- [Actual assistant requests](https://github.com/phobos-instruments/humus/blob/141d8c1e543c5d85dff4268f965c625126162561/engine/src/gui/assistant/AiClient.h)

All backend integration statuses are not-packaged; all validation stages are not-run. No CPU, Apple or external-service execution claim is promoted from upstream. No NVIDIA/AMD tracker runtime is established, and no AMD hardware was exercised. External Ollama GPU capability cannot be inferred from this client's HTTP transport.

Next action: make model acquisition explicit and separately authorized, isolate configure-time downloads/conversion, then establish CPU tracker and optional Apple baselines separately from the external assistant service.
