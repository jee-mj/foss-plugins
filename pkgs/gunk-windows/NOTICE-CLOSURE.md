# Binary-distribution embedded notice closure

`JUCE-component-source-notices.txt` retains **every unmodified byte of all
2,026 pinned source/license files** from the 13 JUCE modules that have
translation units in this Windows build. Clear filename separators surround
each file's raw bytes. The legal text is present contiguously, not replaced by
links, names or digests. These notice materials accompany both the manual ZIP
and operator NSIS installer, independently of the corresponding-source ZIP.
The top-level `LICENSE-JUCE.md` alone does not cover the distinct licenses of
every embedded component.

`JUCE-component-source-index.json` records each relative path, zero-based byte
offset, byte length and SHA-256. Reading exactly that range reconstructs the
original file, including original line endings and any binary bytes; delimiter
text is not part of a record. Neither source content nor legal text is
transcoded. The stream is raw bytes despite its `.txt` suffix. The index also
reports source byte count and stream byte count. The format identifier is
`juce-component-source-notices-v1`.

This two-file binary representation replaces only the duplicated per-source
notice entries. All original source trees remain intact in `gunk-source.zip`.
The 2,026 source records are not 2,026 installed files. The manual ZIP has 224
members; the installer contains those 224 destination-mapped files plus its
single known helper. Checks enforce the 2,048-file collection bound and a
128 MiB maximum binary member size; actual sizes are reported in check JSON.

JUCE revision: `4f43011b96eb0636104cb3e433894cda98243626` (7.0.12).

Modules: juce_core, juce_data_structures, juce_events, juce_graphics,
juce_gui_basics, juce_gui_extra, juce_audio_basics, juce_audio_devices,
juce_audio_formats, juce_audio_processors, juce_audio_utils, juce_dsp,
juce_audio_plugin_client.

## Concrete assembled-code evidence

- `juce_audio_plugin_client/juce_audio_plugin_client_VST3.cpp` and
  `juce_audio_processors/format_types/juce_VST3Headers.h` assemble VST3 SDK
  sources. In particular, the latter includes `base/source/fstring.cpp`.
  Its full 2023 Steinberg copyright, BSD three conditions and warranty/liability
  disclaimer are retained contiguously under the record path
  `juce_audio_processors/format_types/VST3_SDK/base/source/fstring.cpp`.
  The SDK's other headers, implementation notices and LICENSE.txt records are
  retained as well; this is not a substitute attribution to the SDK's name.
- `juce_graphics/juce_graphics.cpp` assembles its PNG and JPEG loaders. Their
  bundled implementations and full notices remain under the record prefixes
  `juce_graphics/image_formats/pnglib/` (including LICENSE and png.h) and
  `juce_graphics/image_formats/jpglib/` (including the complete IJG README and
  per-file copyright notices). The JUCE modification note is retained too.
- `juce_core/juce_core.cpp` assembles compression code, and the PNG loader also
  uses zlib. All bundled zlib source headers and their complete notice/grant/
  disclaimer are retained under `juce_core/zip/zlib/`.
- Whole module contents also preserve other assembled implementation/header
  attributions and disclaimers without relying on a hand-selected list of
  component names. This includes JUCE graphics' font-handling sources and the
  plugin SDK extensions, audio-format and DSP implementation trees.

The module records include unused platform/optional-code branches too; retaining
these notices does not claim that every branch was linked into the Windows
plugin. The build disables optional FLAC/Ogg codecs and external curl/browser
features. Source guards and DSP/GUI implementation remain unmodified.

## Fonts, data and other dependencies

No font asset is bundled by the pinned Gunk source. The Windows build uses
JUCE's native Windows font handling (MinGW disables DirectWrite in upstream
JUCE code). Font-handling source notices remain with the graphics module;
system font files are not redistributed. The Linux native helper's external
FreeType library is not part of the Windows payload.

Surge wavetable attribution is retained both as `SURGE-NOTICE` and with the
AppData wavetable tree. The project, JUCE, aubio, Q and GNU/MinGW/MCF notices
elsewhere in this directory remain applicable. Q/Infra full corresponding
source, GCC/MinGW source archives and all build inputs remain in the separate
source archive.

## Verification and provenance

Tests reconstruct **every file and byte** of these 13 module trees from indexed
stream ranges and compare them to the immutable JUCE input and the intact
source archive tree. They verify record bounds/order/hashes and all license/
copyright/README file bytes, assert the complete Steinberg fstring BSD notice
clauses and contiguous full header, and retain full PNG/JPEG/zlib notices.
The ZIP check compares every payload member; static NSIS extraction verifies
the exact destination file set and contents, including these notice materials.

The manifest still comes from the actual Linux native plugin factory via
upstream's JUCE manifest helper, then is copied for the Windows bundle. The
VST SDK parser accepts its JSON5-style trailing commas. No Windows factory,
plugin or installer was executed.
