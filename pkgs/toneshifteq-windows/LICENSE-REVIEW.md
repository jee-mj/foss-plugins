# ToneShiftEQ Windows source build

ToneShiftEQ is BSD-3-Clause; libxputty is 0BSD, AudioFFT MIT, travesty ISC,
NanoSVG zlib, stb_truetype MIT/public domain, and the embedded Roboto font
Apache-2.0. Preserve the complete public source notices, including xdgmime's
AFL-2.0 alternative (selected here). b64_encode.c has no file-local grant;
the enclosing libxputty declaration is retained, not treated as a legal audit.

Cairo/pixman/zlib/libpng and the GNU/MinGW runtimes have their own notices.
Libsndfile is LGPL-2.1-or-later. Corresponding public source, build objects and
static libraries for relinking accompany the source output. The manual ZIP
and operator installer must be distributed with that corresponding-source
output. This is an operator cross-build, not an official upstream binary.

Only Windows system DLLs may be external dependencies. Optional compressed
libsndfile codecs are disabled; built-in WAV/AIFF IR support remains enabled.
Windows LV2 and standalone are explicitly unsupported upstream.
