# Modified source: Basilica Nave 0.5.0

Upstream: https://github.com/basilica-audio/Nave
Commit: `aba56a4c15dbb5ae2edab38f9a47826ee7091ee1` (unchanged source archive).
Downstream modification date: 2026-10-17. License remains AGPL-3.0.

`nave-scalar-minimum.patch` adds `<algorithm>` and replaces the two explicit
`juce::jmin<juce::int64>` calls in `src/PluginProcessor.cpp` (original lines 390
and 436) with `std::min<juce::int64>`. Both operands retain their signed
`juce::int64` type; the int upper cap, outer int conversion and nonpositive
guards are unchanged. No processing algorithm, GUI or SIMD guard is modified.

JUCE 8.0.14's explicit template argument makes its SIMD jmin candidate consider
`SIMDRegister<long long>` on Linux LP64. JUCE's signed SIMD specialization is
for `int64_t` (`long` here), while `juce::int64` is `long long`. Instantiation
of the SIMD candidate fails before scalar overload resolution completes.
The standard scalar minimum avoids that candidate and implements the same
`b < a ? b : a` signed comparison as JUCE's scalar minimum.

The original upstream notices are preserved under `upstream/`. This directory
retains the exact patch, this notice and modified `PluginProcessor.cpp`.
The separate CMake-only native graph adaptation remains documented by the
suite source recipe. The compatibility check applies the patch with zero fuzz,
asserts the exact source delta, compiles both source calls with real JUCE
headers and SIMD enabled, checks signed boundary values against deduced JUCE
scalar jmin at compile time, and runs the same scalar arithmetic separately
without linking or instantiating JUCE GUI/audio objects.
