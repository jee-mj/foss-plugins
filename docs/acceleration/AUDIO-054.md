# AUDIO-054 — MegaCrusher

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `lluisestape-upc/MegaCrusher` at `5d3abba1efc1fd54d3aa2d9696aeb5ba71b5d118`.

- [PluginProcessor.cpp](https://github.com/lluisestape-upc/MegaCrusher/blob/5d3abba1efc1fd54d3aa2d9696aeb5ba71b5d118/Source/PluginProcessor.cpp): `processBlock` implements tanh/hard clipping and bit quantization using `round(wet * levels) / levels`, directly on samples.
- [MegaCrusher.jucer](https://github.com/lluisestape-upc/MegaCrusher/blob/5d3abba1efc1fd54d3aa2d9696aeb5ba71b5d118/MegaCrusher.jucer): version 1.0.2 VST3/standalone JUCE project and Windows exporter/module paths. Inclusion of the JUCE OpenGL module is not NN acceleration.

One conventional distortion/bitcrusher component. No model or NN provider integration evidenced. NVIDIA/AMD NN backends are therefore not recorded. Next: investigate the Windows source build and separately assess Wine load/audio/GUI behavior. All execution stages not run; no inference success is inherited from a release label. Existing rights metadata is informational.
