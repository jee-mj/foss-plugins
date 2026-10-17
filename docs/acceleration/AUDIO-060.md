# AUDIO-060 — ADLplug-Next suite

Assessment: **complete; none; not-applicable** (2026-10-17).
Pinned source: `yumasansansan/ADLplug-Next` at `563e5443041f253bc91be2f8716b7e1c0940ca97` (matches catalog's captured nightly commit).

- [CMakeLists.txt](https://github.com/yumasansansan/ADLplug-Next/blob/563e5443041f253bc91be2f8716b7e1c0940ca97/CMakeLists.txt): OPL3 branch links `ADLMIDI_static`/WOPL, OPN2 branch links `OPNMIDI_static`/WOPN, alongside JUCE and resampling. CPU target flags and PGO are compiler optimization, not training a neural DSP model.
- [plugin_processor.cc](https://github.com/yumasansansan/ADLplug-Next/blob/563e5443041f253bc91be2f8716b7e1c0940ca97/sources/plugin_processor.cc): sample-accurate MIDI dispatch and `resampler_.pull(... pl.generate(...))` drive chip synthesis, followed by DC filters and meters.

Separate `adlplug-opl3` and `opnplug-opn2` non-neural components preserve the family distinction. No model, NN runtime or NVIDIA/AMD inference provider identified. Existing older `adlplug` packages are not proof of packaging this fork. Next: native package/CPU ISA and bank provenance investigation. Instrument-bank/dependency terms need separate review; no license technical gate. All validation not-run; Windows/Wine remains independent and unverified.
