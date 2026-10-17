# AUDIO-094 — WetEQ

Assessment: **complete; ai_role none; execution_mode not-applicable**.
Official API source pin: `yonie/WetEQ@b753c0e50f3563e1a9b2a8d18bee141d7d3da3cb`.

- [Processor](https://github.com/yonie/WetEQ/blob/b753c0e50f3563e1a9b2a8d18bee141d7d3da3cb/WetEQ/source/weteqprocessor.cpp) calls `engine.processStereo()`.
- [EQ engine](https://github.com/yonie/WetEQ/blob/b753c0e50f3563e1a9b2a8d18bee141d7d3da3cb/WetEQ/source/eqengine.cpp) and [header](https://github.com/yonie/WetEQ/blob/b753c0e50f3563e1a9b2a8d18bee141d7d3da3cb/WetEQ/source/eqengine.h) implement smoothed biquad/circuit stages, saturation, crosstalk and noise. Circuit modeling here is analytic DSP, not neural inference.
- [CMake](https://github.com/yonie/WetEQ/blob/b753c0e50f3563e1a9b2a8d18bee141d7d3da3cb/WetEQ/CMakeLists.txt) lists the VST3 SDK source target and Apple AU wrapper, with no NN provider dependency.

Component `wet-eq`: conventional DSP. No NVIDIA/AMD inference route established or needed. Native Linux packaging remains a source lead, while Wine needs its own validation. No build, load or host execution was attempted; metadata is not compile evidence. Existing copyright fields preserved. Next: freeze SDK/source tuple before packaging and verify actual artifacts/host behavior.
