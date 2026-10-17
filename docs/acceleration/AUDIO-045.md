# AUDIO-045 — FreeVox8

- Repository: `GareBear99/FreeVox8`
- Inspected revision: `02eedfe2ee38618d38718c3c47d8ba55a0cd6a10` (official GitHub APIs).
- Assessment: **complete / none / not-applicable**.

## Components and implementation

Two CPU components have materially different processing requirements:

1. `filterbank-vocoder`: IIR modulator/carrier band filters, envelope tracking/remapping, carrier synthesis, freeze/mask/morph modes and saturation.
2. `spectral-ghost`: 1024-sample ring/window processing, explicit sine/cosine spectral-bin accumulation, stored/frozen envelopes and overlap-add output. This current reference implementation has real processing code; older descriptions calling all of it a future scaffold are incomplete. Its “STFT/OLA” comment does not establish use of an optimized FFT, reconstruction quality, or measured callback performance.

Pinned official upstream assessment evidence, revision above:

- [FreeVox8DSP.h](https://github.com/GareBear99/FreeVox8/blob/02eedfe2ee38618d38718c3c47d8ba55a0cd6a10/Source/DSP/FreeVox8DSP.h): engine selection, filterbank and envelope code, generated carriers, tanh and stereo width.
- [FreeVox8SpectralEngine.h](https://github.com/GareBear99/FreeVox8/blob/02eedfe2ee38618d38718c3c47d8ba55a0cd6a10/Source/DSP/FreeVox8SpectralEngine.h): `process`, `renderFrame`, `analyseBins`, ring storage and OLA implementation; no learned weights or model execution.
- [PluginProcessor.cpp](https://github.com/GareBear99/FreeVox8/blob/02eedfe2ee38618d38718c3c47d8ba55a0cd6a10/Source/PluginProcessor.cpp): calls `dsp.process`, exposes “Low Latency 128” and “Spectral Ghost 1024”.
- [CMakeLists.txt](https://github.com/GareBear99/FreeVox8/blob/02eedfe2ee38618d38718c3c47d8ba55a0cd6a10/CMakeLists.txt): local/external JUCE, VST3/AU/Standalone and macOS arm64/x86_64 universal setting; no inference runtime dependency.

## Backend disposition

Both components are `non-neural-dsp`. Recorded macOS arm64 CPU tuples use `juce-cpp-filterbank` and `cpp-spectral-bin-ola`, implemented upstream and not packaged. CMake also configures x86_64 in the universal build; those source settings are not successful artifact checks. Generic format declarations do not validate all Linux/Windows targets or Wine.

No NVIDIA/AMD inference provider is established; “vocoder” does not imply a neural vocoder. Package attributes/runtime IDs null; runtime pins/model refs empty. JUCE revision/hash resolution is future packaging work. License information is not a technical gate.

## Validation / next action

All six backend validation stages **not-run**. Resolve JUCE source provenance and actual target buildability, assess spectral reference quality and callback cost, then validate selected hosts. No GPU inference enablement is indicated. AMD hardware model/provider/host execution, if ever represented, remains `not-run-policy`.
