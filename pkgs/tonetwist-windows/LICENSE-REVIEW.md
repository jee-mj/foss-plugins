# Public source notice review

Source revision: 5fac29094050eecf665479921e6ebbd3595b2281, brummer10/ToneTwistPlugs.
This records source statements; it does not invent a suite-wide license.
Redistribution classification is **conditional** pending clarification of the
mixed GPL version statements and any unmarked embedded assets/generated code.
This classification does not gate the technical source build.

- The six plugin wrappers, UI and info headers state literally
  `SPDX-License-Identifier: GPL-2.0 license`, Copyright (C) 2023 brummer.
  There is no root LICENSE file at this revision. Do not silently upgrade
  that ambiguous statement to GPL-3.0-or-later or assert an exception.
- zita-resampler headers/implementation: Fons Adriaensen, GPL-3.0-or-later.
  gx_resampler: Hermann Meyer, Andreas Degert, Pete Shorthose,
  GPL-2.0-or-later. ts9nonlin headers: Andreas Degert and Hermann Meyer,
  GPL-2.0-or-later. Full source headers and generated DSP are preserved.
- DPF and its travesty VST3 compatibility headers carry ISC grants.
  DPF LICENSING.md identifies CLAP as MIT, attributed to 2014-2022 Alexandre
  Bique, but its bundled CLAP headers do not contain the complete MIT grant.
  The separate LICENSE-CLAP supplies the complete attributed permission,
  retention condition and disclaimer in both payload notices and source.
  Pugl COPYING and DPF LICENSING.md are retained. No proprietary SDK is used.
- Cairo is LGPL-2.1-or-later OR MPL-1.1 according to its source COPYING;
  consult the preserved actual notices. Pixman is MIT-style, zlib uses
  the zlib license, and libpng preserves its public libpng notices.
  The exact pinned graphics source archives accompany the build recipe.
- MinGW-w64/winpthreads, MCF Gthread and GNU runtime licenses/exceptions
  are copied verbatim from the locked toolchain sources.

## CLAP notice provenance

LICENSE-CLAP is byte-identical to the verified notice used by the Wolf Shaper
and DrumCloud Windows packages, SHA-256
`50bf21def6095d5e50999675203ae1cd03a6333859bf5fa7c2238909b04dd7d3`.
The complete MIT grant and Copyright (c) 2021 Alexandre BIQUE were checked
against the public CLAP 1.0.0 LICENSE at full upstream commit
`84ad6fe9739d3070ed0eb05c24be303a899ab813`:
https://github.com/free-audio/clap/blob/84ad6fe9739d3070ed0eb05c24be303a899ab813/LICENSE
The notice additionally preserves DPF's 2014-2022 attribution from the pinned
DPF revision `29addec6f6e072162d0269fe8f1341b333c69e42`, LICENSING.md CLAP row.
This public text is vendored; building does not fetch another CLAP SDK.

Keep these notices and the accompanying corresponding source/build recipe
available with redistribution. The operator NSIS layer is separate from
upstream. NSIS's pinned Windows bootstrap/helper are supplied by nixpkgs,
not compiled from source by this package; their COPYING is included.
