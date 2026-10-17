# AUDIO-049 — WetDiaper

- Repository: `conjius-dp/wet-diaper`
- Inspected revision: `2a9c3bf271a4db06cddaf9c94075fa51c8adad92` (official GitHub APIs).
- Assessment: **complete / none / not-applicable**.

## Pinned upstream evidence

All references are upstream assessment evidence at the revision above.

- [Overdrive.cpp](https://github.com/conjius-dp/wet-diaper/blob/2a9c3bf271a4db06cddaf9c94075fa51c8adad92/Source/DSP/Overdrive.cpp): scalar `processMono`, normalized tanh overdrive and shaping transfer path; not a learned model.
- [PluginProcessor.cpp](https://github.com/conjius-dp/wet-diaper/blob/2a9c3bf271a4db06cddaf9c94075fa51c8adad92/Source/PluginProcessor.cpp): calls `drives[0].processMono` and rebuilds transfer LUTs from editable Bezier curve slots. These LUTs are user-defined transfer curves, not neural weights.
- [CMakeLists.txt](https://github.com/conjius-dp/wet-diaper/blob/2a9c3bf271a4db06cddaf9c94075fa51c8adad92/CMakeLists.txt): WetDiaperDSP, AU/VST3/Standalone and JUCE linkage, no inference provider. JUCE is a source subdirectory whose exact dependency pin must be resolved separately.

## Disposition

Component `overdrive` is `non-neural-dsp`. Recorded Windows/unknown-architecture/CPU/`juce-cpp-waveshaper` route is implemented/not-packaged. Windows release availability is a native/Wine acquisition lead, not Wine acceptance. Source AU and Linux link-option declarations are not evidence of working artifacts on those platforms.

No NVIDIA/AMD inference backend is indicated. Package attribute/runtime ID null; runtime pins/model refs empty because no inference runtime/model was identified or package built. Missing license metadata remains informational and does not technically gate packaging investigation.

## Validation / next action

All six validation stages **not-run**. Resolve exact JUCE source and artifact architecture; establish CPU package and validate native Windows or Wine independently. No models, installers or binaries were executed/downloaded. Future AMD hardware model/provider/host stages, if a real route appears, remain policy-skipped.
