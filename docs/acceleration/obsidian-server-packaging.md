# AUDIO-090 Task 4 — OBSIDIAN server packaging feasibility

## Verdict: blocked for a working CPU-offline server

**A portable, working CPU-offline package cannot truthfully be claimed from
this server pin in the current campaign.** CPU generation is explicitly
unsupported; startup requires a supported GPU and, by default, loads SA3
resources. The model and dependency closures are not immutable or complete.
No package, runtime flag, dependency compatibility result or offline acceptance
result is supplied by this assessment.

A future source/dependency-only distribution is conceptually separable from
model acquisition and GPU execution. It would be an **unvalidated GPU-server
distribution**, not CPU inference support or an offline-ready service. If
“CPU-offline” means packaging/static checks on a CPU-only host for later CUDA
deployment, that limited objective remains possible in principle, but the
closure and startup changes below must be resolved first. Parent decides
whether to authorize that implementation scope.

## Evidence boundary and identity

- Assessment date: 2026-10-17.
- Server: `innermost47/obsidian-neural-gpu-server` at
  **`29ed0cdcb971ff5840243bcf43f988055b97396d`** throughout.
- Local context: [AUDIO-090.md](AUDIO-090.md) and
  `/tmp/opencode/foss-plugins-acceleration/2026-10-17-full-set/AUDIO-090.json`.
  The latter records GPU-server CPU fallback as `unsupported`, all packages
  absent, and validation as not-run; AMD hardware stages are policy-skipped.
- Official source was read through GitHub contents/tree APIs with that exact
  `ref`; no upstream installer or Python module was executed. No builds,
  installations, models, input updates, service activation or hardware probes
  were performed. This report is the only file written.
- This is separate from plugin-local ONNX CPU inference. Plugin `v350` resolves
  to `dcc21142fe62283e61f1ab096ec3a6e004dc813d` and declares 3.2.0 in the
  existing assessment; its CPU route does not establish a server CPU route.

## Concrete blockers

### 1. CPU-only operation is rejected, including model-free normal startup

`device_utils.get_device()` returns CUDA, MPS, or `None`.
`require_device()` raises when neither GPU backend is available.
`main.py` checks the device before `uvicorn.run` and exits with “CPU mode is not
allowed in the GPU Server.” Its lifespan also constructs `AudioGenerator`,
whose constructor calls `require_device()`. Launching the ASGI app through a
different entry point therefore does not provide a supported CPU escape hatch.
Moving models to CPU during cleanup or SA3 RAM caching is staging, not CPU
generation. `PYTORCH_ENABLE_MPS_FALLBACK=1` concerns MPS operators, not a server
CPU backend. [S1, S2, S4, S6]

### 2. Default startup can acquire models before serving requests

`settings.py` defaults `SA3_KEEP_IN_RAM` to `true`. During FastAPI lifespan,
`_load_models()` constructs all registries and calls
`get_pretrained_model(sa3.repo_id)` to preload SA3 into RAM. The call supplies
neither an immutable revision nor a local-only argument. With missing resources
it is a potential acquisition path, not a model-free readiness check. The exact
download behavior and nested resources depend on the unresolved
`stable-audio-tools` implementation. [S1, S3, S6]

`SA3_KEEP_IN_RAM=false` is a real source-supported setting that suppresses that
preload. It **does not** disable GPU requirements, remote loaders during
requests, or expose a local-model manifest interface. SAO1 and the seven
checkpoint/config engines are lazy-loaded; startup does not download all nine
engines through those constructors. The installer, by contrast, explicitly
pre-downloads all nine engine selections. [S1, S4–S7]

### 3. No upstream offline/local-model switch or complete resource closure

The CLI parses only `--host` and `--port` with `parse_known_args()`. An invented
`--offline`, `--cpu` or `--no-download` argument could be silently ignored;
it must not be advertised as functional. Defaults are already loopback
(`HOST=127.0.0.1`, `PORT=8000`). The example environment contains host, port,
HF token and MPS dtype; it is not an offline configuration. [S1, S3, S9]

Server loaders pass remote repository IDs, without `revision` or
`local_files_only`. No server-owned offline setting or local resource-path
selection is implemented in the inspected Python sources. Library-level
environment controls, including a possible `HF_HUB_OFFLINE` wrapper policy,
would need verification against the **selected pinned dependency versions**
and every nested loader. They are not established here as working server
flags, do not supply missing bytes, and do not prove all network paths are
blocked. A populated mutable cache is not a reproducible offline manifest.
[S1–S6]

### 4. Dependency requests do not define a reproducible environment

- `install.sh` requires Python **3.10** and requests Linux
  `torch==2.7.1`, `torchaudio==2.7.1`, `torchvision==0.22.1` from the
  **cu126** wheel index. That is an installer request, not a resolved closure
  or a verified host-driver/CUDA/cuDNN combination.
- `requirements.txt` pins only `numpy==1.26.4`. Lower bounds are:
  `fastapi>=0.110.0`, `uvicorn>=0.29.0`, `torch>=2.2.0`,
  `diffusers>=0.27.0`, `transformers>=4.40.0`, `accelerate>=0.29.0`,
  `bitsandbytes>=0.43.0`, `librosa>=0.10.0`, `soundfile>=0.12.0`,
  `httpx>=0.27.0`, `pydantic>=2.0.0`, `python-dotenv>=1.0.0`.
  `torchsde`, `websockets`, `huggingface_hub` have no versions.
- The installer separately installs **unversioned** `stable-audio-tools`,
  `einops`, `safetensors`, `pytorch_lightning`, and upgrades pip, packaging,
  setuptools and wheel without pins. Later resolver operations are not
  constrained by a complete lock preserving the initial torch tuple.
- No lock/constraints file or dependency hashes appears in the pinned root
  tree (which contains no subdirectories). Import/API compatibility for
  Diffusers quantization and stable-audio-tools SA3 functions is unproved by
  these lower bounds. `requirements.txt` alone omits directly imported code
  such as `stable_audio_tools` and `einops`.
- `FLASH_ATTN_WHL` is empty by default; README says standard attention is the
  fallback. Do not introduce flash-attn as a demonstrated mandatory dependency.
- Python ABI/platform wheel identities, full transitive constraints, native
  libraries and hashes, CPU/CUDA build selection, cuDNN and supported driver
  requirements remain unresolved. Installer checks `nvidia-smi` and warns
  about missing ffmpeg; shared WAV output uses SoundFile, requiring its native
  audio-library closure to be accounted for. [S7, S8, S10, S11]

This review did not inspect or evaluate the parent checkout's flake lock.
Neither current package-API availability nor an upstream source pin proves
that its **existing locked inputs** supply Python 3.10 or the necessary
versions/features. No input update or inference about locked availability is
made. Resolving an incompatible locked closure may itself require a parent
decision beyond this campaign.

## Per-engine third-party and resource dependencies

All rows share PyTorch and the `base_generator.py` output path
(einops, NumPy, SoundFile). All model revisions, full file sets, hashes, sizes
and nested resource identities remain unestablished. [S3–S8, S10]

| Engine | Pinned server behavior and external code | Resource boundary / unresolved dependency |
| --- | --- | --- |
| stable-audio-open-1.0 | Diffusers `StableAudioPipeline`, `StableAudioDiTModel`; Transformers `T5EncoderModel`; CUDA uses both libraries' bitsandbytes 8-bit configurations and `device_map="balanced"` (Accelerate integration). Loads on each request, unloads afterward. | `stabilityai/stable-audio-open-1.0`; separate `text_encoder` and `transformer` loads plus pipeline resources (including VAE/tokenizer/config/scheduler as required by the selected library/model snapshot). No revision/local-only arguments. |
| stable-audio-3-medium | stable-audio-tools `get_pretrained_model` and `generate_diffusion_cond_inpaint`; default startup RAM preload, then GPU transfer on request. | `stabilityai/stable-audio-3-medium`; installer fetches `model_config.json` and `model.safetensors`, which does **not** establish all nested conditioner/text-encoder/tokenizer resources consumed by the unresolved library/config. |
| foundation-1 | stable-audio-tools config factory, checkpoint loader, `generate_diffusion_cond`; Hugging Face Hub downloads on each request (cache may satisfy). | `RoyalCities/Foundation-1`: `Foundation_1.safetensors`, `model_config.json`; model factory may require further resources specified by the unacquired config. |
| audialab-edm-elements | Same checkpoint/config engine. | `innermost47/obsidian-neural-models`: `audialab-edm-elements.safetensors`, `audialab-edm-elements_model_config.json`; nested config dependencies unresolved. |
| rc-infinite-pianos | Same checkpoint/config engine. | Same repository: `rc-infinite-pianos.safetensors`, `rc-infinite-pianos_model_config.json`; nested dependencies unresolved. |
| rc-vocal-textures | Same checkpoint/config engine. | Same repository: `rc-vocal-textures.safetensors`, `rc-vocal-textures_model_config.json`; nested dependencies unresolved. |
| sao-instrumental | Same checkpoint/config engine. | Same repository: `sao-instrumental.safetensors`, `sao-instrumental_model_config.json`; nested dependencies unresolved. |
| stablebeat | Same checkpoint/config engine. | Same repository: `stablebeat.safetensors`, `stablebeat_model_config.json`; nested dependencies unresolved. |
| gluten-v1 | Same checkpoint/config engine. | Same repository: `gluten-v1.safetensors`, `gluten-v1_model_config.json`; nested dependencies unresolved. |

Do not assume all checkpoint engines share identical text models, terms or
memory requirements: their configs were not acquired. README requires HF
account/token and acceptance of the two Stability repositories' licenses;
the other repositories and nested resources need independent provenance/terms
review. Its approximate “SA3 alone ~9 GB” is an upstream estimate, not measured
artifact size or RAM/VRAM budget. Default SA3 preload is unsuitable as a bounded
CPU packaging smoke check. A single generation lock serializes GPU work but
does not cap dependency/model memory or disk use. [S1, S11]

## Actionable path for the parent

1. **Choose the deliverable.** Retain Task 4 as blocked if it requires working
   CPU inference or validated offline CUDA service now. CPU inference would be
   new port work. A deferred, code-only CUDA distribution must explicitly keep
   build/load/offline/provider/model validation unclaimed until performed.
2. **Resolve the code closure without changing inputs implicitly.** Review the
   existing locked package set separately; select exact Python, PyTorch CUDA
   build, Diffusers/Transformers/Accelerate/bitsandbytes and stable-audio-tools
   versions/source hashes, then all transitive/native dependencies. Audit
   stable-audio-tools loader/factory code at that selected pin. If unavailable
   under current inputs/budget, report that incompatibility before implementation.
3. **Separate packaging from acquisition.** Do not run `install.sh` as a build
   or launch step. It combines dependency installation, device execution and
   model downloads. A future package must contain pinned code/dependencies,
   use an explicit launcher, retain loopback default, and have no autostart,
   install-time cache population or request-triggered implicit acquisition.
4. **Design explicit offline resource selection before claiming offline.**
   Model-free checks need a separately implemented non-serving validation path
   that avoids device checks and pretrained loads; that path does not exist at
   this pin. Serving needs local immutable resources, fail-fast checks for
   missing files, and verified network-denial semantics through every nested
   loader. Disabling SA3 RAM preload alone is insufficient. This is future
   implementation work, not a proposed flag accepted by current upstream.
5. **Keep resource acquisition deferred.** Once separately authorized, enumerate
   each selected engine's full recursive resource graph, revisions, hashes,
   sizes, terms and cache layout, including conditioners/tokenizers. Prefer a
   bounded selected-engine scope over automatically acquiring all nine. Current
   no-model-download policy prevents establishing or validating that closure.
6. **Stage acceptance honestly.** Later authorization may allow bounded static,
   packaging and model-free checks first; only separately authorized offline
   resources and NVIDIA hardware can establish actual offline CUDA generation.
   No such acceptance is possible in this read-only review.

**AMD remains `port-required`, `not-packaged`, with hardware execution
policy-skipped.** NVIDIA wheel installation and bitsandbytes CUDA quantization
are not a ROCm implementation. A future port must select its own framework,
quantization/kernel tuple and inspect provider build/HIP identity; CPU staging
and `torch.cuda` naming do not establish AMD support. Existing catalog/temp
assessment statuses are not changed by this report.

## Immutable source references

All GitHub blob links below use server commit
`29ed0cdcb971ff5840243bcf43f988055b97396d`.

- [S1 — main.py: CLI, imports, lifespan preload, GPU gate, serving](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/main.py)
- [S2 — device_utils.py: device requirement, dtype, staging, MPS patch](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/device_utils.py)
- [S3 — settings.py: defaults and all model mappings](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/settings.py)
- [S4 — audio_generator.py: SAO1 loaders and quantization](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/audio_generator.py)
- [S5 — sa_generator.py: checkpoint/config loaders and factory](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/sa_generator.py)
- [S6 — sa3_generator.py: pretrained loader, cache and inference](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/sa3_generator.py)
- [S7 — install.sh: Python/CUDA requests, extras, device checks and downloads](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/install.sh)
- [S8 — requirements.txt: incomplete version constraints](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/requirements.txt)
- [S9 — .env.example.txt: documented environment](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/.env.example.txt)
- [S10 — base_generator.py: tensor/audio output dependencies](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/base_generator.py)
- [S11 — README.md: supported platforms, license/access and resource statements](https://github.com/innermost47/obsidian-neural-gpu-server/blob/29ed0cdcb971ff5840243bcf43f988055b97396d/README.md)
- [Pinned tree API: file inventory, no lock file](https://api.github.com/repos/innermost47/obsidian-neural-gpu-server/git/trees/29ed0cdcb971ff5840243bcf43f988055b97396d)

Cross-check blob identities returned by that tree include
`main.py=487d5bbbe65e841b54c2c619e41584178991cbca`,
`requirements.txt=67eae0174ddc34651e883064758315a365baa693`,
`settings.py=76de55eb242fb26b5f60a8fc86642ceea8ec0a9e`, and
`install.sh=2f1ff9d1093d7e3a95aaec15f17e9d33ae490522`.
