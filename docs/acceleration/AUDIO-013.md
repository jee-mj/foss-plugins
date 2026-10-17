# AUDIO-013 — AudioRestorationVST

Assessment date: 2026-10-17. Repository: `flarkflarkflark/AudioRestorationVST`.
Pinned source: `df7bf68c764095634b45d79f3a40839f0ff39306`.

## Conclusion

**complete; ai_role inference; execution_mode audio-callback.** The plugin's AI
denoiser really calls ONNX Runtime from its processing path. Conventional click,
crackle, filter-bank and spectral restoration are separate DSP. Optional GPU DSP
classes are also separate from neural inference and contain material unfinished
paths. No training or external inference server is required by the inspected
plugin inference implementation.

## Pinned upstream evidence

1. [CMakeLists.txt](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/CMakeLists.txt), especially lines 129–245 and 249–436: GPU DSP detection is separate from ONNX configuration. ORT defaults to **1.17.3**; Linux CPU/CUDA/legacy ROCm artifact names, Windows DirectML and macOS CoreML flags are explicit. Configuration can download dependencies; **it was not executed**.
2. [OnnxDenoiser.cpp](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/Source/DSP/OnnxDenoiser.cpp): actual CPU tensor/session execution; conditional CUDA, ROCm, DML and CoreML provider append; generic QNN append with separately configured backend. Provider readiness/session creation is not graph-node execution evidence. Auto order tries QNN, DML, CUDA, ROCm, CoreML, then CPU; explicit provider selection can disable fallback.
3. [PluginProcessor.cpp](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/Source/PluginProcessor.cpp): prepares the denoiser and invokes `onnxDenoiser.processBlock` from plugin processing when AI denoise is enabled. Model loading can also be retried from processing; callback latency/allocation behavior needs assessment.
4. [GPUBackend.cpp](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/Source/GPU/GPUBackend.cpp): CUDA/HIP device, buffer and FFT scaffolding; OpenCL FFT explicitly unimplemented, Vulkan/oneAPI initialization TODOs. HIP module loading expects compiled data, not source compilation.
5. [GPUNoiseReduction.cpp](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/Source/GPU/GPUNoiseReduction.cpp): non-neural FFT/spectral-subtraction path exists, but CUDA/HIP initialization reads `.cu`/`.hip` text and comments that precompilation is normally needed. This is not a demonstrated complete kernel pipeline.
6. [GPUSpectralProcessor.cpp](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/Source/GPU/GPUSpectralProcessor.cpp): `processGPU` is TODO and calls `processCPU`, itself simplified/unimplemented analysis; spectrogram GPU rendering also TODO.
7. [GPUBatchProcessor.cpp](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/Source/GPU/GPUBatchProcessor.cpp): batch worker exists but full GPU audio processing/profile upload remains TODO. It does not establish background neural inference or completed GPU batch restoration.
8. [models/README.txt](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/models/README.txt) and the [pinned tree](https://github.com/flarkflarkflark/AudioRestorationVST/tree/df7bf68c764095634b45d79f3a40839f0ff39306/models): filenames include provider-optimized RNNoise variants, but tree metadata contains only generic `rnnoise_48k.onnx` (1,020,606 bytes) and `rnnoise_48k_olive_dml.onnx` (1,314,085 bytes). Naming alone does not establish compatibility, provenance or model-specific terms.
9. [release.yml](https://github.com/flarkflarkflark/AudioRestorationVST/blob/df7bf68c764095634b45d79f3a40839f0ff39306/.github/workflows/release.yml), lines 66–69: macOS release configuration explicitly sets `arm64;x86_64` with ONNX and CoreML enabled. This supplies source-level architecture evidence, not a successful campaign build.

All numbered items are upstream assessment evidence at the full commit above,
not campaign verification results. Source content and tree metadata were obtained
through official GitHub APIs without fetching model bodies.

## Source versus releases

The API now lists **v1.6.36**, newer than catalog v1.6.35. Both tag commit lookups
resolve to `df7bf68c764095634b45d79f3a40839f0ff39306`. Thus the source pin
matches both tags at inspection time; release packaging can still differ. No
binary version is inferred from the new tag: CMake still declares project 1.6.35. No
release archive, model payload or bundled provider library was inspected. The
catalog's original version/copyright fields were not changed.

## Backend disposition

| Component / platform / architecture / vendor / provider | Source status |
| --- | --- |
| denoiser / Linux / x86_64 / CPU / onnxruntime-cpu | implemented |
| denoiser / Linux / x86_64 / NVIDIA / onnxruntime-cuda | implemented conditional append; candidate, untested |
| denoiser / Linux / x86_64 / AMD / onnxruntime-rocm-legacy | experimental; legacy 1.17.3 append/artifact recipe, availability/ABI unresolved |
| denoiser / Linux / x86_64 / AMD / onnxruntime-migraphx | port-required; no MIGraphX enum/append/build integration |
| denoiser / Windows / x86_64 / NVIDIA, AMD, Intel / onnxruntime-directml | implemented; three distinct records |
| denoiser / macOS / arm64 / Apple / coreml | implemented conditional append; no hardware claim |
| denoiser / Windows / x86_64 / unknown / onnxruntime-qnn | experimental; generic append and external backend-path support, bundle/device unresolved |
| denoiser / Wine / x86_64 / unknown / onnxruntime-directml | unknown; native Windows is not Wine validation |
| GPU DSP / Linux / unknown / AMD / hip-dsp | port-required; incomplete kernels/spectral/batch pipeline |
| GPU DSP / Linux / unknown / NVIDIA / cuda-dsp | port-required; incomplete kernels/spectral/batch pipeline |

Every record is `integration_status: not-packaged`, `package_attribute: null`.
Architectures are explicit x64 ORT archive targets or arm64 within the configured
macOS universal route; GPU DSP architecture is unknown. The table is a set of
researched routes, not a claim that every CMake menu entry is usable. OpenCL,
Vulkan and oneAPI menu labels are not promoted to working DSP providers.

CPU fallback is implemented in provider ordering when enabled; this is not proof
of CPU fallback execution or GPU node placement. Default upstream auto selection
is GPU-preferring: a future package must make CPU default explicitly. Upstream
1.17.3 ROCm is not MIGraphX; per the binding design, moving beyond legacy ORT
requires compatibility/maintenance review, not a metadata rename.

## Runtime/model pins and next action

ORT requested version is source-known; fetched runtime hashes, CUDA/cuDNN/ROCm
versions and exact provider ABI closure are unresolved. QNN backend artifacts are
not supplied by merely selecting QNN. CoreML depends on the system framework and
provider header/build. No runtime or driver changes were made.

Bundled model references use pinned source URLs and tree-reported exact sizes.
SHA-256 remains null because no model was acquired; separate model terms/provenance
are unresolved. Provider-specific CUDA/ROCm/CoreML model filenames are search
candidates, not evidenced bundled artifacts. No automatic model acquisition is
authorized by this report. Missing license metadata does not block technical work.

Establish a model-pinned Linux CPU baseline with GPU auto-detection disabled, then
pin and inspect the optional CUDA runtime tuple. Review legacy ROCm separately;
MIGraphX needs a real port. Complete/audit DSP kernels and wiring before exposing
HIP/CUDA DSP. Measure callback scheduling and real provider node execution only
in a separately authorized validation campaign.

## Validation

Evaluation, build and load: **not-run** for every backend. Model execution,
provider execution and host: **not-run** for non-AMD records, **not-run-policy**
for all AMD records because AMD hardware execution is deliberately outside this
campaign. No upstream claim or workflow is treated as campaign success. No model
download, build, upstream execution, installation or hardware test was performed.
