# AUDIO-009 — chorale

Assessment date: 2026-10-17. Repository: `rithulkamesh/chorale`.
Pinned source: `ee5f8b4bc66fc2730065d531f08eabc58288ed7c`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** Eight-voice harmony is
generated with numerical YIN pitch estimation, scale/MIDI rules and conventional
pitch shifting/effects. Neither a harmonizer label nor automatic pitch tracking
establishes a neural or server runtime.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/rithulkamesh/chorale/blob/ee5f8b4bc66fc2730065d531f08eabc58288ed7c/CMakeLists.txt): C++20/JUCE targets compile YIN/PSOLA/harmony DSP and link JUCE DSP, not an ML framework.
- [HarmonyEngine.cpp](https://github.com/rithulkamesh/chorale/blob/ee5f8b4bc66fc2730065d531f08eabc58288ed7c/src/dsp/HarmonyEngine.cpp): direct YIN analysis, voice shifters, rule-based note targeting and signal-graph effects.
- [YinTracker.cpp](https://github.com/rithulkamesh/chorale/blob/ee5f8b4bc66fc2730065d531f08eabc58288ed7c/src/dsp/YinTracker.cpp): FFT cross-correlation and cumulative-mean normalized difference thresholding.

Release `v1.3.0` resolves to this source commit and lists Linux/Windows/macOS ZIPs.
No archive, DAW routing, latency or hardware result was tested.

## Backend disposition and next action

One non-neural harmonizer DSP component; empty backend/runtime/model arrays.
Investigate Linux CPU source packaging and MIDI/multi-output behavior. All campaign
validation stages were not run.
