# AUDIO-052 — Caravan

- Repository: `biferdou/Caravan`
- Inspected revision: `73d45a102b406dbd8eba5fa643f6d129d202fbd7` (official GitHub APIs).
- Assessment: **complete / none / not-applicable**.

## Pinned upstream evidence

All references are `kind: upstream`, `stage: assessment`, revision above.

- [CaravanProcessor.cpp](https://github.com/biferdou/Caravan/blob/73d45a102b406dbd8eba5fa643f6d129d202fbd7/plugin/caravan/source/core/CaravanProcessor.cpp): `processBlock` applies input gain, vocal EQ/de-esser/exciter, DustDrive, stereo width and output gain.
- [DustDriveSaturator.cpp](https://github.com/biferdou/Caravan/blob/73d45a102b406dbd8eba5fa643f6d129d202fbd7/plugin/caravan/source/effects/DustDriveSaturator.cpp): polarity-dependent tanh/exponential saturation, wet/dry mixing and optional cascaded stages. No neural model load/inference path.
- [plugin/CMakeLists.txt](https://github.com/biferdou/Caravan/blob/73d45a102b406dbd8eba5fa643f6d129d202fbd7/plugin/CMakeLists.txt): VST3 target, conventional effect sources, Linux packaging settings and JUCE/OpenGL linkage.
- [root CMakeLists.txt](https://github.com/biferdou/Caravan/blob/73d45a102b406dbd8eba5fa643f6d129d202fbd7/CMakeLists.txt): CPM requests JUCE 8.0.6, enables graphics header options, adds plugin directory.
- [CaravanOpenGLContext.h](https://github.com/biferdou/Caravan/blob/73d45a102b406dbd8eba5fa643f6d129d202fbd7/plugin/caravan/source/ui/opengl/CaravanOpenGLContext.h): UI wrapper derives from `juce::OpenGLContext`, not a compute/inference provider.

## Disposition

`vocal-chain` is non-neural DSP. Recorded Linux/unknown-architecture/CPU/`juce-cpp-vocal-dsp` backend is implemented/not-packaged. OpenGL rendering does not turn vocal DSP into GPU audio processing or NN inference. No NVIDIA/AMD runtime route is established. Windows installer/Wine and native Linux source are distinct leads, with no compatibility result inferred between them.

Package attribute/runtime ID null; inference pins/model refs empty. Framework fetch/hash resolution remains packaging work, and no acquired model is claimed. License information is not a technical gate. Release/source version reconciliation is separate from this fixed-source processing assessment.

## Validation / next action

All six validation stages **not-run**. Establish Linux CPU VST3 dependency closure and compare with a separately investigated Windows/Wine installer route, then validate audio/GUI/state/host behavior under authorization. No binaries, models or installers were executed. Any future AMD hardware model/provider/host acceptance remains `not-run-policy`.
