# AUDIO-076 — Delirion

Assessment date: 2026-10-17. Repository: `igorski/delirion`.
Pinned source: `17f4f406af8e896fe34b9b8f7d70c79681b37a93`; official GitHub commit/tree/contents API inspection.

## Outcome and evidence

**complete; ai_role: none; execution_mode: not-applicable.** Component `delirion` is conventional multiband effects DSP.

- [PluginProcessor.cpp](https://github.com/igorski/delirion/blob/17f4f406af8e896fe34b9b8f7d70c79681b37a93/src/PluginProcessor.cpp), lines 245–313: `processBlock` copies low/mid/high audio buffers, applies Doppler processing per band, low-band waveshaping and mid-band reverb, filters bands and recombines them with a dry/wet mix. Direct buffer/sample processing establishes the CPU DSP route, rather than relying on product naming.
- [CMakeLists.txt](https://github.com/igorski/delirion/blob/17f4f406af8e896fe34b9b8f7d70c79681b37a93/CMakeLists.txt): adds JUCE, selects VST3 for non-Apple and VST3/AU for Apple, detects Linux and links resources/juce_audio_utils. Build declarations are not proof of a working Linux artifact.

## Disposition

Linux CPU `juce-cpp-dsp`, architecture unknown. No neural or GPU-audio provider identified in inspected callback/build routes. No Windows assets or shared code are treated as Wine acceleration evidence.

Integration `not-packaged`, exports/runtime ID null; pins/models empty. All six validation stages `not-run`. No AMD GPU route asserted; future AMD GPU model/provider/host stages remain `not-run-policy` because hardware execution is excluded.

Next: pin JUCE and establish a separately authorized Linux CPU build/load/host baseline. Preserve GPL v3-or-later/source and dependency notices and consumer judgement. Unverified Linux builds remain visible follow-up work, not a reason to misclassify the DSP as unknown inference.
