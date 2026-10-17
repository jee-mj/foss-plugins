# AUDIO-065 — INTERSECT

Assessment: **complete; inference; background-job** (2026-10-17). This is source-backed assessment, not completed acceleration packaging or hardware acceptance.

## Frozen identities and release boundary
- Plugin source: [`f89e556d074ee46d88717ddfe92a84d3df824879`](https://github.com/tucktuckg00se/INTERSECT/commit/f89e556d074ee46d88717ddfe92a84d3df824879).
- Provider builder inspected at [`033694837dccf898bc8195de02953f71ab8b5490`](https://github.com/tucktuckg00se/intersect-ort-providers/commit/033694837dccf898bc8195de02953f71ab8b5490); release tag `ort-1.24.2` resolves to **different** commit `0378a91edd1f0b18d1dcf507d93804788ea0a9a8`.
- ORT `v1.24.2` resolves via official API to [`058787ceead760166e3c50a0a4cba8a833a6f53f`](https://github.com/microsoft/onnxruntime/commit/058787ceead760166e3c50a0a4cba8a833a6f53f).
- Model exporter/manifest inspected at [`d3edeb0fb0e48df544ce5ceb53e4478bba065e55`](https://github.com/tucktuckg00se/intersect-stem-models/commit/d3edeb0fb0e48df544ce5ceb53e4478bba065e55); model release `v0.1.0` resolves to `8095ac317787ad424ce5380b7d02f6d59cc50469`.

Current source is not automatically the catalog's v0.17.0 binary. Provider releases permit asset replacement (`--clobber`); capture API asset digests rather than treating tags as immutable build provenance. Neither builder HEAD nor tag alone proves which workflow revision produced particular bytes.

## Actual execution/build path
[CMakeLists.txt](https://github.com/tucktuckg00se/INTERSECT/blob/f89e556d074ee46d88717ddfe92a84d3df824879/CMakeLists.txt) sets `INTERSECT_ORT_VERSION=1.24.2`, obtains headers (or accepts a header root), and dynamically loads runtime bundles instead of linking/shipping ORT in the plugin. macOS Intel stem separation is explicitly disabled; this does not disable the sampler itself.

[StemSeparationJob.cpp](https://github.com/tucktuckg00se/INTERSECT/blob/f89e556d074ee46d88717ddfe92a84d3df824879/src/audio/StemSeparationJob.cpp): a `juce::Thread("StemSeparation")` starts at background priority. It loads the runtime using `LoadLibrary` or `dlopen(RTLD_NOW | RTLD_GLOBAL)`, obtains the requested ORT API, constructs a session, and runs overlapping waveform chunks with `Session::Run`. This is background sample processing, not callback inference. Sampler/time-stretch DSP is a separate non-neural component.

Provider selection is real code:
- CPU: returns without appending an EP; CPU tensors/default ORT session.
- CUDA: typed `AppendExecutionProvider_CUDA`, device 0.
- MIGraphX: typed `AppendExecutionProvider_MIGraphX`, device 0. **Not** a renamed legacy ROCm EP.
- DirectML: disables memory patterns, requests sequential execution and appends `DML`.
- CoreML: string-name provider appended through the generic path; active bundle catalog identifies `CoreML`.

Provider availability comes from the active bundle's metadata, not proof that nodes ran on GPU. On provider-configuration failure, lines 644–650 set a warning and attempt CPU operation; this does not prove recovery from session construction, model execution or OOM failure. Source fallback differs from prose in stem-separation docs that suggests manual restart only. Profile node placement before accepting acceleration.

## Provider/platform matrix
All records are **not-packaged**, with null package attributes/runtime IDs. CPU fallback is supported as a source path, not a campaign execution result.

| Platform / architecture | Route | Source assessment |
| --- | --- | --- |
| Linux x86_64 | CPU ORT 1.24.2 | Implemented |
| Linux aarch64 | CPU ORT 1.24.2 | Implemented; no upstream ARM GPU bundle |
| Linux x86_64 NVIDIA | ORT CUDA 12 and CUDA 13 bundles | Implemented API; distinct versions within one backend tuple |
| Linux x86_64 AMD | ORT MIGraphX 1.24.2 | Experimental; ROCm dependency ABI unresolved beyond recorded build/SONAME evidence |
| Windows x86_64 | CPU; DirectML for NVIDIA, AMD and Intel | Implemented; vendor-specific records, no hardware acceptance |
| Windows arm64 | CPU | Implemented; no DirectML ARM bundle in catalog |
| macOS arm64 | CPU/default session; CoreML | Implemented; Apple framework runtime provided by OS |
| macOS x86_64 | Stem inference disabled | No ORT 1.24 x64 route in inspected build |
| Wine x86_64 | Candidate Windows DirectML route | **Unknown**; separate from native Windows; multi-vendor route cannot earn GPU acceptance |

### Runtime provenance and gaps
[Provider workflow](https://github.com/tucktuckg00se/intersect-ort-providers/blob/033694837dccf898bc8195de02953f71ab8b5490/.github/workflows/build.yml) and [Linux repacker](https://github.com/tucktuckg00se/intersect-ort-providers/blob/033694837dccf898bc8195de02953f71ab8b5490/scripts/repack_linux.sh) repack Microsoft's CPU/CUDA ORT 1.24.2 tarballs. [Installation requirements](https://github.com/tucktuckg00se/INTERSECT/blob/f89e556d074ee46d88717ddfe92a84d3df824879/docs/installation.md) name `libcudart.so.12` or `.13`, plus `libcudnn.so.9`; CUDA/cuDNN patch versions are not pinned here. Driver is a consumer environment prerequisite, not a fetched pin. No driver inspection or change performed.

[MIGraphX build script](https://github.com/tucktuckg00se/intersect-ort-providers/blob/033694837dccf898bc8195de02953f71ab8b5490/scripts/build_linux_migraphx_in_container.sh) clones ORT `v1.24.2`, builds shared libraries with `--use_migraphx --skip_tests` and stages the MIGraphX provider. Current workflow pins `rocm/dev-ubuntu-22.04:7.2.2`; comment reports the published bundle links `libamdhip64.so.7` and `libmigraphx_c.so.3`. Actual MIGraphX/MIOpen/rocBLAS package patch versions and container digest are not fixed by its unversioned apt installs. **Release-tag workflow instead used container `latest`**; current comments retrospectively explain 7.2.2 provenance, not an immutable build attestation. A staging glob for legacy `providers_rocm` does not make ROCm EP an implemented separate route. Verify ABI and AMD GPU support before packaging; no AMD execution here.

[DirectML repacker](https://github.com/tucktuckg00se/intersect-ort-providers/blob/033694837dccf898bc8195de02953f71ab8b5490/scripts/repack_windows_directml.ps1) uses `Microsoft.ML.OnnxRuntime.DirectML/1.24.2`, but fetches **Microsoft.AI.DirectML without a version**. Its exact DLL version remains unresolved without artifact/provenance inspection. Native DirectX12 capability is not Wine DirectML/D3D compatibility. [macOS repacker](https://github.com/tucktuckg00se/intersect-ort-providers/blob/033694837dccf898bc8195de02953f71ab8b5490/scripts/repack_macos_arm64.sh) repackages official ORT arm64; CoreML OS version/accelerator placement requires later host evidence.

Official release metadata: <https://api.github.com/repos/tucktuckg00se/intersect-ort-providers/releases/tags/ort-1.24.2>. Selected asset SHA-256 values (API-reported, not downloaded/rehashed):

| Asset suffix | SHA-256 |
| --- | --- |
| linux-x64-cpu | `935bcfe2a545ab5ce9ae528fd2a1d5076faf32decdae5ddbe815e45999fb47da` |
| linux-arm64-cpu | `425ff2182cdf8de2ecd2f2de574d5a171a49350e933292a23c77a113f516b126` |
| linux-x64-cuda12 | `8c3bf32ec93d87085253a3ccf1ef96d93ea22c547802705b5b3addc7d3a2a988` |
| linux-x64-cuda13 | `dd585b05d71ca0c7cbb64c77acbbb228a52e3d43d706fb615055af53e85c9ae9` |
| linux-x64-migraphx | `f03788631da52c9c0aeadd58b04056d512474fcee8a8c8e8da8479cdf26adae6` |
| win-x64-cpu | `8b7571b42c48f3451cc2f13f31c4e0910209125a090fd6b5ba68e1204e375a61` |
| win-arm64-cpu | `1d11ae7b36e24cd65e7330d165503dac88b4deca3254ebf25dea99995d79c060` |
| win-x64-directml | `8d0fa5873b043905915f33c82033d32b4e1dd740d1379f34802be0c571e0434c` |
| macos-arm64 | `49d8766b9c752f3b727f21eff5e656928bf60005ff807efd6944a388b77b5366` |

## Model references only — no downloads
[StemSeparation.cpp](https://github.com/tucktuckg00se/INTERSECT/blob/f89e556d074ee46d88717ddfe92a84d3df824879/src/audio/StemSeparation.cpp) maps the sole current model `bs-roformer-sw-6stem` to the official [v0.1.0 ONNX asset](https://github.com/tucktuckg00se/intersect-stem-models/releases/download/v0.1.0/bs_roformer_sw_6stem.onnx). [Pinned exporter manifest](https://github.com/tucktuckg00se/intersect-stem-models/blob/d3edeb0fb0e48df544ce5ceb53e4478bba065e55/models/manifest.json) records 44.1 kHz stereo, chunk 131072, six outputs and overlap 0.5. The pinned plugin model entry sets `computeResidual=false` and `residualRole=unknown`; no additional instrumental residual is computed. API asset size **739,269,627 bytes**, SHA-256 `718c3304a4a051bc8b1adfa776ce0aeab54165e207d0a5f5890d683c16188e5e`, agrees with manifest. Hash/size are metadata, not acquired execution subjects.

Original sources recorded by exporter:
- Architecture/code: <https://github.com/openmirlab/bs-roformer-infer>.
- Configuration: <https://huggingface.co/jarredou/BS-ROFO-SW-Fixed/resolve/main/BS-Rofo-SW-Fixed.yaml>; manifest hash `f9fada9f94e5ba2d2e4600196299459294bc5f532b314c209cc156ac63e4329b`.
- Checkpoint: <https://huggingface.co/jarredou/BS-ROFO-SW-Fixed/resolve/main/BS-Rofo-SW-Fixed.ckpt>; manifest hash `24e7d35ee9c64415673d3fd33e06a67cac2c103c5df6267ba1576459c775916e`.

Hugging Face source revision is not pinned by these `main` URLs. Model metadata API returned HTTP 401 during this research; no credentials or model download attempted. [Exporter LICENSE](https://github.com/tucktuckg00se/intersect-stem-models/blob/d3edeb0fb0e48df544ce5ceb53e4478bba065e55/LICENSE) is MIT for repository software, **not independent proof of checkpoint/training-data/exported-weight terms**. Missing model-term evidence is informational and a provenance follow-up, not a technical gate.

The plugin's [model download job](https://github.com/tucktuckg00se/INTERSECT/blob/f89e556d074ee46d88717ddfe92a84d3df824879/src/audio/StemModelDownloadJob.cpp) accepts manifest override URLs and downloads on demand. [Runtime download job](https://github.com/tucktuckg00se/INTERSECT/blob/f89e556d074ee46d88717ddfe92a84d3df824879/src/audio/OrtBundleDownloadJob.cpp) fetches a mutable latest manifest and activates a bundle. Record/pin selected artifacts during future integration; do not execute these download paths during evaluation.

## Validation and next action
Evaluation/build/load/model/provider/host are all **not-run**. AMD model/provider/host are **not-run-policy**: AMD hardware execution is deliberately outside this campaign, including native Windows AMD DirectML. No upstream build/repack/test claim is promoted into local verification.

Next: reconcile plugin release/source, fixed runtime asset digests, ORT API/provider ABI, DirectML DLL version and model provenance; implement optional CPU-first/native variants only after the base package exists. Resolve CUDA and MIGraphX closures independently and keep Wine unknown until independent validation. Authorized later NVIDIA testing must establish actual graph-node placement and distinguish CPU fallback; background separation needs completion-time/VRAM/playback-impact measurement. No package exports, builds, archives, drivers or models were changed/acquired here.
