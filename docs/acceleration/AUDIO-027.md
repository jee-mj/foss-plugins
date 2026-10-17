# AUDIO-027 — Valvra

Assessment: **complete**; AI role **mixed** (local inference and offline training); execution **mixed** (audio callback and offline job). Research date: 2026-10-17.

Repository: `hwangtab/valvra`; frozen source: `10bdcb6db0d0cb8f5dd243dbedce74ea73e61393`. Official GitHub commits, recursive-tree and contents APIs were inspected at this revision.

## Products and actual execution

- **Valvra**, **Valvra Compressor**, and **Valvra Tape** are three distinct CMake products sharing `PluginProcessor.cpp`. Each has the same optional neural residual requirements, with different expansion defaults.
- `NeuralResidualLayer::process` computes a fixed-weight 5→4→1 tanh MLP on CPU, or calls the optional RTNeural 5→8→1 model's `forward`. Bootstrap weights are constants, not evidence of measured training quality.
- The processor calls the residual per sample in `processBlock` only when effective neural blend exceeds 1e-6. Neural Blend defaults to zero. Physics-only operation remains viable. `VALVRA_NEURAL_MODEL` or explicit file loading supplies optional local JSON; no model acquisition is authorized here.
- `VALVRA_USE_RTNEURAL` defaults OFF. When enabled, CMake forces RTNeural's STL backend and fetches moving `main`. The dependency has no immutable revision, version or artifact hash in this inspected recipe. Pinning it and checking its JSON/parser compatibility are packaging prerequisites, not assessment blockers.
- `scripts/train_neural_residual.py` trains with PyTorch, explicitly `torch.device("cpu")`. It writes a simple weight bundle whose own note requires conversion to RTNeural JSON. This is a distinct training component; export/load compatibility has not been demonstrated.

## Acceleration and platform disposition

No CUDA, HIP, ROCm, MIGraphX, DirectML or other GPU inference provider is selected by these build/inference paths. OpenGL linkage serves the plugin/UI and is not evidence of GPU neural DSP. The JSON records the source-implemented optional CPU RTNeural route per product on macOS arm64, the explicit plugin workflow platform. Built-in CPU fallback is supported in source. Linux/Windows DSP workflow jobs disable plugin builds; those jobs do not establish plugin or RTNeural acceptance. Linux source/plugin portability and native Windows/Wine host behavior remain follow-up work. A GPU route would require new integration and workload justification for this tiny callback model.

## Pinned upstream assessment evidence

- [Root build options and RTNeural STL dependency](https://github.com/hwangtab/valvra/blob/10bdcb6db0d0cb8f5dd243dbedce74ea73e61393/CMakeLists.txt)
- [Three product targets sharing the processor](https://github.com/hwangtab/valvra/blob/10bdcb6db0d0cb8f5dd243dbedce74ea73e61393/src/plugin/CMakeLists.txt)
- [Actual bootstrap/RTNeural forward and JSON loader](https://github.com/hwangtab/valvra/blob/10bdcb6db0d0cb8f5dd243dbedce74ea73e61393/src/dsp/NeuralResidualLayer.h)
- [Callback, blend default and model loading](https://github.com/hwangtab/valvra/blob/10bdcb6db0d0cb8f5dd243dbedce74ea73e61393/src/plugin/PluginProcessor.cpp)
- [CPU training and unconverted export](https://github.com/hwangtab/valvra/blob/10bdcb6db0d0cb8f5dd243dbedce74ea73e61393/scripts/train_neural_residual.py)
- [Platform/job scope](https://github.com/hwangtab/valvra/blob/10bdcb6db0d0cb8f5dd243dbedce74ea73e61393/.github/workflows/build.yml)

All citations are upstream evidence, stage **assessment**, not campaign verification. Evaluation, build, load, model/provider execution and host validation are **not-run**. No AMD backend is evidenced; any future AMD hardware stages must remain **not-run-policy** under the campaign rule. Integration is **not-packaged**, package attributes/runtime IDs null. Runtime/model unknowns are explicit in the companion envelope. Rights fields are preserved; repository GPL evidence does not establish terms of an arbitrary user-supplied capture/model. Missing model terms are informational and require consumer judgement.

Next action: pin RTNeural and its fetched hash, obtain explicit authorization for a provenance-reviewed model, convert/check its JSON architecture, then separately evaluate CPU plugin packaging and host validation on each platform.
