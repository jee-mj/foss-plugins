# Dependency notice provenance

All compiled project dependencies other than SDL2 are the exact vendored source
bytes in 0xFX commit `5b248779c96dce6e64d0ed29cfa598014dc4d3c4`.
Independent historical revisions are not invented for those copies.

`vendored-sources/` preserves the full vendored files and embedded notices:
CPLUG (MIT/public-domain choice), its CLAP header (MIT), VST3 C API and wrapper
(Steinberg SDK notices; upstream documents the GPLv3 route), Dear ImGui (MIT),
cJSON (MIT), KissFFT (BSD-3-Clause), dr_wav (MIT/public domain), miniaudio
(MIT/public domain), nativefiledialog-extended (zlib), Shine (LGPL), and
stb_image (MIT/public domain). See each original file for its complete terms.
`COPYING3` also supplies the complete GPLv3 text; `COPYING.RUNTIME` retains
the GCC Runtime Library Exception. GNU/MCF/MinGW notices are separate.

The vendored KissFFT files refer to a COPYING file absent from the 0xFX tree.
Supplemental `KissFFT-COPYING` and `LICENSE-KissFFT.txt` come from official
KissFFT 131.1.0 commit `8f47a67f595a6641c566087bf5277034be64f24d`.
The compiled KissFFT copy remains the parent-pinned copy, not a replacement.

Shine's vendored directory omits its upstream COPYING and README. Supplemental
`LICENSE-Shine.txt` and `Shine-README.md` come from official Shine 3.1.1 commit
`97f188efc3dc90315b79a2af1f477c0c18d85e82` (GNU Library GPL version 2 text).
This identifies notice provenance, not an independently verified version match
for the compiled vendored sources.

SDL2 2.30.12 is built from official source commit
`8236e01a9f758d15927624925c6043f84d8a261f`, replacing the vendored precompiled
archives/DLLs. Its zlib license is included. No SDL3 compatibility layer is used.
Windows API headers/import libraries come from the locked MinGW-w64 toolchain;
no proprietary SDK is fetched. NSIS is a native packaging tool, not a runtime.

The four bundled cabinet IRs retain their original README attributing zoyd's
public-domain musical-artifacts collection. This is upstream attribution, not
independent re-verification or a new download. Factory presets and PNG/icon
assets are parent-pinned project data. No neural-model assets are involved.
