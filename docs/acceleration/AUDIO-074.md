# AUDIO-074 — Spiro

Assessment date: 2026-10-17. Repository: `p-o-l-e/spiro`.
Pinned source: `bf86749dd255c11ce4470c0e3a855ad55568b468`; official GitHub commit/tree/contents API inspection.

## Outcome and implementation

**complete; ai_role: none; execution_mode: not-applicable.** Component `spiro` is semi-modular oscillator/envelope/rack synthesis on CPU.

- [PluginProcessor.cpp](https://github.com/p-o-l-e/spiro/blob/bf86749dd255c11ce4470c0e3a855ad55568b468/source/PluginProcessor.cpp), lines 447 onward: callback handles MIDI, clears output and calls `spiro.process()` once per sample, copying stereo outputs.
- [core/spiro.cpp](https://github.com/p-o-l-e/spiro/blob/bf86749dd255c11ce4470c0e3a855ad55568b468/source/core/spiro.cpp): `Spiro::process` iterates whitelisted rack modules and reads the mixer; note handling updates VCO/ENV state explicitly. This is conventional modular synthesis rather than a model inference graph.
- [CMakeLists.txt](https://github.com/p-o-l-e/spiro/blob/bf86749dd255c11ce4470c0e3a855ad55568b468/CMakeLists.txt): JUCE audio/DSP, clap extensions, inspector and OpenGL UI linkage, with optional SpiroIPP inclusion.
- [SpiroIPP.cmake](https://github.com/p-o-l-e/spiro/blob/bf86749dd255c11ce4470c0e3a855ad55568b468/cmake/SpiroIPP.cmake): optional Intel IPP CPU libraries, Windows package path, Linux discovery and macOS x86_64 wheel FetchContent. No artifact was fetched or code executed.

## Backend distinction

Recorded Linux backend: `juce-cpp-rack-dsp`, vendor CPU, architecture unknown. Neither GUI shaders nor Intel IPP establish a GPU audio provider. IPP is an optional CPU-library build route; this inspection does not establish which active call sites gain performance, so no extra accelerated audio backend is advertised.

Integration `not-packaged`; exports/runtime ID null, pins/model refs empty. All six backend validation stages `not-run`. No NVIDIA/AMD inference or GPU-audio route established; native Windows does not validate Wine. Future AMD GPU model/provider/host stages remain `not-run-policy`.

Next: pin dependencies and control optional build-time IPP acquisition before a separately authorized CPU baseline build. Preserve upstream MIT and dependency/IPP terms independently; uncertainty is informational, not an inference assessment blocker.
