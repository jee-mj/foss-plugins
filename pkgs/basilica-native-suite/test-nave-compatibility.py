"""Exercise the retained patch against pinned source, then compile its calls."""
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path

upstream, patch, juce, output = map(Path, __import__('sys').argv[1:])
original = (upstream/'src/PluginProcessor.cpp').read_text()
Path('src').mkdir()
Path('src/PluginProcessor.cpp').write_text(original)
subprocess.run(['patch','--batch','--fuzz=0','-p1','-i',str(patch)],check=True)
modified = Path('src/PluginProcessor.cpp').read_text()
expected = original.replace('#include <limits>','#include <algorithm>\n#include <limits>')
assert original.count('juce::jmin<juce::int64>') == 2
expected = expected.replace('juce::jmin<juce::int64>','std::min<juce::int64>')
assert modified == expected, 'patch changed more than the two scalar calls and include'
calls = re.findall(r'const auto numSamples = static_cast<int> \((.*?)\);',modified,re.S)
assert len(calls) == 2
assert calls[0] == calls[1]
scalar = calls[0].replace('reader->lengthInSamples','length')
template = '''
#include <juce_dsp/juce_dsp.h>
#include <juce_audio_formats/juce_audio_formats.h>
#include <algorithm>
#include <limits>
#include <type_traits>
using I = juce::int64;
static_assert (JUCE_USE_SIMD);
static_assert (std::is_same_v<I, decltype(juce::AudioFormatReader::lengthInSamples)>);
constexpr I low = std::numeric_limits<I>::min();
constexpr I high = std::numeric_limits<I>::max();
constexpr I cap = std::numeric_limits<int>::max();
constexpr I scalarMinimum(I a, I b) { return std::min<juce::int64>(a,b); }
struct Case { I a, b, expected; };
constexpr Case cases[] = {
  {low,high,low}, {high,low,low}, {low,low,low}, {high,high,high},
  {0,0,0}, {0,high,0}, {high,0,0}, {-1,0,-1}, {0,-1,-1},
  {-9,-3,-9}, {-3,-9,-9}, {-7,-7,-7}, {cap,high,cap}, {high,cap,cap}
};
constexpr bool boundaries() {
  for (auto c : cases) {
    if (scalarMinimum(c.a,c.b) != c.expected) return false;
    if (scalarMinimum(c.a,c.b) != juce::jmin(c.a,c.b)) return false;
  }
  return true;
}
static_assert(boundaries());
constexpr int sourceCall(I length) { return static_cast<int>(SOURCE_CALL); }
static_assert(sourceCall(0)==0);
static_assert(sourceCall(-1)==-1);
static_assert(sourceCall(1)==1);
static_assert(sourceCall(cap)==cap);
static_assert(sourceCall(cap+1)==cap);
static_assert(sourceCall(high)==cap);
int main() { return boundaries() ? 0 : 1; }
'''.replace('SOURCE_CALL',scalar)
Path('boundaries.cpp').write_text(template)
command = [os.environ['CXX'],'-std=c++20','-DNDEBUG','-DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1',
           '-DJUCE_STANDALONE_APPLICATION=1','-I'+str(juce/'modules')]
# Actual JUCE headers prove the source calls, SIMD state and scalar equivalence
# at compile time. Linking JUCE would require its module debug-mode sentinel;
# run the same arithmetic separately with the already-proven native scalar type.
subprocess.run(command+['-c','boundaries.cpp','-o','boundaries.o'],check=True)
runtime = template.replace('#include <juce_dsp/juce_dsp.h>','').replace('#include <juce_audio_formats/juce_audio_formats.h>','')
runtime = runtime.replace('static_assert (JUCE_USE_SIMD);','')
runtime = runtime.replace('static_assert (std::is_same_v<I, decltype(juce::AudioFormatReader::lengthInSamples)>);','')
runtime = runtime.replace('juce::int64','long long').replace('juce::jmin(c.a,c.b)','(c.b < c.a ? c.b : c.a)')
Path('runtime.cpp').write_text(runtime)
subprocess.run([os.environ['CXX'],'-std=c++20','runtime.cpp','-o','boundaries'],check=True)
subprocess.run(['./boundaries'],check=True)
output.mkdir()
receipt = dict(sourceRevision='aba56a4c15dbb5ae2edab38f9a47826ee7091ee1',
               patchSha256=hashlib.sha256(patch.read_bytes()).hexdigest(),
               originalSha256=hashlib.sha256(original.encode()).hexdigest(),
               modifiedSha256=hashlib.sha256(modified.encode()).hexdigest(),
               patchedCalls=2,operandType='juce::int64 (signed long long)',simdEnabled=True,
               scalarBoundaryCases=14,sourceClampCases=6,compileExitCode=0,runtimeExitCode=0,
               checks=['zero-fuzz patch application','exact minimal source delta','both actual source calls',
                       'signed minimum/zero/maximum/negative/ties','deduced JUCE scalar equivalence'])
(output/'verification.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(receipt,indent=2))
