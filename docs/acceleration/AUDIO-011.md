# AUDIO-011 — Mahogany

Assessment date: 2026-10-17. Repository: `sammythayermusic-ship-it/Mahogany`.
Pinned source: `de61262778e1490d5425bf12bd275762320f32d0`.

## Conclusion

**complete; ai_role inference; execution_mode worker-thread.** The optional neural
pitch detector actually creates an ONNX Runtime session and runs SwiftF0. It uses
CPU memory and default session providers, with no CUDA, ROCm, CoreML or MPS provider
append in the inspected implementation. A macOS neural build does not imply Apple
GPU/Neural Engine inference. Classic EQ/compression/pitch processing remains
conventional DSP, with YIN fallback if the neural model cannot load.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/sammythayermusic-ship-it/Mahogany/blob/de61262778e1490d5425bf12bd275762320f32d0/CMakeLists.txt): `MAHOGANY_ENABLE_ONNX` defaults OFF; optional build embeds SwiftF0 and links the vendored ORT 1.26.0 macOS dylib. Apple architecture is forced to arm64; the neural deployment target is macOS 14. Linux/Windows ORT lookup/linkage is not implemented here.
- [SwiftF0Detector.cpp](https://github.com/sammythayermusic-ship-it/Mahogany/blob/de61262778e1490d5425bf12bd275762320f32d0/Source/DSP/Pitch/SwiftF0Detector.cpp): default `Ort::SessionOptions`, one intra/inter-op thread, CPU tensor memory, embedded-model `session.Run`; worker snapshots/resamples audio and publishes pitch. Audio callback writes a ring rather than running inference.
- [SwiftF0Detector.h](https://github.com/sammythayermusic-ship-it/Mahogany/blob/de61262778e1490d5425bf12bd275762320f32d0/Source/DSP/Pitch/SwiftF0Detector.h): explicit worker/audio separation and YIN fallback contract.
- [fetch_deps.sh](https://github.com/sammythayermusic-ship-it/Mahogany/blob/de61262778e1490d5425bf12bd275762320f32d0/Scripts/fetch_deps.sh): names the ORT 1.26.0 macOS-arm64 release artifact and downloads the SwiftF0 model/license from **mutable `main`** in `lars76/swift-f0`. Script was read, never executed.

GitHub release API returned no releases. This is the current optional neural
source path, not proof of a published neural binary. The script's versioned URL
is provenance of the requested dependency, not proof the artifact was fetched.

## Backend and model disposition

| Tuple | Source status | Campaign integration |
| --- | --- | --- |
| macOS / arm64 / CPU / onnxruntime-cpu | implemented | not-packaged |
| Linux / unknown / CPU / onnxruntime-cpu | port-required | not-packaged |
| Windows / unknown / CPU / onnxruntime-cpu | port-required | not-packaged |

The Linux/Windows records describe porting needs, not upstream-supported neural
builds; no architecture is invented. GPU backends are not inferred. ORT version
is known from source; artifact hash is unresolved. Model source URL is known,
but its commit, SHA-256 and exact size are unresolved because upstream fetches a
moving branch. Upstream script describes model terms as MIT; that claim is not
an independently audited model grant. Model acquisition remains `not-requested`.

## Next action and validation

Freeze SwiftF0 bytes/provenance, replace mutable fetching, and establish the macOS
CPU baseline or explicitly port ORT discovery/linkage to Linux. Then evaluate
whether a GPU provider is beneficial for this small worker workload.
All six campaign stages are `not-run`; upstream test targets are not campaign
success evidence. No models/download scripts/builds/hardware tests were executed.
