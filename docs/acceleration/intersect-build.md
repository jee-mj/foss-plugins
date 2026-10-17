# INTERSECT source-package pilot — 2026-10-17

## Result and registration boundary

**CPU source VST3: built and headless-load checked. CUDA 12 and experimental
MIGraphX: derivations evaluated and official archives audited; complete GPU
runtime/plugin builds and GPU-library loads were not run.** No model, audio host,
or hardware execution occurred. AMD model/provider/host execution is
`not-run-policy`, because this campaign excludes AMD hardware execution.

The parent owns public exports and catalog registration. This pilot supplies
`pkgs/intersect/default.nix`, with `provider = "cpu"` by default and overrides
`"cuda12"` / `"migraphx"`. There is no new public flake attribute in this change.
`passthru` exposes `sourceRevision`, `provider`, `ortRuntime`, `ortHeaders`, and
`runtimeId`; the runtime exposes archive hash/size and `ortRevision`.

| Route | Evaluation | Full package build | Load | Model/provider/host |
| --- | --- | --- | --- | --- |
| Linux x86_64 CPU | passed | passed | VST3 `dlopen`/factory symbol; ORT API/`CreateEnv` passed | not-run |
| Linux x86_64 CUDA 12 | passed | not-run: resource-deferred | not-run | not-run |
| Linux x86_64 MIGraphX | passed | not-run: resource-deferred | not-run | not-run-policy |
| CUDA 13 | not implemented in this recipe | not-run | not-run | not-run |

Archive-audit derivations are **not runnable runtime outputs**, nor proof that
GPU dependencies resolve. Their only claims are hash-verified acquisition,
successful extraction, runtime install-phase artifact selection and ELF inspection.
The optional recipes are candidates for parent review, not accepted accelerated
exports. No unavailable dependency was concealed with a stub or ABI symlink.

## Full pins and source/release reconciliation

Official GitHub API tag inspection confirmed that **v0.17.0 itself resolves to
`f89e556d074ee46d88717ddfe92a84d3df824879`**, dated 2026-10-07. This reconciles the
release caution in [AUDIO-065.md](AUDIO-065.md). The plugin is compiled from this
source, not from any release plugin binary.

Source: <https://github.com/tucktuckg00se/INTERSECT/tree/f89e556d074ee46d88717ddfe92a84d3df824879>.
Recursive `fetchFromGitHub` NAR hash:
`sha256-dNIjasfRn6Szv+7sfwd7GKL0pW4lQWUbj0wg4h9+bDg=`.
The initial fake-hash acquisition reported precisely this hash; rerunning with
the real hash succeeded. Source output:
`/nix/store/wk7qzy5nk4h3siaanxxj8kvpi2rwbipr-source`.

Pinned submodules, independently read from GitHub's tree API:

| Source | Commit |
| --- | --- |
| JUCE | `2cdfca8feb300fb424002ba2c2751569e5bacb64` |
| Bungee | `2745718c2751bd655d7c5ed4853955de492bb39f` |
| signalsmith-linear | `5668673560146a9cfe38c25315071e3fd68c8317` |
| signalsmith-stretch | `57b93f4e9206a089a45387eaa39bdc9f310d3308` |
| VelociLoops | `ce00fd46ebe7e0cbad3adbad448945bbd9cce172` |
| Bungee/cxxopts | `4bf61f08697b110d9e3991864650a405b3dd515d` |
| Bungee/eigen | `c29c800126982c561e8d0b9255dc65474cd98de3` |
| Bungee/pffft | `02fe7715a5bf8bfd914681c53429600f94e0f536` |

All runtime archives are from
<https://github.com/tucktuckg00se/intersect-ort-providers/releases/tag/ort-1.24.2>,
using `releases/download/ort-1.24.2/onnxruntime-linux-x64-<provider>.zip`.
ORT version is **1.24.2**, API **24**, upstream ORT revision
`058787ceead760166e3c50a0a4cba8a833a6f53f`. The CPU archive also supplies all
build headers, including CUDA and MIGraphX typed API declarations. Nixpkgs' own
newer ORT is never substituted.

| Provider | Bytes | SHA-256 (API and locally acquired bytes agree) |
| --- | ---: | --- |
| cpu | 8,093,658 | `935bcfe2a545ab5ce9ae528fd2a1d5076faf32decdae5ddbe815e45999fb47da` |
| cuda12 | 205,347,957 | `8c3bf32ec93d87085253a3ccf1ef96d93ea22c547802705b5b3addc7d3a2a988` |
| migraphx | 9,866,383 | `f03788631da52c9c0aeadd58b04056d512474fcee8a8c8e8da8479cdf26adae6` |

Archive hashes pin bytes even if upstream replaces release assets. Producing
workflow attestation remains unresolved: provider builder inspected at
`033694837dccf898bc8195de02953f71ab8b5490`, release tag at
`0378a91edd1f0b18d1dcf507d93804788ea0a9a8`; see AUDIO-065 for that distinction.

Locked nixpkgs: `fd1462031fdee08f65fd0b4c6b64e22239a77870`. No input update.
The CPU build used GCC 15.2.0 and glibc 2.42-67 from that input.

## Optional dependency inspection and bounded stopping point

CUDA archive ELF inspection found `libcublasLt.so.12`, `libcublas.so.12`,
`libcurand.so.10`, `libcufft.so.11`, `libcudart.so.12`, and `libcudnn.so.9`.
It also contained an unused TensorRT EP requiring `libnvinfer.so.10` and
`libnvonnxparser.so.10`. The runtime install phase removes that EP: INTERSECT's
actual entrypoint is typed `AppendExecutionProvider_CUDA`, not TensorRT.
An assertion against the unfiltered archive failed first, then the archive audit
using the corrected real install phase passed.

Locked CUDA dependency archive pins (official NVIDIA HTTPS redistribution URLs
are evaluated directly from the locked recipes; all hashes below are SHA-256):

| Package | Version | Compressed bytes (HEAD, not downloaded) | Hash |
| --- | --- | ---: | --- |
| cuda_cudart | 12.9.79 | 1,514,676 | `1f6ad42d4f530b24bfa35894ccf6b7209d2354f59101fd62ec4a6192a184ce99` |
| libcublas | 12.9.1.4 | 933,611,504 | `546addc4a9d82b8f23aa9ba9274b6bc0429a63008a31c759884ac24880796057` |
| libcufft | 11.4.1.4 | 470,942,192 | `b0e65af59b0c2f6c8ed9f5552a9b375890855b7926ae2c0404d15dcf2565bda4` |
| libcurand | 10.3.10.19 | 89,582,256 | `48281b4caadb1cf790d44ac76b23c77d06f474c0b1799814f314aafec9258ad6` |
| cudnn | 9.22.0.52 (CUDA 12) | 959,541,460 | `3c350637c820f586c292501124fda0d8ae1104f4ccdb688ad06aa929cf23f112` |
| cuda_nvrtc (cuDNN runtime dependency) | 12.9.86 | 114,231,976 | `82913658363892dbc0f2638b070476234476e06e084fed60db861cb7e161a6af` |

These six archives alone exceed 2.5 GB; the dry run additionally required 20
derivations and 83.2 MiB cached downloads / 261.4 MiB unpacked. The cached-size
line does **not** include unbuilt fixed-output NVIDIA downloads. Full CUDA build
was deferred at this preflight, not passed. CUDA/cuDNN require the consumer's
normal unfree opt-in. No global `cudaSupport` setting was changed.

The locked cuDNN recipe restricts CUDA compute capabilities to >=7.5. Evaluated
default capabilities were `7.5 8.0 8.6 8.9 9.0 10.0 10.3 12.0 12.1`; these are
dependency configuration, not verified device support or ORT kernel coverage.
The source also supports CUDA 13, but only CUDA 12 is selected here; the
180,190,313-byte CUDA 13 archive was not downloaded and no CUDA 13 override is
advertised.

MIGraphX archive ELF inspection confirmed actual dependencies
`libmigraphx_c.so.3` and `libamdhip64.so.7`, and the original RUNPATH
`/opt/rocm-7.2.2/lib:/opt/rocm-7.2.2/lib/migraphx/lib:/opt/rocm/lib:`.
The recipe uses locked ROCm CLR/MIGraphX **7.2.3**, with normal transitive
MIOpen/rocBLAS/etc dependencies. Locked MIGraphX source hash is
`sha256-raYsrMZASdEIxSstk14b38q9dt5EOq3rKidoFvobnxk=` (ROCm tag
`rocm-7.2.3`). Official source
<https://github.com/ROCm/AMDMIGraphX/blob/rocm-7.2.3/src/api/CMakeLists.txt>
sets the stable C API SONAME to **3.0**. This supports trying dependency
resolution, not assuming every required symbol or GPU is compatible.

The final narrowed MIGraphX dry run required 40 cached paths: **3.5 GiB download,
7.6 GiB unpacked**, plus the already-acquired small ORT archive. It was stopped before fetching that
closure. Auto-patching/build/load of this tuple is therefore **not-run**, not
passed. No ABI aliases or ignored missing MIGraphX dependencies are used.
Locked CLR targets were `gfx900 gfx906 gfx908 gfx90a gfx942 gfx950 gfx1010
gfx1030 gfx1100 gfx1101 gfx1102 gfx1103 gfx1150 gfx1151 gfx1200 gfx1201`.
This list does not validate the upstream ORT bundle on those devices.

At preflight the host had 61 GiB RAM, 38 GiB available, and 1.7 TiB store space
available. This was a CPU-priority, bounded-download pilot sharing the host with
another build; resource deferral is not a claim that these dependencies are
missing or that building the optional variants is technically impossible.

## Offline adaptation and manual model selection

`offline.py` replaces both complete `downloadFileToTarget` helper bodies with
failure returns, including model/runtime manifest downloads. Local manifests
remain readable. CMake gets the pinned header root and
`FETCHCONTENT_FULLY_DISCONNECTED=ON`. No configure-time model acquisition is
present in the pinned upstream build. The source VST3 uses the selected runtime's
absolute store path privately; it neither reads mutable active-runtime selection
for inference nor changes DAW-wide `LD_LIBRARY_PATH`. CPU selection keeps the
upstream default session (no EP appended); GPU variants preserve the actual typed
CUDA/MIGraphX provider APIs and upstream CPU-choice behavior.

No model is supplied or fetched by this package or its tests. Sampler operation
does not require a model. To use stem separation later, the consumer must
independently obtain an authorized compatible model and manually choose
**SET → Stem Separation → Model Folder** containing
`bs_roformer_sw_6stem.onnx`, then select the desired Compute setting. Default
model folder is `~/.local/share/INTERSECT/models`. The built-in Download Models
and runtime download menus are inherited UI but downloads are disabled; a model
download failure may retain upstream's generic network-error text. Runtime menu
activation does not change this package's fixed runtime.

Reference-only model: `bs-roformer-sw-6stem`, 739,269,627 bytes, SHA-256
`718c3304a4a051bc8b1adfa776ce0aeab54165e207d0a5f5890d683c16188e5e`;
exporter manifest revision `d3edeb0fb0e48df544ce5ceb53e4478bba065e55`, release
`v0.1.0`. Weight terms/source revision remain unresolved as documented in
AUDIO-065. No acquired model/hash subject is claimed. Windows, Wine, macOS and
aarch64 packaging are outside this x86_64 Linux recipe.

## Reproducible commands and observations

Run from the Git root. Legitimate new pilot sources must be Git-visible. The
checkout is fetched through explicit Git transport; package directories are
narrow. No raw whole-checkout path import is used. This common expression permits
checks without editing shared exports:

```sh
pilot='let
  f = builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins";
  p = import f.inputs.nixpkgs { system = "x86_64-linux"; };
  base = p.callPackage (f.outPath + "/pkgs/intersect") {
    juceRuntime = p.callPackage (f.outPath + "/lib/juce-runtime.nix") {};
    pluginArtifacts = p.callPackage (f.outPath + "/lib/plugin-artifacts.nix") {};
  };
in '
nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 1 --cores 4 \
  --expr "${pilot} p.callPackage (f.outPath + \"/tests/intersect.nix\") { intersect=base; }" -L
nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 1 --cores 4 \
  --expr "${pilot} p.callPackage (f.outPath + \"/tests/intersect-provider.nix\") { intersect=base; }" -L
for provider in cuda12 migraphx; do
  nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 1 --cores 4 \
    --expr "${pilot} p.callPackage (f.outPath + \"/tests/intersect-provider.nix\") { intersect=base.override { provider=\"${provider}\"; }; archiveAudit=true; }" -L
done
```

Optional full derivation evaluation/dry runs use the same expression with
`config.allowUnfree = true` in its nixpkgs import (a process-local inspection,
not a workstation configuration change):

```sh
nix eval --impure --raw --expr "${pilot} (base.override { provider=\"migraphx\"; }).drvPath"
nix build --dry-run --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  --expr "${pilot} (base.override { provider=\"migraphx\"; }).ortRuntime"
```

Repeat the two expressions with `cuda12` for the NVIDIA candidate and the noted
unfree inspection import. Actual preflights called the narrow `runtime.nix`
directly; these select the same runtime derivations. CPU laziness was also
evaluated with `cudaPackages=throw "CPU forced CUDA"` and
`rocmPackages=throw "CPU forced ROCm"` supplied to `runtime.nix`: CPU `drvPath`
resolved successfully. The artifact test inspects the **actual output closure**
for GPU package leakage.

Before package implementation the artifact test was evaluated with
`p.callPackage /home/kalki/agent-work/foss-plugins/pkgs/intersect {}` and failed
specifically because that package path did not exist. Final builds passed;
upstream conversion/deprecation/unused-parameter and `JUCE_USE_CURL` redefinition
warnings were emitted, with no compilation errors. One CPU package was built at
a time, capped at four cores/one Nix job. The initial build used an unstable
display version; after GitHub proved the tag identity, it was rebuilt as 0.17.0.

### Exact final subjects

All entries share source revision `f89e556d074ee46d88717ddfe92a84d3df824879`.
Environment: `{os: "linux", architecture: "x86_64", execution_context:
"nix-build-sandbox", gpu_vendor: null, gpu_model: null, driver: null}`.
`package_attribute` is null until parent registration; `model_id` and
`model_sha256` are null throughout this pilot.

- CPU runtime ID: `intersect-ort-1.24.2-linux-x64-cpu`.
- CPU plugin derivation: `/nix/store/ajwhslqc4nngawklkd2jypdkshm0qr30-intersect-0.17.0.drv`.
- CPU plugin output: `/nix/store/0x7y0lmyq97yl5cqhzjydk6364n29arf-intersect-0.17.0`.
- Built VST3: `lib/vst3/INTERSECT.vst3/Contents/x86_64-linux/INTERSECT.so`;
  SHA-256 `f2cbc995fe443852fe9f249b31ac60dfa11658c9720dcf31175cfd89d7f9e9a0`.
- CPU plugin NAR hash: `sha256-IInvfe25m3vixgazatr2HLBM8K9+Qv1RnSgiWrFCehQ=`.
  Actual closure: 51 paths, 126,078,440 NAR bytes; no GPU runtime packages.
- CPU runtime: `/nix/store/a0y00n9fwqz631lzalbzy0m7kz6amlwa-intersect-ort-cpu-1.24.2`.
- Artifact check: `/nix/store/m6d2x3cc9s5mgaqz7f2pz2bkd8saaccy-intersect-artifacts`.
- ORT API/load check: `/nix/store/bdgkxzpvx8blyfcnzrg8spld7f5c13i9-intersect-provider-api`.
  Output: `ORT 1.24.2 API 24 + CreateEnv passed (no model/session/GPU)`.
- CUDA archive audit: `/nix/store/42vlavbshmn26blq034qc06k06pnxyhk-intersect-cuda12-archive-audit`.
- MIGraphX archive audit: `/nix/store/6vav7npp5gg8h9ir4r3ljc4dig02wfn7-intersect-migraphx-archive-audit`.

Evaluated-only subjects below are **not built output artifacts**:

- CUDA runtime ID: `intersect-ort-1.24.2-linux-x64-cuda12-cudart-12.9.79-cudnn-9.22.0.52`.
  Plugin attempt `/nix/store/lv60r492c8zknb4vsiailjmf0mliafp6-intersect-cuda12-0.17.0.drv`;
  runtime attempt `/nix/store/nalvlm3m3fnym9jj4jw4qa0xvyrrml6v-intersect-ort-cuda12-1.24.2.drv`.
- MIGraphX runtime ID: `intersect-ort-1.24.2-linux-x64-migraphx-rocm-7.2.3-migraphx-7.2.3`.
  Plugin attempt `/nix/store/2h99b20fmm3lvf08v5kx1r85sd685qsz-intersect-migraphx-0.17.0.drv`;
  runtime attempt `/nix/store/gkvvi36pbw0ijkj6yjhlk6qgl3dr5994-intersect-ort-migraphx-1.24.2.drv`.

Parent follow-up: review the CPU recipe/checks for registration, decide whether
to fund the multi-GB optional closure builds, then perform non-hardware
dependency/load checks before making any GPU packaging acceptance claim. Actual
model/provider/host validation remains a distinct authorization and evidence step.

## Parent integration evidence addendum — 2026-10-17

The parent requested an evidence-only update of the transient AUDIO-065 report
for its CPU-only `intersect` export. This supersedes the historical handoff's
null CPU `package_attribute`: the existing CPU derivation/output is now bound to
the parent's integration name **`intersect`**. The original pilot evaluated the
recipe directly before public export registration; this addendum does not claim
a new public-attribute build or new test execution. Optional CUDA 12/MIGraphX
overrides remain prototypes with **null package attributes** and
`integration_status: not-packaged`.

Exactly three Linux x86_64 backend records were updated in the temporary report:
CPU, NVIDIA CUDA and experimental AMD MIGraphX. Nine other backend tuples and
all model references retain their original content. All model acquisitions remain
`not-requested`. No new build, download, library load, model, provider, hardware
or audio-host execution was performed for this metadata update.

Every added backend-local verification record references this document and has
revision/source revision `f89e556d074ee46d88717ddfe92a84d3df824879`,
`attempt: null`, `model_id: null`, and `model_sha256: null`. The shared schema
environment is:

```json
{"os":"linux","architecture":"x86_64","execution_context":"native-linux","gpu_vendor":null,"gpu_model":null,"driver":null}
```

`native-linux` describes the native processes used by the original Nix sandbox
checks; no GPU identity or driver was observed or inferred. The earlier sandbox
description is retained as historical execution detail, not a separate platform.

The **six** added verification subjects bind these exact artifacts:

| Backend / package attribute | Stage | Artifact |
| --- | --- | --- |
| CPU / `intersect` | evaluation | `/nix/store/ajwhslqc4nngawklkd2jypdkshm0qr30-intersect-0.17.0.drv` |
| CPU / `intersect` | build | `/nix/store/0x7y0lmyq97yl5cqhzjydk6364n29arf-intersect-0.17.0` |
| CPU / `intersect` | load | `/nix/store/0x7y0lmyq97yl5cqhzjydk6364n29arf-intersect-0.17.0/lib/vst3/INTERSECT.vst3/Contents/x86_64-linux/INTERSECT.so` |
| CPU / `intersect` | load | `/nix/store/a0y00n9fwqz631lzalbzy0m7kz6amlwa-intersect-ort-cpu-1.24.2` |
| CUDA 12 / null | evaluation | `/nix/store/lv60r492c8zknb4vsiailjmf0mliafp6-intersect-cuda12-0.17.0.drv` |
| MIGraphX / null | evaluation | `/nix/store/2h99b20fmm3lvf08v5kx1r85sd685qsz-intersect-migraphx-0.17.0.drv` |

Their matching runtime IDs are:

- CPU: `intersect-ort-1.24.2-linux-x64-cpu`.
- CUDA 12: `intersect-ort-1.24.2-linux-x64-cuda12-cudart-12.9.79-cudnn-9.22.0.52`.
- MIGraphX: `intersect-ort-1.24.2-linux-x64-migraphx-rocm-7.2.3-migraphx-7.2.3`.

CPU validation is evaluation/build/load **passed**, with model/provider/host
**not-run**. The two load records distinguish VST3 `dlopen`/factory-symbol lookup
from ORT `dlopen`/API 24/`CreateEnv`; neither is model or provider execution.
GPU validation is evaluation **passed**, build/load **not-run**. AMD's three
hardware stages remain **not-run-policy**. The **7.2.3 local dependency candidate**
is explicitly separate from the upstream bundle's reported **7.2.2 build
environment**; cross-tuple symbol/ABI compatibility remains unverified.

The GPU evaluation summaries cite the exact archive-audit outputs already listed
above as artifact-selection/ELF observations only. They do not turn unpatched
archive contents into accepted provider builds, successful loads or execution.

Metadata verification (from the Git root, Python bytecode writes disabled):

```sh
python3 -B -c 'import json; from pathlib import Path; from lib.catalog_acceleration import validation_errors; report=json.loads(Path("/tmp/opencode/foss-plugins-acceleration/2026-10-17-full-set/AUDIO-065.json").read_text()); errors=validation_errors(report, require_assessed=True); print(errors); assert not errors'
git diff --check -- docs/acceleration/intersect-build.md
```

Result: validator returned `[]` and exited zero; scoped whitespace check exited
zero. Additional metadata assertions confirmed 12 total backends, exactly three
with the new verification records, six full subjects with the shared environment
and null model/attempt fields, CPU-only package registration, GPU build/load
`not-run`, all AMD hardware policy skips and all model acquisitions preserved.

## Linked optional-variant retry — supersedes size-only deferral

At the parent's explicit request, both optional variants were actually built and
checked after the earlier resource-only stopping point. **CUDA 12 and experimental
MIGraphX now have successful source-plugin builds, complete runtime fixups,
VST3 headless loads and core ORT API/CreateEnv loads.** Earlier evaluated-only
tables and deferral statements above describe the initial attempt; this section
and the updated transient report are the current results. No source recipe,
dependency selection, input pin or test implementation needed changing.

The parent still owns export acceptance: both optional `package_attribute` values
remain null, `integration_status` remains `not-packaged`, and no public GPU alias
is asserted. CPU registration/evidence and the other nine backend tuples were
not changed during this retry. AMD stays experimental and all AMD
model/provider/host stages stay `not-run-policy`.

### No-model source boundary before dependency realization

`nix derivation show --recursive` over the two pinned runtime derivations
inspected **2,732 derivations / 1,011 fixed-output fetch definitions** before
dependency downloads. The graph includes ONNX 1.21.0 C++/Python build inputs of
MIGraphX, AMDMIGraphX, rocMLIR and MIOpen sources. Metadata-only GitHub tree API
queries found **7,743 ONNX model/protobuf fixture blobs** and **1,145 MIGraphX
model/protobuf fixture blobs**. Example paths included ONNX backend model test
data and MIGraphX's example MNIST models. Only filenames/tree metadata were read;
none of those model blobs or model-bearing source archives were downloaded.

The direct CLR/MIGraphX outputs were therefore required through a **cache-only
`--max-jobs 0` gate**, which succeeded from cache.nixos.org: 40 paths, 3.5 GiB
download / 7.6 GiB unpacked. Those are binary runtime/compiler libraries and
MIOpen kernel-tuning databases, not downloaded NN model weights. The direct CUDA
library gate also succeeded at `--max-jobs 0`; the requested outputs were already
realized when checked. No source fallback was attempted for either gate.

After all builds, these protected source outputs were still absent:

- MIGraphX: `/nix/store/mkjpi4gvgpkimw6qyiv2lpqsw1m1ajh9-source`.
- ONNX: `/nix/store/45g4jriv1x7748044fdzdl9m7yhzqdcp-source`.
- rocMLIR: `/nix/store/ddaw1i87i3k7n28nx36rsajykrgn3fjc-source`.

An audit of the combined **131-path realized plugin/runtime closure** found no
files with `.onnx`, `.pth`, `.pt`, `.ckpt` or `.safetensors` extensions. This
filename audit supplements the cache/source graph boundary; it is not a claim
that arbitrary files can be classified as model-free solely by their names.
The previously hash-verified provider archives were reused, and INTERSECT's
configure/runtime download disabling remains in force.

### Exact cache-gate and build commands

All commands use the locked input through explicit Git transport. The CUDA EULA
opt-in is process-local `NIXPKGS_ALLOW_UNFREE=1 --impure`; no global setting was
changed. No remote source framework build is an allowed fallback if these gates
fail on another machine.

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 0 --cores 4 \
  --expr 'let f=builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins"; p=import f.inputs.nixpkgs { system="x86_64-linux"; }; in [ p.rocmPackages.clr p.rocmPackages.migraphx ]' -L
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 0 --cores 4 \
  --expr 'let f=builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins"; p=import f.inputs.nixpkgs { system="x86_64-linux"; }; in map p.lib.getLib (with p.cudaPackages; [ cuda_cudart libcublas libcufft libcurand cudnn ])' -L
```

The following expressions reproduce the four successful build/check invocations;
the actual order was MIGraphX runtime check, MIGraphX plugin/artifact check,
CUDA runtime check, then CUDA plugin/artifact check. Only one heavy source
package build ran at a time; each was capped at four cores and one Nix job.

```sh
linkedPilot='let
  f=builtins.getFlake "git+file:///home/kalki/agent-work/foss-plugins";
  p=import f.inputs.nixpkgs { system="x86_64-linux"; };
  base=p.callPackage (f.outPath + "/pkgs/intersect") {
    juceRuntime=p.callPackage (f.outPath + "/lib/juce-runtime.nix") {};
    pluginArtifacts=p.callPackage (f.outPath + "/lib/plugin-artifacts.nix") {};
  };
in '
for provider in migraphx cuda12; do
  NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 1 --cores 4 \
    --expr "${linkedPilot} p.callPackage (f.outPath + \"/tests/intersect-provider.nix\") { intersect=base.override { provider=\"${provider}\"; }; }" -L
  NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --print-out-paths --max-jobs 1 --cores 4 \
    --expr "${linkedPilot} p.callPackage (f.outPath + \"/tests/intersect.nix\") { intersect=base.override { provider=\"${provider}\"; }; }" -L
done
```

The exact successful cache-gate output identities were:

| Dependency | Realized output |
| --- | --- |
| CLR 7.2.3 | `/nix/store/l7s2kwhd29ghx0phjwr2lcaclkqd0hk3-clr-7.2.3` |
| MIGraphX 7.2.3 | `/nix/store/3hb7kc9yv21frdi1va44kk9nys5wkpwz-migraphx-7.2.3` |
| cudart 12.9.79 | `/nix/store/fawrv59x4f476r01r94c00n9zbya5yxg-cuda12.9-cuda_cudart-12.9.79` |
| cuBLAS 12.9.1.4 | `/nix/store/1f05yryvsczkvyqg1cdn6az9lgvwrj2s-cuda12.9-libcublas-12.9.1.4-lib` |
| cuFFT 11.4.1.4 | `/nix/store/z10apyg4zdp5gmihs2cwnlgxxrqmh0ji-cuda12.9-libcufft-11.4.1.4-lib` |
| cuRAND 10.3.10.19 | `/nix/store/pcq9n6p0igs1npp3k3v7mnb2mv7gh12v-cuda12.9-libcurand-10.3.10.19-lib` |
| cuDNN 9.22.0.52 | `/nix/store/jsg5mrba24q22zdqvvmmspragimgc0hs-cuda12.9-cudnn-9.22.0.52-lib` |

All source/archive hashes and the locked nixpkgs revision above remain unchanged.
No cuDNN components or consumed CUDA/ROCm libraries were removed to manufacture
a passing closure; the existing unused TensorRT exclusion is unchanged.

### Successful linked outputs and load scope

Both runtime fixups emitted the exact diagnostic:

```text
auto-patchelf: 0 dependencies could not be satisfied
```

CUDA resolved cuBLAS/cuBLASLt ABI 12, cuRAND ABI 10, cuFFT ABI 11, cudart ABI 12,
and cuDNN ABI 9. MIGraphX resolved `libmigraphx_c.so.3` and `libamdhip64.so.7` to
the cached 7.2.3 outputs. Both VST3 source variants linked successfully and their
headless artifact checks emitted `VST3 dlopen/GetPluginFactory passed; no bundled
model`. Both runtime checks emitted `ORT 1.24.2 API 24 + CreateEnv passed (no
model/session/GPU)`.

| Subject | CUDA 12 | MIGraphX |
| --- | --- | --- |
| Built plugin output | `/nix/store/r7g2gwzig0sfj0vfzc37p6m3xnigd3n0-intersect-cuda12-0.17.0` | `/nix/store/475qi54y50wy694lfadrm7bxmpip4i02-intersect-migraphx-0.17.0` |
| Built patched runtime | `/nix/store/szph3pabdhz2di85bif496hbmp5njxql-intersect-ort-cuda12-1.24.2` | `/nix/store/ccw9dwbwkrhfx3w62njqx28l70a3vfvg-intersect-ort-migraphx-1.24.2` |
| VST3 artifact/load check | `/nix/store/j1qjhzdy0hrspz3gz4hbqdk51xl0f4x5-intersect-artifacts` | `/nix/store/i7himknan6akz6fd6vckq1jh0zf8b9nc-intersect-artifacts` |
| Core ORT API/load check | `/nix/store/ci7m6g0n5bxbkxih1mg02993dfd6531m-intersect-provider-api` | `/nix/store/s7sm73qkmkmghifgm3w3w3r3nhs9v7dy-intersect-provider-api` |
| Plugin NAR SHA-256 | `sha256-tTKz3TXrY+tr9st6kDi8IvV1id7Vvn1lZXVzQsK7qVY=` | `sha256-H1VayaR4lheiSSQGLKEiYBU/XJ+BFltjygPPYvS25wc=` |
| Runtime NAR SHA-256 | `sha256-xFoBda0IthRQkOPaQd9ijYIfTZW6W4KN/8l0ba3T1sw=` | `sha256-VByBlbRY6quGclyZ6Ud9aB/6zOXv/8l93INcFHMbhJg=` |
| VST3 binary SHA-256 | `d3d570fa5a8650a2a9f549d3cffd836040ac128f19460545a06f392517a0f0ec` | `5923705b7c5f22897bff529da5cc290d009aa36b2cb6690b4a1b0035dfcdd0f0` |

The VST3 binary in each output is
`lib/vst3/INTERSECT.vst3/Contents/x86_64-linux/INTERSECT.so`.
The plugin intentionally dynamically loads its fixed runtime rather than
directly linking ORT into the VST3. Thus the results establish the complete
patched runtime closure plus the built source plugin and model-free core load;
they do not imply that the plugin exercised an accelerated provider.

### Provider dependency/relocation trace, not provider execution

The actual provider DSOs were additionally checked in the glibc loader's
**trace-and-exit mode**, with eager relocation warnings and the ORT shared
provider bridge explicitly supplied. This is the same kind of dependency tracing
used by `ldd -r`: library initializers and provider entrypoints are not invoked.
No CUDA/HIP device API was called. Commands, using the runtime paths in the table:

```sh
loader=/nix/store/34dkjp1wxxh6djsvxk8nhvzp0izasds0-glibc-2.42-67/lib/ld-linux-x86-64.so.2
runtime=/nix/store/ccw9dwbwkrhfx3w62njqx28l70a3vfvg-intersect-ort-migraphx-1.24.2
env LD_TRACE_LOADED_OBJECTS=1 LD_WARN=1 LD_BIND_NOW=1 "$loader" \
  --preload "$runtime/lib/libonnxruntime_providers_shared.so" \
  "$runtime/lib/libonnxruntime_providers_migraphx.so"
runtime=/nix/store/szph3pabdhz2di85bif496hbmp5njxql-intersect-ort-cuda12-1.24.2
env LD_TRACE_LOADED_OBJECTS=1 LD_WARN=1 LD_BIND_NOW=1 "$loader" \
  --preload "$runtime/lib/libonnxruntime_providers_shared.so" \
  "$runtime/lib/libonnxruntime_providers_cuda.so"
```

Both exited zero with resolved libraries and no missing-library/undefined-symbol
diagnostics. MIGraphX's upstream reported 7.2.2 build versus local 7.2.3 runtime
therefore passed **packaging and relocation resolution**; full provider
initialization, semantic ABI compatibility during graph execution and supported
GPU-node coverage remain unverified. These traces are not recorded as successful
provider initialization or GPU execution. Only the **core ORT library** received
actual `dlopen`/`CreateEnv`; VST3 loading did not start separation.

Eight new backend-local verification subjects were added: runtime build, plugin
build, plugin load and core-runtime load for each optional tuple. They retain
the exact runtime IDs, source revision and `native-linux`/null-GPU/null-model
environment above, with null package attributes and attempts. Together with the
earlier six subjects the report now has fourteen. Evaluation/build/load are
passed for both optional tuples; NVIDIA model/provider/host remain not-run and
AMD's three hardware stages remain not-run-policy. No failed build or ABI route
was hidden: both original pinned recipes passed without a corrective patch.

Final verification reran all four optional variant checks together with the same
Git-filtered expression: all four outputs above resolved successfully, with no
rebuild or download required. `validation_errors(report, require_assessed=True)`
returned `[]`; assertions verified fourteen full subjects, the exact three
passed non-hardware stages for both optional tuples, null GPU package attributes,
unchanged model acquisitions and AMD hardware skips. Scoped `git diff --check`
passed. The final combined 131-path model-filename audit additionally included
`.pb`, `.tflite` and `.h5` alongside the five weight/model extensions listed
above: **zero matches**. Protected model-bearing source outputs were rechecked
and remained absent.

## Public conditional aliases — final registration state

Independent review accepted the two optional variants for **experimental,
source-build/core-load-only packaging**. The parent registered the same CPU
override derivations as conditional aliases:

| Backend | Public package attribute | Package-set member | Integration |
| --- | --- | --- | --- |
| CPU default | `intersect` | `freePackages.intersect` | packaged |
| NVIDIA CUDA 12 | `intersect-cuda12` | `unfreePackages.intersect-cuda12` | packaged |
| AMD MIGraphX | `intersect-migraphx` | `unfreePackages.intersect-migraphx` | packaged, experimental |

This final registration supersedes earlier null-GPU-attribute / not-packaged
handoff statements in this historical report. MIGraphX's placement behind the
existing `NIXPKGS_ALLOW_UNFREE=1` conditional gate is an **experimental-support
opt-in**, not a new determination that MIGraphX is unfree. CUDA's existing vendor
runtime terms remain separate. No package-source or license metadata was changed
for this registration update.

Alias identity was checked directly, without new builds or loads:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --no-write-lock-file --raw .#intersect-cuda12.drvPath
# /nix/store/lv60r492c8zknb4vsiailjmf0mliafp6-intersect-cuda12-0.17.0.drv
NIXPKGS_ALLOW_UNFREE=1 nix eval --impure --no-write-lock-file --raw .#intersect-migraphx.drvPath
# /nix/store/2h99b20fmm3lvf08v5kx1r85sd685qsz-intersect-migraphx-0.17.0.drv
```

Both match the recorded source-build subjects exactly. All **five existing
backend-local verification subjects per optional route** now name that route's
public alias, including evaluation, runtime/plugin builds and runtime/plugin
loads. Their artifacts, derivations, runtime IDs, source revision and model-free
environment are unchanged. CPU subjects still name `intersect`; the fourteen
full verification subjects and original upstream evidence are preserved. Each
optional backend also directly cites `pkgs/intersect/runtime.nix` as its packaged
runtime recipe, keeping upstream build-provenance gaps separate from fetched
runtime/archive pins.

### Public build commands and the acquisition boundary

**Choose one INTERSECT variant.** All variants have the same VST3/plugin identity;
they are runtime alternatives, not distinct instruments to install together.
CPU remains the default public package:

```sh
nix build --no-link --no-write-lock-file --max-jobs 1 --cores 4 .#intersect
```

For an optional variant, inspect the locked source graph as above and require its
cache-only dependency gate **before** building the alias. Stop on a failed gate;
do not fall back to framework source acquisition. The following commands chain
the gate and the public build so a failed gate cannot continue to the alias:

Run from this checkout's Git root. Derive an explicit Git-filtered URI (including
URI-encoding for spaces or other special path characters); pass it through the
environment rather than interpolating a checkout path into Nix code:

```sh
flake_uri=$(python3 -c 'import pathlib, subprocess; root = subprocess.check_output(["git", "rev-parse", "--show-toplevel"], text=True).rstrip("\n"); print("git+" + pathlib.Path(root).as_uri())') || exit 1
```

The public alias's `ortRuntime.buildInputs` supplies the exact pinned dependency
tuple. Its first entry is the C++ runtime; the tail is precisely the five CUDA
library outputs or the two ROCm outputs covered by the original dependency gate.
No package/helper is imported from a private checkout path.

```sh
# CUDA 12 alternative: explicit per-command conditional/EULA opt-in.
FOSS_PLUGINS_FLAKE="$flake_uri" NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 0 --cores 4 \
  --expr 'let f = builtins.getFlake (builtins.getEnv "FOSS_PLUGINS_FLAKE"); a = f.packages.x86_64-linux.intersect-cuda12; in builtins.tail a.ortRuntime.buildInputs' \
&& NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 "$flake_uri#packages.x86_64-linux.intersect-cuda12"

# MIGraphX alternative: explicit per-command experimental-support opt-in.
FOSS_PLUGINS_FLAKE="$flake_uri" NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 0 --cores 4 \
  --expr 'let f = builtins.getFlake (builtins.getEnv "FOSS_PLUGINS_FLAKE"); a = f.packages.x86_64-linux.intersect-migraphx; in builtins.tail a.ortRuntime.buildInputs' \
&& NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 "$flake_uri#packages.x86_64-linux.intersect-migraphx"
```

Public optional artifact/core-load checks use the same per-command gate, after
the corresponding successful dependency gate above:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  .#checks.x86_64-linux.intersect-cuda12 .#checks.x86_64-linux.intersect-cuda12-provider
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --no-write-lock-file --max-jobs 1 --cores 4 \
  .#checks.x86_64-linux.intersect-migraphx .#checks.x86_64-linux.intersect-migraphx-provider
```

These build/check commands are public usage instructions; only the two alias
`drvPath` evaluations were newly executed for this registration update. The
model-free acquisition evidence applies to the **documented, pinned cache-only
dependency procedure**, not arbitrary cold-source builds of the aliases. The
conditional opt-in by itself does not prevent a cold build from fetching a
model-bearing dependency source. No new model, runtime or hardware checks were
run during registration.

Source-build/load acceptance still means VST3 library loading, core ORT API 24 /
`CreateEnv`, and separate no-initializer DSO dependency/relocation traces. It does
**not** mean CUDA/MIGraphX provider initialization, session/model execution or
GPU-node placement. NVIDIA model/provider/host remain `not-run`; all three AMD
hardware stages remain `not-run-policy`. Models remain `not-requested`, and the
local ROCm/MIGraphX 7.2.3 tuple remains distinct from upstream reported 7.2.2
build provenance.

Final registration metadata validation returned `[]` from
`validation_errors(report, require_assessed=True)`. Assertions confirmed both
packaged alias mappings, all ten optional verification subjects rebound to their
matching aliases, fourteen full subjects retained, CPU still `intersect`, model
acquisitions unchanged and all hardware-stage restrictions preserved. Scoped
`git diff --check -- docs/acceleration/intersect-build.md` passed.
