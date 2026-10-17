# AUDIO-042 — TimeLagFilter

- Repository: `sauraen/timelagfilter`
- Inspected revision: `0b358117300f2445891619958d87de3a00d72b9f` (official GitHub APIs).
- Assessment: **complete / none / not-applicable**. Non-neural DSP does run on audio samples; `not-applicable` is the spec's non-neural execution-mode convention.

## Pinned upstream evidence

All evidence is `kind: upstream`, `stage: assessment`, at the full revision above.

- [TimeLagFilterCore.cpp](https://github.com/sauraen/timelagfilter/blob/0b358117300f2445891619958d87de3a00d72b9f/Source/TimeLagFilterCore.cpp): `sample()` (446–495) implements cascaded LTI recurrences in ring buffers using computed coefficients. DTCalcThread/DlyCalcThread are filter-parameter workers, not inference workers.
- [PluginProcessor.cpp](https://github.com/sauraen/timelagfilter/blob/0b358117300f2445891619958d87de3a00d72b9f/Source/PluginProcessor.cpp): `processBlock` invokes `core.sample` for wet output and mixes stereo channels.
- [TimeLagFilter.jucer](https://github.com/sauraen/timelagfilter/blob/0b358117300f2445891619958d87de3a00d72b9f/TimeLagFilter.jucer): enables **both VST and VST3**, disables AU, defines VS2013 x64/32-bit and a Linux Make exporter. Local JUCE and SDK paths remain unresolved, including Windows module paths in the Linux exporter.

## Disposition

Component `time-lag-filter` is `non-neural-dsp`. Recorded backend is `windows / x86_64 / cpu / juce-cpp-dsp`, implemented upstream, `not-packaged`. Source configuration also exposes Windows x86; it does not establish which format is inside each DLL. The Linux exporter is a concrete source lead beyond README evidence, but is not a successful Linux build. Native Windows and Wine require separate validation.

No NN runtime/model or NVIDIA/AMD compute provider was identified in these paths. CPU processing is supported; package attribute/runtime ID are null, runtime pins/model references empty. Framework version/hash must be resolved during packaging, rather than inventing an inference pin. License information is not a technical gate.

## Validation / next action

All six validation stages are **not-run**. Resolve legacy JUCE/VST SDK dependencies and actual artifact format/architecture, then investigate CPU packaging and host checks. No AMD route is asserted; future AMD hardware model/provider/host checks are policy-skipped, not passed by upstream claims.
