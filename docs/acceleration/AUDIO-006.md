# AUDIO-006 — CleanVoice

Assessment date: 2026-10-17. Repository: `zenoxart/CleanVoice`.
Pinned source: `bc30063b6892392d758d37e1b4539ffb6d6fd33b`.

## Conclusion

**complete; ai_role none; execution_mode not-applicable.** The actual nine-stage
chain is conventional DSP. AI-assisted code authorship is not NN inference.
In particular, the Soothe-like resonance suppression computes STFT magnitudes,
smooths a spectral baseline and applies bounded per-bin gain reduction; it does
not execute a trained model.

## Pinned upstream evidence

- [CMakeLists.txt](https://github.com/zenoxart/CleanVoice/blob/bc30063b6892392d758d37e1b4539ffb6d6fd33b/CMakeLists.txt): JUCE audio-utils/DSP linkage and VST3/standalone, with AU on macOS; no ML framework.
- [PluginProcessor.cpp](https://github.com/zenoxart/CleanVoice/blob/bc30063b6892392d758d37e1b4539ffb6d6fd33b/Source/PluginProcessor.cpp): direct chain of Fairchild/vari-mu, RVox levelling, de-esser, multiband stages, air, saturation and Soothe processing.
- [Soothe.h](https://github.com/zenoxart/CleanVoice/blob/bc30063b6892392d758d37e1b4539ffb6d6fd33b/Source/Dsp/Soothe.h): 1024-point FFT, spectral smoothing, excess-over-baseline reduction, inverse FFT and overlap-add.
- [Compressors.h](https://github.com/zenoxart/CleanVoice/blob/bc30063b6892392d758d37e1b4539ffb6d6fd33b/Source/Dsp/Compressors.h): explicit envelope followers, threshold/ratio gain computers and conventional saturation.

`v1.1.0` resolves to this same source commit. Linux release naming supports a
native acquisition lead, not a verified payload or host result.

## Backend disposition and next action

One conventional vocal-chain component, no inference/GPU backend or model pins.
Inspect JUCE submodule provenance and establish the Linux CPU baseline. Do not
add CUDA/ROCm dependencies because of development-tool authorship claims.
All campaign validation stages were not run.
