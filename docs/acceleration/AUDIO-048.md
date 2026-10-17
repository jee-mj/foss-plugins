# AUDIO-048 — OpenVoxTuner and OpenVoxKey

- Repository: `EiffelBS/OpenVoxTuner`
- Inspected revision: `633fcf1ed106898cfa868fb792e392bc513777b1` (official GitHub API full commit, pinned tree/contents).
- Assessment: **complete / none / not-applicable**. Pitch correction is not automatically neural inference.

## Product/component findings

- `openvox-tuner`: instantiated YIN pitch detector, conventional scale/chord correction, overlapping-grain pitch shifting, harmony and formant DSP. Its “Reserved” detector slot is not an implemented neural provider.
- `openvox-key`: separately configured companion effect; transparently passes audio, uses YIN/key analysis and publishes key data through KeyBridge.
- Bundled `ovtchord` recognition scores explicit pitch-class chord templates. Its background worker is not proof of NN inference or an external service.

Pinned official upstream assessment evidence, revision above:

- [CMakeLists.txt](https://github.com/EiffelBS/OpenVoxTuner/blob/633fcf1ed106898cfa868fb792e392bc513777b1/CMakeLists.txt): VST3/Standalone tuner, separate VST3 companion, optional macOS formats, JUCE, eiffelbs-ui tag v0.4.2 and local ovtchord; no NN framework/provider dependency in inspected target lists.
- [PluginProcessor.cpp](https://github.com/EiffelBS/OpenVoxTuner/blob/633fcf1ed106898cfa868fb792e392bc513777b1/Source/PluginProcessor.cpp): detector choices “YIN”, “Reserved”; constructor actually instantiates YIN for main and sidechain, then shifter, quantizer and harmony modules.
- [YinPitchDetector.cpp](https://github.com/EiffelBS/OpenVoxTuner/blob/633fcf1ed106898cfa868fb792e392bc513777b1/Source/dsp/YinPitchDetector.cpp): lag differences, cumulative normalization, thresholding, octave correction and interpolation.
- [PitchShifter.cpp](https://github.com/EiffelBS/OpenVoxTuner/blob/633fcf1ed106898cfa868fb792e392bc513777b1/Source/dsp/PitchShifter.cpp): ring storage, overlapping grains and Kaiser-window OLA normalization, not model inference.
- [OpenVoxKeyProcessor.cpp](https://github.com/EiffelBS/OpenVoxTuner/blob/633fcf1ed106898cfa868fb792e392bc513777b1/Source/companion/OpenVoxKeyProcessor.cpp): constructs YIN, prepares downsampled analysis and publishes key while keeping audio transparent.
- [chord_engine.cpp](https://github.com/EiffelBS/OpenVoxTuner/blob/633fcf1ed106898cfa868fb792e392bc513777b1/libs/ovtchord/src/core/chord_engine.cpp): coverage/extra-note template scores and stable recognition state.

## Backend and platform disposition

Both products are non-neural DSP. Recorded Windows CPU tuples, architecture unknown, are `cpp-yin-granular-dsp` and `cpp-yin-key-analysis`, implemented/not-packaged. Unknown architecture intentionally avoids assigning the current source an architecture solely from an older installer. Native source declarations and ARA/format options do not validate native Linux/macOS support or Wine behavior. No CUDA/ROCm/DirectML/CoreML inference provider is established; no Wine GPU route is inferred from native Windows availability.

Package attributes/runtime IDs null; inference pins/model refs empty. Framework/dependency provenance must be locked before packaging; there are no acquired neural model bytes. License metadata is informational, not a gate.

## Validation / next action

All six stages **not-run** for both products. Reconcile current source with chosen release, resolve dependencies, build a CPU baseline, then validate companion routing, MIDI/ARA, state, latency and host behavior in each selected context. Any later AMD hardware model/provider/host stages remain `not-run-policy`; none ran here.
