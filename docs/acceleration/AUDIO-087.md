# AUDIO-087 — Wavelollies

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Pinned source: `a1exwang/wavelollies@05009e8fedcdb970ec31cae9bc668627d8b69dca`.

`Source/dsp.cpp` uses FFTW's real-to-complex API, windowing, spectral interpolation and conventional peak/pitch tracking. It dynamically resolves Windows FFTW DLL symbols or POSIX `libfftw3f.so` symbols. `SpectrogramComponent.cpp` hands FFT-derived bins to a spectrogram renderer with an OpenGL context. This is CPU spectral analysis plus graphics rendering, not neural inference or GPU FFT audio processing. Do not turn the OpenGL dependency into a CUDA/ROCm backend claim.

## Upstream assessment evidence

- [Actual FFTW DSP](https://github.com/a1exwang/wavelollies/blob/05009e8fedcdb970ec31cae9bc668627d8b69dca/Source/dsp.cpp)
- [Spectrogram/OpenGL implementation](https://github.com/a1exwang/wavelollies/blob/05009e8fedcdb970ec31cae9bc668627d8b69dca/Source/SpectrogramComponent.cpp)
- [CMake test targets](https://github.com/a1exwang/wavelollies/blob/05009e8fedcdb970ec31cae9bc668627d8b69dca/Source/CMakeLists.txt)

The inspected CMake file exposes DSP test executables, not a demonstrated complete Linux plugin build. Symbol-loading branches show source intent, not supported/validated platform artifacts. No neural backends/models are recorded. All campaign stages remain not-run, including graphics and host execution. No upstream test result is promoted.

Rights: preserve GPL-3.0 evidence; FFTW, JUCE and visualization dependencies retain separate obligations.

Next action: establish plugin exporter/build and FFTW runtime resolution per target OS; assess graphics compatibility separately from audio inference.
