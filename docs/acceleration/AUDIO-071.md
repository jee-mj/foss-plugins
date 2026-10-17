# AUDIO-071 — Plasma

Assessment date: 2026-10-17. Repository: `Dimethoxy/Plasma`.
Pinned source: `00f25fe1ae1b8ee62197b27f0b10196ac08abb68`; official GitHub commit/tree/contents API inspection.

## Outcome

**complete; ai_role: none; execution_mode: not-applicable.** Component `plasma` implements non-neural CPU distortion and resonant filters. The callback runs analytic shapers on samples and processes left/right JUCE chains. Loudness metering is separate conventional analysis.

- [PluginProcessor.cpp](https://github.com/Dimethoxy/Plasma/blob/00f25fe1ae1b8ee62197b27f0b10196ac08abb68/Source/PluginProcessor.cpp): `processBlock` calls `DistortionProcessor::distort`, filter chains and loudness meters.
- [PlasmaDistortionProcessor.h](https://github.com/Dimethoxy/Plasma/blob/00f25fe1ae1b8ee62197b27f0b10196ac08abb68/Source/PlasmaDistortionProcessor.h): hard/soft clipping, powers, atan, sine/cosine and other explicit distortion formulas; no learned-layer dispatch.
- [Plasma.jucer](https://github.com/Dimethoxy/Plasma/blob/00f25fe1ae1b8ee62197b27f0b10196ac08abb68/Plasma.jucer): declares AU/LV2/VST3, local distortion/meter code and JUCE modules. LinuxMake exporter contains machine-specific JUCE paths, requiring packaging work. Snapshot version is 1.3.0, distinct from the catalog's captured 1.2.1 release evidence.

## Integration

Linux CPU `juce-cpp-dsp`, architecture unknown. `implemented` describes DSP source, not build success; integration `not-packaged`. Package attribute/runtime ID null; pins/models empty. Inspected source/build paths provide no neural/GPU-audio route; GUI OpenGL inclusion alone is insufficient.

All six validation stages `not-run`. No native Windows or Wine GPU result inferred. Future AMD GPU model/provider/host stages remain `not-run-policy` because AMD hardware execution is excluded.

Next: reconcile release and repair portable dependency paths before CPU builds. Preserve the catalog's GPL/AGPL discrepancy, full-license evidence and consumer judgement; do not silently resolve conflicting rights metadata or treat it as a technical gate.
