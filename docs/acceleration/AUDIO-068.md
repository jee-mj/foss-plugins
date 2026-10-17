# AUDIO-068 — Vaporizer2

Assessment date: 2026-10-17. Repository: `VASTDynamics/Vaporizer2`.
Pinned source: `1c56c4be304255f1c397dad725ea784f15a55ef5`; official GitHub commit/tree/contents API inspection.

## Outcome

**complete; ai_role: none; execution_mode: not-applicable.** Component `vaporizer2` covers the hybrid instrument/sampler and its internal FX. The inspected callback dispatches to a conventional polyphonic oscillator/sample engine and effects buses. No separate neural product/backend was found in that route.

## Pinned implementation evidence

- [VASTAudioProcessor.cpp](https://github.com/VASTDynamics/Vaporizer2/blob/1c56c4be304255f1c397dad725ea784f15a55ef5/VASTvaporizer/Source/Plugin/VASTAudioProcessor.cpp): `processBlock` calls `m_pVASTXperience.processAudioBuffer`; the OpenGL oscilloscope reference writes a display ring buffer, not GPU synthesis.
- [VASTXperience.cpp](https://github.com/VASTDynamics/Vaporizer2/blob/1c56c4be304255f1c397dad725ea784f15a55ef5/VASTvaporizer/Source/Engine/VASTXperience.cpp): `processAudioBuffer` invokes polyphonic synthesis and FX bus processing.
- [VASTPoly.cpp](https://github.com/VASTDynamics/Vaporizer2/blob/1c56c4be304255f1c397dad725ea784f15a55ef5/VASTvaporizer/Source/Engine/VASTPoly.cpp): calls `m_OscillatorSynthesizer.renderNextBlock`.
- [CMakeLists.txt](https://github.com/VASTDynamics/Vaporizer2/blob/1c56c4be304255f1c397dad725ea784f15a55ef5/CMakeLists.txt): explicitly lists oscillator/filter/envelope/FX C++ files; selects FFTW3 and resolves Linux `fftw3f` through pkg-config. Optional AAX/VST2 paths are explicitly labelled non-FOSS.

## Integration and limits

Linux CPU backend `juce-fftw3f-cpp`, architecture unknown. No inference/GPU-audio provider selected by inspected build/runtime paths. CPU SIMD/FFTW and GUI OpenGL are not neural/GPU audio evidence. Integration `not-packaged` describes this campaign, independent of the catalog's existing consumer selection. Export/runtime ID null; pins/models empty pending actual packaging input reconciliation.

All six validation stages `not-run`. No AMD route asserted; future AMD GPU hardware model/provider/host stages remain `not-run-policy`. No Wine compatibility inferred.

Next: reconcile existing selection with the chosen source/release and dependency closure before CPU verification. Preserve GPL, fonts, sample content and optional SDK terms separately; none is silently relicensed by this assessment.
