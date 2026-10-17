# AUDIO-086 — JC120 Plugin

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Source and `v1.0.0` tag: `maluscomas/JC120-Plugin@fc99022d49f5305c3dcd3bea0724344b7be1c802`.

`PluginProcessor.cpp` implements soft clipping, one-pole tone shaping, interpolated delay modulation for chorus, and comb/allpass reverb inside `processBlock`. It does not load an amp neural model. `JC120.jucer` references JUCE audio/DSP modules and local module paths, with no neural framework dependency. An amplifier-emulation name does not imply NAM or GPU inference.

## Upstream assessment evidence

- [Processor implementation](https://github.com/maluscomas/JC120-Plugin/blob/fc99022d49f5305c3dcd3bea0724344b7be1c802/Source/PluginProcessor.cpp)
- [Projucer build declarations](https://github.com/maluscomas/JC120-Plugin/blob/fc99022d49f5305c3dcd3bea0724344b7be1c802/JC120.jucer)

Only `JC120-macOS-VST3.zip` is listed by the v1.0.0 release API. Windows readiness and a Linux port remain separate work; a Windows/Wine route cannot be asserted from the macOS payload. No inference backends or models are recorded. All campaign stages remain not-run; no archive or executable was fetched.

Rights: retain MIT evidence and separately review JUCE/dependency obligations; no inferred license change.

Next action: establish an explicit Linux build/exporter or usable Windows source build before platform packaging; retain CPU DSP.
