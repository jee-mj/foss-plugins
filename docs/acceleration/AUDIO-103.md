# AUDIO-103 — Hollow

Assessment: **complete; ai_role none; execution_mode not-applicable**.
Official API pin: `lheiler/hollow_plugin@18c6fa4267aea5dd2df1d22171d24e99534fdb59`.

- [Processor](https://github.com/lheiler/hollow_plugin/blob/18c6fa4267aea5dd2df1d22171d24e99534fdb59/source/plugin/PluginProcessor.cpp) runs `chain.process()` and an `ImpulseWorker` synthesizing/partitioning convolution impulses outside the audio thread. A worker thread does not imply model inference.
- [Chain](https://github.com/lheiler/hollow_plugin/blob/18c6fa4267aea5dd2df1d22171d24e99534fdb59/source/dsp/Chain.h) explicitly dispatches Filter1, Trash, Filter2, Convolve, Motion, Degrade, Dynamics and Echo. Static spectral level estimates derive from knob settings/impulses; not learned inference. These modules share conventional CPU DSP requirements, so one component is sufficient.
- [Build](https://github.com/lheiler/hollow_plugin/blob/18c6fa4267aea5dd2df1d22171d24e99534fdb59/CMakeLists.txt) adds a user-specified JUCE checkout (default JUCE-9.0.2), VST3/Standalone and conditional Apple AU targets. No neural/GPU runtime integration in inspected target.

Components `hollow-chain` and `impulse-preparation` distinguish callback DSP from conventional background impulse preparation. No NN/GPU backends established. The CMake non-Apple branch alone does not certify Linux plugin delivery; catalog's Windows cross-build/macOS source investigation remains separate. No builds, tests, load or host execution performed. Copyright retained. Next: resolve reproducible JUCE/toolchain/source tuple and native versus Windows/Wine artifact route under authorization.
