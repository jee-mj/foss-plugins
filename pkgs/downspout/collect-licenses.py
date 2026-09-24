"""Collect pinned, applicable binary notices; never install source/header trees.

Arguments: pinned source root, destination directory, reviewed CC0 legal code.
Every extracted block checks a source anchor so a changed vendor notice fails
the build rather than silently producing an incomplete attribution payload.
"""

from pathlib import Path
import re
import shutil
import sys


source, destination, cc0 = map(Path, sys.argv[1:])
destination.mkdir(parents=True, exist_ok=True)


def read(path, *anchors):
    text = (source / path).read_text(encoding="utf-8")
    for anchor in anchors:
        if anchor not in text:
            raise ValueError(f"missing license anchor {anchor!r}: {path}")
    return text


def write(name, text):
    (destination / name).write_text(text.rstrip() + "\n", encoding="utf-8")


def copy(name, path, *anchors):
    write(name, read(path, *anchors))


def opening_comment(path, *anchors):
    text = read(path, *anchors)
    match = re.match(r"/\*.*?\*/", text, flags=re.S)
    if not match or any(anchor not in match.group() for anchor in anchors):
        raise ValueError(f"missing opening permission block: {path}")
    return match.group()


copy("Downspout-MIT.txt", "LICENSE", "Copyright (c) 2026 Danny Ayers", "Permission is hereby granted")
# Reuse pinned root MIT permission terms only where a compiled vendor header
# supplies its own copyright/MIT label but not the complete grant.
mit_grant = read("LICENSE", "Permission is hereby granted").split("Permission is hereby granted", 1)[1]
copy("Tuney-MIT.txt", "plugins/tuney-vst/docs/TUNEY-LICENSE.md", "Copyright (c) 2025 Tom Ritchford", "Permission is hereby granted")
copy("DPF-ISC.txt", "third_party/DPF/LICENSE", "Filipe Coelho", "Permission to use, copy")
copy("DPF-format-licenses.txt", "third_party/DPF/LICENSING.md", "travesty", "VST3")
copy("Pugl-ISC.txt", "third_party/DPF/dgl/src/pugl-upstream/COPYING", "David Robillard", "Permission to use, copy")
copy("NanoVG-zlib.txt", "third_party/DPF/dgl/src/nanovg/LICENSE.txt", "Mikko Mononen", "Altered source versions")
copy("DejaVuSans-font.txt", "third_party/DPF/dgl/src/resources/LICENSE-DejaVuSans.ttf.txt", "Bitstream Vera Fonts Copyright", "Arev Fonts Copyright", "Tavmjong Bah")

# The root DPF/Pugl grants above supply complete permissions. These scoped
# source headers retain the additional file-level authors and copyright dates.
dpf = "third_party/DPF/"
dpf_headers = [
    "cmake/DPF-plugin.cmake",
    "distrho/DistrhoPluginMain.cpp",
    "distrho/DistrhoUIMain.cpp",
    "distrho/src/DistrhoPluginVST3.cpp",
    "distrho/src/DistrhoUIVST3.cpp",
    "distrho/extra/ScopedPointer.hpp",
    "dgl/src/NanoVG.cpp",
]
parts = []
for name in dpf_headers:
    path = dpf + name
    text = read(path, "Copyright")
    if name.endswith(".cmake"):
        block = text.split("\n\n", 1)[0]
        if "Jean Pierre Cimalando" not in block or "SPDX-License-Identifier: ISC" not in block:
            raise ValueError(f"invalid DPF CMake notice: {path}")
    else:
        block = opening_comment(path, "Copyright", "Permission to use, copy")
    parts.append(f"{path}\n{block}")
# ScopedPointer's instantiated implementation has a second, independent ISC
# permission block after the opening DPF notice. Include it in full.
scoped = dpf + "distrho/extra/ScopedPointer.hpp"
scoped_source = read(scoped, "Copyright (C) 2013 Raw Material Software Ltd.")
raw_material = re.search(r"/\*\*\s+Copyright \(C\) 2013 Raw Material Software Ltd\..*?\*/", scoped_source, flags=re.S)
if not raw_material or "THE SOFTWARE IS PROVIDED \"AS IS\"" not in raw_material.group() or "PERFORMANCE\n   OF THIS SOFTWARE." not in raw_material.group():
    raise ValueError(f"missing complete embedded Raw Material ISC permission: {scoped}")
parts.append(f"{scoped} (embedded Raw Material Software ISC notice)\n{raw_material.group()}")
write("DPF-file-notices.txt", "\n\n".join(parts))

write("travesty-ISC.txt", opening_comment(dpf + "distrho/src/travesty/base.h", "travesty", "Copyright (C) 2021-2022 Filipe Coelho", "Permission to use, copy"))
pugl = dpf + "dgl/src/pugl-upstream/"
pugl_parts = []
for name in ["src/common.c", "src/internal.c", "src/x11.c", "src/x11_gl.c", "include/pugl/pugl.h"]:
    path = pugl + name
    block = read(path, "Copyright", "SPDX-License-Identifier: ISC").split("\n\n", 1)[0]
    pugl_parts.append(f"{path}\n{block}")
write("Pugl-file-notices.txt", "\n\n".join(pugl_parts))

nanovg = dpf + "dgl/src/nanovg/"
fontstash = read(nanovg + "fontstash.h", "Copyright (c) 2009-2013 Mikko Mononen", "Altered source versions")
write("fontstash-zlib.txt", fontstash.split("\n\n", 1)[0])
utf8_notice = "// Copyright (c) 2008-2010 Bjoern Hoehrmann <bjoern@hoehrmann.de>\n// See http://bjoern.hoehrmann.de/utf-8/decoder/dfa/ for details."
if utf8_notice not in fontstash or "static unsigned int fons__decutf8(" not in fontstash:
    raise ValueError("missing compiled Hoehrmann UTF-8 decoder and notice")
# The referenced decoder page gives this code the MIT grant; preserve the
# pinned fontstash copyright year and pair it with full pinned MIT terms.
write("fontstash-UTF8-MIT.txt", utf8_notice + "\n\nPermission is hereby granted" + mit_grant)
image = read(nanovg + "stb_image.h", "stb_image - v2.10", "perpetual, irrevocable license")
image_grant = image.split("LICENSE\n\nThis software is in the public domain.", 1)[1].split("*/", 1)[0]
write("stb_image-public-domain.txt", "stb_image - v2.10\nLICENSE\n\nThis software is in the public domain." + image_grant)
truetype = read(nanovg + "stb_truetype.h", "This software is available under 2 licenses", "Copyright (c) 2017 Sean Barrett")
truetype_grant = truetype.split("/*\n------------------------------------------------------------------------------\nThis software is available under 2 licenses", 1)[1].split("*/", 1)[0]
write("stb_truetype-MIT.txt", "MIT alternative A elected for redistribution.\n/*\n------------------------------------------------------------------------------\nThis software is available under 2 licenses" + truetype_grant + "*/")
write("libSOFD-MIT.txt", opening_comment(dpf + "distrho/extra/sofd/libsofd.c", "Robin Gareus", "Permission is hereby granted"))

# The vendored single-header libraries have SPDX/MIT labels rather than the
# complete MIT grant. Reuse the complete permission terms from pinned root MIT
# with each header's independently verified copyright and contributor notices.
http = read("third_party/cpp-httplib/httplib.h", "Copyright (c) 2026 Yuji Hirose", "MIT License")
write("cpp-httplib-MIT.txt", "cpp-httplib 0.53.1\n" + http.split("\n", 8)[3].strip() + "\n\nPermission is hereby granted" + mit_grant)
json = read("third_party/nlohmann/json.hpp", "2013-2026 Niels Lohmann", "2016-2021 Evan Nemerson", "Björn Hoehrmann", "2009 Florian Loitsch", "2018 The Abseil Authors")
notices = [
    "SPDX-FileCopyrightText: 2013-2026 Niels Lohmann",
    "SPDX-FileCopyrightText: 2016-2021 Evan Nemerson",
    "SPDX-FileCopyrightText: 2008, 2009 Björn Hoehrmann",
    "SPDX-FileCopyrightText: 2009 Florian Loitsch",
    "The code is distributed under the MIT license, Copyright (c) 2009 Florian Loitsch.",
    "SPDX-FileCopyrightText: 2018 The Abseil Authors",
    "SPDX-License-Identifier: MIT AND Apache-2.0",
]
for notice in notices:
    if notice not in json:
        raise ValueError(f"missing JSON embedded notice: {notice}")
write("nlohmann-json-MIT.txt", "JSON for Modern C++ 3.12.0\n" + "\n".join(notices) + "\n\nMIT permission for the compiled JSON code and MIT contributors:\nPermission is hereby granted" + mit_grant + "\nThe Abseil Apache-2.0 fallback is inside #else JSON_HAS_CPP_14; C++20 selects standard utilities. No Abseil fallback code or full header is installed.\n")
hedley = "Created by Evan Nemerson <evan@nemerson.com>"
if hedley not in json or "SPDX-License-Identifier: CC0-1.0" not in json:
    raise ValueError("missing Hedley CC0 notice")
write("nlohmann-Hedley-CC0.txt", hedley + "\nSPDX-FileCopyrightText: 2016-2021 Evan Nemerson <evan@nemerson.com>\nSPDX-License-Identifier: CC0-1.0\nSee CC0-1.0.txt for the full waiver and public-license fallback.\n")
cc0_text = cc0.read_text(encoding="utf-8")
if "CC0 1.0 Universal" not in cc0_text or "3. Public License Fallback." not in cc0_text:
    raise ValueError("missing CC0 full legal code")
shutil.copyfile(cc0, destination / "CC0-1.0.txt")
