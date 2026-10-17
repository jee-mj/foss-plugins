# Full-catalog inference and acceleration design

Status: approved direction; implementation planning, not implemented GPU support.
Date: 2026-10-17.

## Outcome and boundaries

Assess the entire captured set of **104 repository identities** in one coordinated
campaign. Identify AI/NN functionality, actual runtime backends and useful native
or Windows routes; implement evidence-supported optional acceleration without
turning all catalog entries into GPU dependencies. Repositories containing suites
need product/component-level assessments beneath their existing stable AUDIO ID.
The original ten additional Basilica acquisition records remain supplemental;
they do not change the 104-entry denominator or receive invented AUDIO IDs.

This campaign covers all entries, not just the seven previously researched leads.
An assessment may conclude no inference, CPU-only implementation, training-only
GPU use, insufficient evidence, a porting requirement, or implemented acceleration.
Completion of assessment is not completion of packaging or compatibility testing.

### Global requirements

- Native package definitions and public catalog metadata belong in `foss-plugins`.
- `.site` owns workstation selection and Wine integration, not duplicate native recipes.
- Preserve exactly 104 stable AUDIO ID-to-repository mappings and the three BA aliases.
- CPU use remains the default where upstream supplies a viable CPU route.
- GPU support is optional, per component, platform, architecture and provider.
- NVIDIA and AMD are both in scope; neither vendor is inferred from an AI label.
- AMD hardware execution is deliberately not performed in this campaign.
- Record AMD hardware validation as `not-run-policy`, never `passed` or `failed`.
- Windows/Wine acceleration is separate from native Windows and native Linux acceleration.
- Missing/unclear license metadata is informational, not a technical implementation gate.
- Record explicit restrictions, model/sample/firmware terms and consumer judgement separately.
- No commits, input updates, model downloads, system activation or driver changes without explicit authorization.
- Never import either entire checkout as an unfiltered raw path Nix source.
- At most 10 concurrent child agents; no recursive delegation.

## Catalog contract

Keep `catalog/audio-104.json` the published machine-readable authority. Upgrade
`schema_version` from 1 to 2 additively; retain all existing fields and identity
fixtures. Add `acceleration` to every entry, even entries without neural DSP.
Existing package `verification` fields are not overwritten by backend evidence.

```json
{
  "assessment": "pending",
  "ai_role": "unknown",
  "execution_mode": "unknown",
  "components": [],
  "backends": [],
  "evidence": [],
  "blocked_reason": null,
  "next_action": "Inspect pinned upstream inference and build paths."
}
```

Allowed `assessment`: `pending`, `complete`, `blocked-evidence`.
Allowed `ai_role`: `none`, `inference`, `training-only`, `external-service`,
`mixed`, `unknown`. AI-assisted authorship is not an inference role.
Allowed `execution_mode`: `audio-callback`, `worker-thread`, `background-job`,
`external-service`, `mixed`, `not-applicable`, `unknown`.

`components` is an array of `{id, summary, kind}` objects. IDs are stable local names
such as `stem-separation`, `denoiser`, `hip-spectral-dsp`, or `gpu-server`;
use a separate component for each suite product with different requirements.
Each backend refers to one of these component IDs. A non-neural GPU DSP component
can be cataloged but must not be misrepresented as NN inference.
Allowed component `kind`: `neural-inference`, `non-neural-dsp`, `training`,
`external-inference`, `application`. `id` and `summary` are nonempty strings.

`blocked_reason` is null unless `assessment: blocked-evidence`, which requires
a nonempty reason and `next_action`. A completed `none` role permits only DSP
or application components; `training-only` requires training components and no
inference components; `inference` requires a neural-inference component;
`external-service` requires an external-inference component. `mixed` requires
at least two of training, local inference and external inference. `unknown`
remains valid with `blocked-evidence`, but not a completed conclusion. Completed
non-neural assessments use `execution_mode: not-applicable` unless explicitly
documenting a non-neural GPU DSP execution mode.

### Backend record

```json
{
  "component": "stem-separation",
  "platform": "linux",
  "architecture": "x86_64",
  "vendor": "amd",
  "provider": "onnxruntime-migraphx",
  "upstream_status": "experimental",
  "integration_status": "not-packaged",
  "runtime_pins": [],
  "model_refs": [],
  "cpu_fallback": "unknown",
  "package_attribute": null,
  "source_revision": null,
  "runtime_id": null,
  "validation": {
    "evaluation": "not-run",
    "build": "not-run",
    "load": "not-run",
    "model_execution": "not-run-policy",
    "provider_execution": "not-run-policy",
    "host": "not-run-policy",
    "reason": "AMD hardware execution is deliberately outside this campaign."
  },
  "evidence": [],
  "next_action": "Verify pinned upstream MIGraphX bundle and runtime ABI."
}
```

This is a structural example, not a newly verified INTERSECT package.
Allowed `platform`: `linux`, `windows`, `macos`, `wine`.
`architecture` is an explicit upstream-supported architecture or `unknown`;
`vendor` is `cpu`, `nvidia`, `amd`, `intel`, `apple`, `multi`, or `unknown`.
Provider names are descriptive strings, e.g. `onnxruntime-cpu`,
`onnxruntime-cuda`, `onnxruntime-migraphx`, `onnxruntime-rocm-legacy`,
`onnxruntime-directml`, `pytorch-rocm`, `pytorch-cuda`, `coreml`, `mps`,
`nam-eigen`, or `hip-dsp`. Do not collapse different providers into `gpu=true`.

The duplicate-backend key is the tuple `(component, platform, architecture,
vendor, provider)`. Keep multiple provider versions in `runtime_pins`/evidence,
not duplicate tuples with contradictory current status. `cpu_fallback` is one
of `supported`, `unsupported`, `unknown`, `not-applicable`. `package_attribute`
is null or a nonempty real export name; `source_revision` is null or a full
upstream commit; `runtime_id` is null or a stable string identifying the exact
provider/runtime tuple. Non-null unresolved names are not proof of packaging.

Allowed `upstream_status`: `implemented`, `experimental`, `documented-only`,
`port-required`, `unsupported`, `unknown`.
Allowed `integration_status`: `not-packaged`, `packaged`, `blocked`.
Allowed validation values: `not-run`, `passed`, `failed`, `not-run-policy`,
`not-applicable`. Any `passed`/`failed` stage needs evidence with the matching
stage; any policy-skipped stage needs a reason. Loading a library does not pass
model/provider/host execution. A successful CPU fallback does not pass GPU execution.

Evidence records contain `kind` (`upstream` or `verification`), `reference`
(official HTTPS URL or repository-relative evidence document), `revision` (full
source commit when applicable), `stage` (`assessment`, `evaluation`, `build`,
`load`, `model_execution`, `provider_execution`, `host`) and a factual `summary`.
Pending assessments may have no evidence; completed conclusions require it.
Runtime pins name the framework, provider build, CUDA/cuDNN or ROCm/MIGraphX
requirements, source/artifact revision and hash where an actual package is built.
Do not substitute today's package-search result for the locked runtime tuple.
Model references record provenance/terms/size without automatically downloading models.

Typed collection items:

- `runtime_pins[]`: `{name: string, version: string|null, revision: string|null,
  hash: string|null, source_url: https-url|null, note: string}`. Unresolved fields
  require a factual note. A packaged framework/provider must have its version or
  full source revision and fetched-source/artifact hash recorded directly or in a
  cited package recipe; GPU system drivers are environment evidence, not fetched pins.
- `model_refs[]`: `{id: string, source_kind: string, source_url: https-url|null,
  revision: string|null, sha256: string|null, bytes: positive-int|null,
  license_evidence: string, acquisition: string}`. Unique IDs; `source_kind` is
  `official-download`, `user-supplied`, `bundled`, `manual`, or `unknown`;
  `acquisition` is `not-requested`, `authorized`, `acquired`, or `manual-required`.
  User-supplied private paths/credentials are not published. Unresolved sources
  stay null rather than invented. Execution evidence must identify acquired
  model bytes by hash; model-free library-load checks need no acquired model.
- Any passed/failed stage must cite a backend-local evidence item with
  `kind: verification`, the exact stage and a `subject` object. An upstream
  claim or another stage cannot satisfy a campaign verification result.
- `subject`: `{package_attribute: string|null, source_revision: string,
  artifact: string|null, attempt: string|null, runtime_id: string, model_id: string|null, model_sha256:
  string|null, environment: object}`. The attribute, source revision and runtime
  ID must match the backend. `artifact` identifies actual tested output bytes
  (e.g. a Nix output path or an archive digest), not only a display name.
  `environment` has `os`, `architecture`, `execution_context`, `gpu_vendor`,
  `gpu_model`, `driver`; strings or null for non-applicable hardware fields,
  but OS, architecture and execution context are nonempty. GPU-stage success
  requires GPU identity and driver evidence. Model/provider execution requires
  a declared model ID and matching acquired model SHA-256. Native Windows,
  Wine and Linux execution contexts cannot validate one another implicitly.

For providers supporting several vendors (such as DirectML), split vendor-specific
backend records before hardware acceptance. A `vendor: multi` or `unknown` route
cannot earn passing model/provider/host stages: a test on NVIDIA does not validate
AMD through a shared provider name. The environment's GPU vendor must match the
specific backend, and AMD model/provider/host stages remain policy-skipped.

Failed evaluation/build stages may have no output bytes: set `artifact: null`,
identify the attempted derivation or exact input tuple in nonempty `attempt`,
and cite diagnostic evidence through the verification record's `reference`.
Do not invent a successful output to describe a failed build. Successful
evaluation may identify an evaluated derivation or a digest of evaluated metadata;
successful build/load/execution stages require a concrete artifact identity.

Bind every passed/failed claim to these exact subjects. Build success at one
runtime version must not validate a later provider tuple. CPU fallback evidence
is a CPU backend result, not a passing GPU `provider_execution` result. AMD
hardware stages remain policy-skipped even if upstream publishes execution logs.

## Evidence-based initial leads

These are research leads at the current upstream state; freeze commits during
execution and reconcile them with the selected plugin release before packaging.

| Entry | Route | Planning disposition |
| --- | --- | --- |
| AUDIO-065 INTERSECT | Linux NVIDIA ORT CUDA; Linux AMD ORT MIGraphX; native Windows DirectML | First accelerated pilot; AMD remains experimental and hardware-untested |
| AUDIO-013 AudioRestorationVST | Optional CUDA; legacy ORT ROCm; distinct HIP DSP code | CUDA candidate; preserve legacy compatibility evidence; do not advertise incomplete HIP DSP as working |
| AUDIO-090 OBSIDIAN-Neural | External PyTorch CUDA server; possible PyTorch ROCm port | Separate server package; AMD port-required, not a generic wheel substitution |
| AUDIO-012 VocalGate | CPU quantized ONNX inference; GPU references in training | Record training/inference distinction; no GPU runtime by implication |
| AUDIO-011 Mahogany | CPU ONNX path, macOS neural build | Port/platform work is separate from GPU enablement |
| AUDIO-089 Sledge/NAM | CPU C++/Eigen inference | Retain CPU baseline; neural inference does not require CUDA |
| AUDIO-006 CleanVoice | Conventional DSP in inspected source | Do not classify AI-authored code as a neural runtime |

Critical AMD/version evidence:

- ORT's ROCm EP was removed starting with ORT 1.23; MIGraphX is a distinct
  provider requiring actual integration, not a drop-in metadata rename.
- INTERSECT publishes an experimental ORT 1.24.2 MIGraphX bundle; its workflow
  uses ROCm 7.2.2 and skips tests. This is provenance, not AMD acceptance evidence.
- AudioRestorationVST's inspected ROCm option uses ORT 1.17.3. Upgrading that path
  to a new ORT requires source/API compatibility work; pinning old code requires
  a separate security/maintenance assessment.
- PyTorch ROCm uses `torch.cuda` API names. Inspect `torch.version.hip` and the
  actual provider build before assuming these names mean NVIDIA or AMD support.
- Native Windows DirectML support is not proof of DirectML working under Wine.

Sources:

- https://tucktuckg00se.github.io/INTERSECT/installation/
- https://github.com/tucktuckg00se/INTERSECT/blob/main/src/audio/StemSeparationJob.cpp
- https://github.com/tucktuckg00se/intersect-ort-providers/releases/tag/ort-1.24.2
- https://github.com/tucktuckg00se/intersect-ort-providers/blob/main/.github/workflows/build.yml
- https://github.com/flarkflarkflark/AudioRestorationVST/blob/main/CMakeLists.txt
- https://github.com/flarkflarkflark/AudioRestorationVST/blob/main/Source/DSP/OnnxDenoiser.cpp
- https://github.com/flarkflarkflark/AudioRestorationVST/blob/main/Source/GPU/GPUSpectralProcessor.cpp
- https://github.com/innermost47/obsidian-neural-gpu-server/blob/main/install.sh
- https://github.com/innermost47/obsidian-neural-gpu-server/blob/main/device_utils.py
- https://onnxruntime.ai/docs/execution-providers/ROCm-ExecutionProvider.html
- https://onnxruntime.ai/docs/execution-providers/MIGraphX-ExecutionProvider.html
- https://onnxruntime.ai/docs/execution-providers/DirectML-ExecutionProvider.html
- https://docs.pytorch.org/docs/stable/notes/hip.html

## Packaging and runtime architecture

Reuse the existing `pluginArtifacts` and `juceRuntime` contracts. Add backend
arguments to the relevant package definition only after the CPU baseline exists.
Expose names such as `<base>-cuda` or `<base>-migraphx` only once implemented;
do not add fake attributes for catalog-only entries. An uncertain-license package
can use the existing conditional set without blocking technical work or pretending
its license is verified free. Do not weaken existing consumer opt-in policy.

Runtime providers must match their plugin's ORT/PyTorch ABI and exact provider
dependencies. Keep evaluation lazy so CPU/package-metadata checks do not evaluate
or fetch CUDA/ROCm closures. Avoid global `cudaSupport` changes or ambient
`LD_LIBRARY_PATH` modifications affecting the entire DAW. Expose only the runtime
libraries actually consumed by the selected variant. Driver/device access and
kernel configuration remain consumer-owned.

Separate external servers from plugin clients. Bind a new local service to
loopback by default if a service is implemented; do not auto-start it. Review
authentication, model provenance, network egress, VRAM and disk consumption.
No undocumented model acquisition or executable installer runs during evaluation.

## Full-set orchestration and acceptance

Use eight disjoint 13-entry assessment shards, leaving capacity for two reviewers:
001–013, 014–026, 027–039, 040–052, 053–065, 066–078, 079–091, 092–104.
All 104 enter the same run; difficult entries do not disappear behind the pilots.
The orchestrator is the sole writer of shared catalog/flake/export/README files.
Workers own evidence reports or assigned package directories, never shared exports.
At most two heavy builds run concurrently, each initially capped at four cores
and one Nix job; reduce further on memory pressure. GPU execution is serialized.

Assessment acceptance requires a complete, source-backed conclusion or an explicit
`blocked-evidence` reason and next action for each of the 104 entries. Global
success requires zero `pending` assessments, not 104 GPU packages. Preserve build
failures and port-required routes as visible outcomes. AMD can be packaged and
build/load-checked where possible while hardware stages remain `not-run-policy`.

For tested NVIDIA routes, require actual model execution and evidence that the
selected provider executed supported graph nodes; a listed provider alone is not
enough. Record any CPU node placement/fallback explicitly. For live processing,
measure block sizes 64/128/256 at 48 kHz, latency, warm-up and callback deadline
misses; also test GUI, automation and state recall. For background jobs measure
completion time, VRAM and effects on concurrent playback. Performance is never
inferred from successful compilation.
