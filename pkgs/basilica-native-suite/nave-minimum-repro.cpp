// Compile-only reproduction using the actual pinned JUCE headers.
#include <juce_dsp/juce_dsp.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <algorithm>
#include <cstdint>
#include <limits>
#include <type_traits>

static_assert (JUCE_USE_SIMD, "keep upstream SIMD enabled");
static_assert (std::is_same_v<juce::int64, long long>);
static_assert (std::is_same_v<int64_t, long>);
static_assert (!std::is_same_v<juce::int64, int64_t>);
static_assert (std::is_same_v<decltype (juce::AudioFormatReader::lengthInSamples), juce::int64>);

juce::int64 minimum (juce::int64 a, juce::int64 b)
{
#if MODE == 0
    return juce::jmin<juce::int64> (a, b);
#elif MODE == 1
    return juce::jmin (a, b);
#else
    return std::min<juce::int64> (a, b);
#endif
}
