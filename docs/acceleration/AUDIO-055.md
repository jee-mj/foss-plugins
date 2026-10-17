# AUDIO-055 — Purrification

Assessment: **complete; inference; background-job** (offline experimental controller only), 2026-10-17.
Pinned source: `AlexSabaka/purrification` at `12b9f264354c6cd53137eb2b88e75020e4456e49`.

## Distinct components
- Production JUCE/iPlug2/embedded physical synthesis: the [JUCE processor](https://github.com/AlexSabaka/purrification/blob/12b9f264354c6cd53137eb2b88e75020e4456e49/Source/PluginProcessor.cpp) maps MIDI/APVTS controls into `CatEngine::render`; it does not instantiate the ONNX controller.
- Experimental offline controller: [OnnxController.cpp](https://github.com/AlexSabaka/purrification/blob/12b9f264354c6cd53137eb2b88e75020e4456e49/Source/dsp/inference/OnnxController.cpp) creates CPU memory tensors, a default ORT session and invokes `Session::Run`, carrying recurrent state. No CUDA, MIGraphX, DirectML or CoreML provider is appended.
- [CMakeLists.txt](https://github.com/AlexSabaka/purrification/blob/12b9f264354c6cd53137eb2b88e75020e4456e49/CMakeLists.txt) defaults `PURRIFICATION_WITH_ONNX=OFF`, links ORT **only into PurrificationTests**, and resolves unversioned Homebrew ORT (arm64 hints). Plugin wiring is explicitly future work. Background-job describes offline testing, not a running plugin inference thread.

## Model/runtime provenance
[gen_stub_onnx.py](https://github.com/AlexSabaka/purrification/blob/12b9f264354c6cd53137eb2b88e75020e4456e49/tools/gen_stub_onnx.py) creates a deterministic randomly initialized tiny RNN: **not trained**, not a completed talking-cat model. The bundled `tests/fixtures/stub_controller.onnx` tree metadata reports 6,907 bytes (Git blob `df21997d9d10cebc09ed18ef6288e6b3d0b345ce`, not SHA-256). No model bytes acquired. Repository AGPL evidence does not independently establish future trained-weight terms. ORT version/hash unresolved by the build; this is an experimental CPU harness, not packaged plugin inference.

## Next action and validation
Pin ORT and establish a real model/control contract before wiring a worker into the plugin. NVIDIA/AMD providers would require implementation; none is claimed. Wine is unknown. All validation stages not-run; no upstream test names/logs count as campaign results. Existing catalog fields remain untouched.
