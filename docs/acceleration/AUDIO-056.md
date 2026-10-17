# AUDIO-056 — AudioVisualiser

Assessment: **complete; external-service; external-service** for AI functionality (2026-10-17).
Pinned source: `iLucaH/AudioVisualiser` at `45895956449bccf7c9596c0b6974f68ca68a1950`.

## Separate AI and GPU paths
- [AskAI.h](https://github.com/iLucaH/AudioVisualiser/blob/45895956449bccf7c9596c0b6974f68ca68a1950/Source/AskAI.h) implements an AI Generator render state and prompt UI; [AVAPIResolver.h](https://github.com/iLucaH/AudioVisualiser/blob/45895956449bccf7c9596c0b6974f68ca68a1950/Source/AVAPIResolver.h) posts authenticated prompts to `https://audiovisualiser-service.onrender.com/prompt`. This establishes a remote AI client, not the remote model/provider/version, service availability or local NN acceleration. No service request was made.
- [VideoEncoder.cpp](https://github.com/iLucaH/AudioVisualiser/blob/45895956449bccf7c9596c0b6974f68ca68a1950/Source/VideoEncoder.cpp) selects `h264_nvenc`, creates `AV_HWDEVICE_TYPE_CUDA`, and uses CUDA/OpenGL texture interop. This is **non-neural video encoding**, not audio inference.
- [CMakeLists.txt](https://github.com/iLucaH/AudioVisualiser/blob/45895956449bccf7c9596c0b6974f68ca68a1950/CMakeLists.txt) requires CUDAToolkit, links CUDA driver and JUCE OpenGL, fetches FFmpeg 7.1 Windows MSVC x64 static libraries and WebView2. CUDA version and driver are not pinned. Source path is Windows-focused; no Linux portability result claimed.

## Disposition
Remote shader generation, local visual rendering and video export are separate components. No local AI model source is exposed. NVIDIA NVENC route is implemented upstream but unpackaged/untested here; CPU video fallback is not established by the inspected encoder (it errors if the selected codec/device fails). AMD replacement for this encoder is port-required, not implied by OpenGL. Wine GPU interop is unknown and needs independent testing. Missing repository license is informational, not a technical gate. All stages not-run; AMD model/provider/host policy-skipped if later represented as an AMD backend.

Next: document remote model/service provenance and pin CUDA/FFmpeg ABI before source packaging; inspect a non-NVIDIA video encoder separately.
