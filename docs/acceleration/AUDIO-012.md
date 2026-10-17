# AUDIO-012 — VocalGate

Assessment date: 2026-10-17. Repository: `dan-k-k/vocal-gate`.
Pinned source: `30b58b6af9affb715f2c71f5f401b87d9304e393`.

## Conclusion

**complete; ai_role mixed; execution_mode mixed.** The repository contains both
local neural inference and a separate training pipeline. The plugin's quantized
ONNX session uses the default CPU provider, not CUDA/MPS/ROCm. Real-time inference
runs on `BackgroundMLThread`; offline bounce explicitly processes hops from the
DAW callback. Training selects MPS, then a PyTorch `cuda` device, then CPU. Training
GPU references are not plugin GPU inference support, and `torch.cuda` alone does
not prove the installed PyTorch build is NVIDIA rather than ROCm.

## Pinned upstream evidence

- [InferenceEngine.cpp](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/plugin/Source/InferenceEngine.cpp): `CreateCpu`, one-thread session options, embedded `vocalgate_int8_onnx`, `onnxSession->Run`, no accelerated EP append.
- [BackgroundMLThread.cpp](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/plugin/Source/BackgroundMLThread.cpp): extracts features and invokes inference in worker hops; offline-hop entry point uses the same inference path.
- [PluginProcessor.cpp](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/plugin/Source/PluginProcessor.cpp): dispatches worker processing during live audio, calls `processNextOfflineHop` for non-real-time processing.
- [plugin/CMakeLists.txt](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/plugin/CMakeLists.txt): embeds the INT8 model and links ORT, with Linux/macOS 1.24.2 library names and Windows DLL deployment.
- [main.yml](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/.github/workflows/main.yml): downloads CPU ORT 1.24.2 Windows/Linux x64 artifacts. Workflow text is provenance, not a campaign build result.
- [train.py](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/ml_pipeline/train.py): MPS/CUDA/CPU device choice and optimizer/checkpoint training loop.
- [export_onnx.py](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/ml_pipeline/export_onnx.py): exports and dynamically quantizes the plugin model.
- [requirements.txt](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/ml_pipeline/requirements.txt): training framework versions/provider builds are unpinned.
- [Pinned platform requirements](https://github.com/dan-k-k/vocal-gate/blob/30b58b6af9affb715f2c71f5f401b87d9304e393/README.md), line 24: macOS M-series, Windows x64 and Linux x64 are the upstream-supported platform/architecture claims. These complement the inspected build/inference code and are not hardware acceptance.

## Source versus release and model provenance

`v1.0.5` resolves to `7393d6508e979a08dcc6250ffe8eb184ef10c231`, different
from the inspected current source. Release payload/runtime identity is unverified.
Official Git tree metadata identifies `plugin/vocalgate_int8.onnx` as **93,056
bytes**, Git blob `5773aa416e64a8b29fadf04ab7cc841b48c7e583`. This is not a
SHA-256 of acquired bytes. The model was not fetched. Separate model-specific terms
and training-data provenance were not established; this is not a technical gate.

## Backend disposition and next action

CPU ORT records: Linux/x86_64, Windows/x86_64 and macOS/arm64, all source-implemented,
all `not-packaged`. Training is a distinct component; no exact GPU framework/OS
tuple is fabricated from its unpinned device-selection code. There is no plugin
GPU EP integration to package by substituting a GPU wheel/library. Establish the
Linux CPU baseline, freeze the model/runtime artifacts and reconcile release drift
before considering a measured inference-provider port.

All six campaign stages remain `not-run`; model acquisition `not-requested`.
No training, model execution, download script or hardware validation was run.
