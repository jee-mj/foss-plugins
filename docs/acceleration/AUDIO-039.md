# AUDIO-039 — GuitarStrumSequencer

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `allenloves/GuitarStrumSequencer`, pinned `442a4e31a3fac0e2e3bd970082ff7269266eec05`; official commits/tree/contents APIs inspected.

One application component: MIDI strum sequencing, not a sampled or neural guitar. `processBlock` clears audio, consumes MIDI/chord input, obtains sequencer steps and strum notes, schedules note-on/off events and swaps the output MIDI buffer. Humanization/voicing is algorithmic and does not imply inference. CMake declares AU/VST3/Standalone and JUCE audio_utils/audio_processors, without an inference/GPU dependency. The sequencer requires a separate instrument and host MIDI routing; Windows source/native Windows and Wine acceptance are separate concerns.

Pinned upstream assessment evidence:
- [Actual MIDI scheduling callback](https://github.com/allenloves/GuitarStrumSequencer/blob/442a4e31a3fac0e2e3bd970082ff7269266eec05/Source/PluginProcessor.cpp)
- [Step scheduling](https://github.com/allenloves/GuitarStrumSequencer/blob/442a4e31a3fac0e2e3bd970082ff7269266eec05/Source/StepSequencer.cpp)
- [Build formats and dependencies](https://github.com/allenloves/GuitarStrumSequencer/blob/442a4e31a3fac0e2e3bd970082ff7269266eec05/CMakeLists.txt)

Backends empty. Next action: establish the pinned CPU build/artifact contract and separately verify Windows/Wine MIDI output, transport, instrument routing and state recall; investigate Linux source portability independently. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. Existing MIT source versus distributed JUCE binary licensing scope is preserved and informational, not a technical gate.
