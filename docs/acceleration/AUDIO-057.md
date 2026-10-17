# AUDIO-057 — snida / Capicola

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `SungamMagnus/snida` at `ad5b37644b8951fe475472dec801665af4c33cc4`.

- [Plugin engine](https://github.com/SungamMagnus/snida/blob/ad5b37644b8951fe475472dec801665af4c33cc4/plugin/Source/CapicolaEngine.cpp): chunked `SparseLine::ProcessBlock`, transient detector/envelope gates and shaped feedback; conventional recorder/time manipulation.
- [Plugin build](https://github.com/SungamMagnus/snida/blob/ad5b37644b8951fe475472dec801665af4c33cc4/plugin/CMakeLists.txt): JUCE audio-utils/DSP plugin with no inference framework integration.
- [Firmware engine](https://github.com/SungamMagnus/snida/blob/ad5b37644b8951fe475472dec801665af4c33cc4/src/audio/audio_engine.cpp): separate embedded DSP also calls SparseLine processors and filters/saturates feedback; no NN runtime evidenced.

Plugin and firmware are distinct non-neural components. Embedded build infrastructure does not prove Linux plugin support. No NN model or NVIDIA/AMD provider is identified. Next: investigate desktop platform port/build independently of firmware. Wine unknown. No validation execution performed; existing firmware/dependency rights require separate consumer review and do not gate this assessment.
