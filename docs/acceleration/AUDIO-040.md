# AUDIO-040 — 0xFX

- Repository: `averagenative/0xFX`
- Inspected revision: `5b248779c96dce6e64d0ed29cfa598014dc4d3c4` (official GitHub commits/HEAD API, frozen for subsequent contents/tree API requests).
- Assessment: **complete**; AI role **none**; execution mode **not-applicable** under the non-neural schema convention. Actual DSP runs in the audio processing chain.

## Source findings

The amplifier is an ordinary DSP model, not a neural amp capture engine. `amp_configs` contains hand-configured gain stages, shapers and R/C component values. `fx_amp_process` (700–820) performs preamp waveshaping, circuit-derived tone filtering, envelope compression, feedback limiting and supply sag. No learned weights, NAM/Eigen/RTNeural forward pass or model acquisition is involved in this path. Cabinet WAV IR convolution is separate from amplifier modeling and is not neural inference.

Pinned official evidence (all `kind: upstream`, `stage: assessment`, revision above):

- [amp.c](https://github.com/averagenative/0xFX/blob/5b248779c96dce6e64d0ed29cfa598014dc4d3c4/src/engine/internal/amp.c): fixed amp parameter tables and actual sample processing, including tanh/polynomial-style shaping and third-order filters.
- [engine.c](https://github.com/averagenative/0xFX/blob/5b248779c96dce6e64d0ed29cfa598014dc4d3c4/src/engine/internal/engine.c): callback chain dispatches gate, pedals, amp, cabinet, mic and studio DSP.
- [cab_ir.c](https://github.com/averagenative/0xFX/blob/5b248779c96dce6e64d0ed29cfa598014dc4d3c4/src/engine/internal/cab_ir.c): dr_wav loading/resampling and KissFFT overlap-add convolution.
- [CMakeLists.txt](https://github.com/averagenative/0xFX/blob/5b248779c96dce6e64d0ed29cfa598014dc4d3c4/CMakeLists.txt): compiles the C engine, plugins and standalone; graphics links are attached to UI code.

## Backend and integration disposition

Recorded tuple: `guitar-chain / linux / x86_64 / cpu / native-c-dsp-kissfft`, implemented upstream, not packaged here. CMake also branches for Linux aarch64, Windows x86_64/ARM64 and macOS arm64/x86_64; configured source branches do not prove each artifact builds. No inference GPU provider is established for NVIDIA, AMD, Intel or Apple. OpenGL is rendering, not accelerated DSP. Wine smoke tooling does not establish audio/GUI/state acceptance or a Wine GPU provider.

Package attribute and runtime ID are null. Runtime pins/model references are empty: no inference runtime or neural model identified, and no package built. Cabinet IR provenance/terms require separate content review if selected; an IR is not added as a fabricated neural model reference. License metadata is informational, not a technical implementation gate.

## Validation and next action

Evaluation, build, load, model execution, provider execution and host stages are **not-run**. No AMD backend is asserted; any future AMD hardware model/provider/host stages must be `not-run-policy` with the campaign reason. Investigate a native Linux CPU recipe, reconcile this source pin with the desired release, then perform separately authorized host checks. No GPU inference enablement is indicated.
