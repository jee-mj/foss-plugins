# AUDIO-102 — VDX7-JUCE

Assessment: **complete; ai_role none; execution_mode not-applicable**.
Official GitHub API pin: `RobCZart82/VDX7-JUCE@78a4dd752bbff1d6ca23a202c346fab854317b8a`.

- [Engine source](https://github.com/RobCZart82/VDX7-JUCE/blob/78a4dd752bbff1d6ca23a202c346fab854317b8a/Source/VDX7Engine.cpp): validates a user ROM, loads firmware into `dx7_`, starts the emulated device and advances firmware cycles. HD6303R reset-vector checks and original-device stepping establish hardware/firmware emulation, not neural inference.
- [Processor](https://github.com/RobCZart82/VDX7-JUCE/blob/78a4dd752bbff1d6ca23a202c346fab854317b8a/Source/PluginProcessor.cpp) manages MIDI, engine ownership and ROM-bound project state. ROM identity is not a model-weight identity.
- [Build](https://github.com/RobCZart82/VDX7-JUCE/blob/78a4dd752bbff1d6ca23a202c346fab854317b8a/CMakeLists.txt) selects portable `dx7Lib` core from `reales/retromulator@d5473776a0449d60a997b91bdc888598a33265ac` and JUCE, with ROM-free test targets; no NN runtime integration found in this path.

`dx7-emulator` is non-neural DSP. No NVIDIA/AMD provider dependency or neural model reference is appropriate. **Firmware is separately copyrighted user-supplied material**, not covered by wrapper/core licenses; no ROM was acquired, linked as a downloadable model, packaged or executed. The catalog's original DX7 Mk I v1.8 ROM condition and consumer judgement remain unchanged.

Windows/macOS source routes do not demonstrate Wine or native Linux compatibility. No compile, test, load or host execution performed; upstream validation documents are not local campaign acceptance. Next: preserve manual firmware boundary and investigate authorized Windows/Wine host behavior independently; do not add NN acceleration dependencies.
