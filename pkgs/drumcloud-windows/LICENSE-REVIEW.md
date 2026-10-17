# DrumCloud source build: licensing and assets

The pinned project's `LICENSE.txt` is a custom release-use permission notice.
It permits downloading, installing and using release contents. It reserves
DrumCloud-specific code, branding and artwork to the author and does not
establish a standard grant for source modification or redistribution of new
builds. This package is therefore marked `unfree` and uses the repository's
explicit unfree opt-in policy. This is a rights description, not a technical
build gate or a claim that source redistribution has been authorized.

`SendNoteExamplePlugin.cpp` retains an inherited ISC DPF notice naming Filipe
Coelho (2012-2024). That complete file is retained in the binary payload notices
as well as the corresponding source. This does not resolve the custom terms
for the complete project, its other files and its artwork.

DrumCloud's UI uses project-defined OpenGL pixel/stroke glyphs, not a separate
downloaded font. The original `UI/fuimadane_wave_bg.png` is retained in the
supplied source; the active `DrumCloudUI.cpp` does not load it. The generic
DPF/DGL source includes DejaVu Sans resources, NanoVG/fontstash/stb code and
their notices. These are conservatively retained without claiming every
resource is linked into the final plugin. No samples or external content are
downloaded or bundled; audio files are selected by the eventual user.

DPF and its travesty VST3 implementation use ISC licensing; CLAP headers use
MIT notices. Pugl's COPYING and the bundled dr_libs headers' embedded license
texts are retained. DGL resources and NanoVG source retain their embedded and
separate third-party notices. MinGW-w64 and statically linked GCC/thread runtime
notices, including runtime exceptions, are also retained. These dependency
licenses do not supply a missing grant for DrumCloud-specific work.

The NSIS script is operator-authored packaging, not an upstream installer.
The supplied source is the pinned upstream tree with its two gitlinks populated,
plus the packaging recipe. Runtime behavior has not been tested.
