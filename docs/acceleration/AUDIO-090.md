# AUDIO-090 — OBSIDIAN-Neural

Assessment: **complete** · AI role: **mixed** (local and external inference) · execution: **mixed** (background generation and external service).

## Exact identities and release boundary

- Plugin inspected HEAD: `innermost47/ai-dj@2e556b9952f4bb05904ee8c191fe05072598774f`.
- Catalog release tag `v350`: **`dcc21142fe62283e61f1ab096ec3a6e004dc813d`**. Its CMake declares **3.2.0**, and release metadata names Linux 3.2.0 tar.gz, win64 EXE and Darwin PKG. Thus `v350` is not evidence for a 3.5.0 artifact. CMake, SA3 pipeline and model constants were also inspected at this release commit. Plugin backend records below use this release pin.
- Separate server: `innermost47/obsidian-neural-gpu-server@29ed0cdcb971ff5840243bcf43f988055b97396d`. Its runtime/provider evidence is independent of the plugin release. No server package/export is implemented here.

GitHub contents API blob identities also confirm that `LocalGenerationEngine.cpp`, `GenerationManager.cpp` and `DjIaClient.cpp` are byte-identical between the inspected plugin HEAD and the pinned v350 source. Their generation-routing evidence therefore applies directly to the selected release source as well.

## Actual local CPU path

`LocalGenerationEngine.cpp` constructs the SA3 pipeline and calls generation. `GenerationManager.cpp` routes local versus API requests and launches generation work away from the audio playback callback. At the release pin, `SA3PipeLine.cpp` creates ONNX Runtime sessions for text encoder, DiT, decoder and encoder, with global CPU thread pools (intra-op 4, inter-op 1) and no CUDA, DirectML, ROCm or CoreML EP append. CMake requests ordinary CPU ONNX Runtime **1.26.0** archives per OS/architecture. The existence or successful loading of these release artifacts was not independently checked.

The actual local factory uses SA3 ONNX; the repository also retains older `StableAudioEngine.cpp` child-process code expecting TFLite files. That older code is not proof that the current local factory uses a TFLite/GPU runtime. The baseline assessed here is SA3 ONNX CPU, not a GPU server dependency in every plugin.

## Separate external GPU server

The plugin's `DjIaClient.cpp` POSTs to configured `/process`. Server generation modules load PyTorch models, move tensors/models to a selected device and run generation. `device_utils.py` selects CUDA first, otherwise Apple MPS, otherwise rejects the device. CPU staging/cleanup of models is not a supported server CPU generation fallback; plugin-local CPU inference is a separate component.

| Route | Source-backed disposition |
| --- | --- |
| Linux NVIDIA | Implemented PyTorch CUDA source route. `install.sh` requests torch/torchaudio 2.7.1, torchvision 0.22.1 from `cu126` (CUDA 12.6) index. |
| Native Windows NVIDIA | Separate `install.bat` has the same requested CUDA tuple; no Windows execution performed and no Wine equivalence. |
| macOS Apple | Implemented MPS path. Installer checks arm64 Python and uses PyTorch 2.7.1; MPS patches and non-quantized branch differ from CUDA. No hardware acceptance performed. |
| Linux AMD | **port-required**. Installers select NVIDIA wheels; SAO1 CUDA branch uses bitsandbytes 8-bit loading. ROCm framework/quantization/kernel compatibility and a pinned supported environment need actual port work. A `torch.cuda` API name alone neither proves nor disproves HIP: inspect `torch.version.hip` and provider build in a future port. No ROCm runtime tuple is invented. |

`requirements.txt` contains lower bounds (torch >=2.2, diffusers >=0.27, transformers >=4.40, bitsandbytes >=0.43) and unpinned packages; installer requests are **not a reproducible resolved environment**. cuDNN and artifact hashes are unknown. Optional flash-attn wheel setting is empty by default, so it is not a verified required backend or fetched artifact. No installer was executed.

## Model provenance, terms and acquisition

No models or manifests were fetched. All model refs are unacquired, with unknown repository revisions, SHA-256 and size. A pinned code commit does not freeze the remote `main` branches it names.

- **Local SA3 ONNX conversion:** `DataConst.h` names the author's `innermost47/stable-audio-open-3-medium-onnx` Hugging Face repository and mutable `resolve/main` URLs for `dit.onnx`, `dit.onnx.data`, `dec_dynamic_bf16.onnx`, `enc_dynamic_bf16.onnx`, `encoder.onnx`, `tokenizer.json` and a manifest. These form a model bundle, not one hashable known model file yet. AssetDownloadManager has download logic, which was not invoked.
- **Server default:** `settings.py` maps stable-audio-open-1.0 to `stabilityai/stable-audio-open-1.0`.
- **Server SA3:** `settings.py` maps stable-audio-3-medium to `stabilityai/stable-audio-3-medium`; its generator uses stable-audio-tools.
- **Other server selections:** Foundation-1 points to `RoyalCities/Foundation-1` (`Foundation_1.safetensors` and config). Six other checkpoint/config pairs are served from `innermost47/obsidian-neural-models`: `audialab-edm-elements`, `rc-infinite-pianos`, `rc-vocal-textures`, `sao-instrumental`, `stablebeat`, `gluten-v1`. These are separate provenance/terms reviews, not automatically covered by a generic Stability grant. Backend model refs record the default SAO1 and SA3 candidates only; additional selectable models require their own immutable byte identities before execution.
- Plugin third-party notices explicitly state models are not distributed with the software and attribute Stable Audio to Stability AI Community License and T5Gemma to Gemma terms. These are upstream attributions, not a completed audit of a converted bundle or every server checkpoint. Preserve AGPL plugin evidence, separate model/service restrictions and consumer judgement; no rights are granted by this assessment.

## Pinned upstream assessment evidence

- [Release CMake / ORT 1.26.0 / version](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/CMakeLists.txt)
- [Release SA3 sessions and CPU threads](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/src/sa3/SA3PipeLine.cpp)
- [Release model URLs](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/src/data/DataConst.h)
- [Release third-party/model notices](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/THIRD-PARTY-LICENSES.txt)
- [Release local factory (identical to inspected HEAD)](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/src/managers/core/LocalGenerationEngine.cpp)
- [Release generation routing/worker launch (identical to inspected HEAD)](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/src/managers/core/GenerationManager.cpp)
- [Release HTTP client (identical to inspected HEAD)](https://github.com/innermost47/ai-dj/blob/dcc21142fe62283e61f1ab096ec3a6e004dc813d/src/engines/DjIaClient.cpp)
- [Server device selection](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/device_utils.py)
- [Server Linux/macOS installer source](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/install.sh)
- [Server Windows installer source](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/install.bat)
- [Server requirements](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/requirements.txt)
- [SAO1 quantized CUDA / non-quantized MPS paths](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/audio_generator.py)
- [SA3 actual inference](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/sa3_generator.py)
- [Server model map](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/settings.py)

## Campaign status and next action

All recorded routes are **not-packaged**, package attributes/runtime IDs null. Evaluation/build/load/model/provider/host stages are **not-run**, except the AMD model/provider/host stages are **not-run-policy**, with an explicit campaign-policy reason. No upstream logs are campaign results; no model/provider execution or performance claim is made. Native Windows, Wine and Linux contexts do not validate each other.

Next action: preserve plugin CPU baseline, reconcile v350/3.2.0 source identity and explicit model acquisition, then independently pin/package a loopback-default, non-autostart server after authorization. AMD needs source/dependency port work and remains hardware-policy-skipped.
