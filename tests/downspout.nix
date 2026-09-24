{ runCommand, packageSet }:

assert packageSet.freePackages ? downspout;
assert packageSet.freePackages.downspout.pname == "downspout";
assert packageSet.freePackages.downspout.version == "0.16.2";
runCommand "foss-plugins-downspout-registration" {
  downspout = packageSet.freePackages.downspout;
} ''
  count=0
  for bundle in "$downspout"/lib/vst3/*.vst3; do
    test -d "$bundle"
    name="''${bundle##*/}"
    name="''${name%.vst3}"
    test -s "$bundle/Contents/x86_64-linux/$name.so"
    count=$((count + 1))
  done
  test "$count" -eq 46
  test ! -e "$downspout/bin"
  test ! -e "$downspout/lib/clap"
  test ! -e "$downspout/lib/lv2"

  notices="$downspout/share/licenses/downspout"
  for name in Downspout-MIT Tuney-MIT DPF-ISC DPF-format-licenses \
    DPF-file-notices travesty-ISC Pugl-ISC Pugl-file-notices \
    NanoVG-zlib fontstash-zlib fontstash-UTF8-MIT stb_image-public-domain stb_truetype-MIT \
    DejaVuSans-font libSOFD-MIT cpp-httplib-MIT nlohmann-json-MIT \
    nlohmann-Hedley-CC0 CC0-1.0; do
    test -s "$notices/$name.txt"
  done
  test "$(ls -1 "$notices" | wc -l)" -eq 19
  grep -Fq 'Copyright (c) 2026 Danny Ayers' "$notices/Downspout-MIT.txt"
  grep -Fq 'Copyright (c) 2025 Tom Ritchford' "$notices/Tuney-MIT.txt"
  grep -Fq 'Permission to use, copy, modify' "$notices/DPF-ISC.txt"
  grep -Fq 'travesty' "$notices/DPF-format-licenses.txt"
  grep -Fq 'Jean Pierre Cimalando' "$notices/DPF-file-notices.txt"
  grep -Fq 'Copyright (C) 2013 Raw Material Software Ltd.' "$notices/DPF-file-notices.txt"
  grep -Fq 'ISC DISCLAIMS ALL WARRANTIES' "$notices/DPF-file-notices.txt"
  grep -Fq 'Permission to use, copy' "$notices/travesty-ISC.txt"
  grep -Fq 'David Robillard' "$notices/Pugl-ISC.txt"
  grep -Fq 'Robin Gareus' "$notices/Pugl-file-notices.txt"
  grep -Fq 'Copyright (c) 2013 Mikko Mononen' "$notices/NanoVG-zlib.txt"
  grep -Fq 'Altered source versions' "$notices/fontstash-zlib.txt"
  grep -Fq 'Copyright (c) 2008-2010 Bjoern Hoehrmann' "$notices/fontstash-UTF8-MIT.txt"
  grep -Fq 'Permission is hereby granted' "$notices/fontstash-UTF8-MIT.txt"
  grep -Fq 'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE' "$notices/fontstash-UTF8-MIT.txt"
  grep -Fq 'perpetual, irrevocable license' "$notices/stb_image-public-domain.txt"
  grep -Fq 'Copyright (c) 2017 Sean Barrett' "$notices/stb_truetype-MIT.txt"
  grep -Fq 'Arev Fonts Copyright' "$notices/DejaVuSans-font.txt"
  grep -Fq 'Font Software may be sold as part of a larger software package' "$notices/DejaVuSans-font.txt"
  grep -Fq 'Copyright (C) 2014 Robin Gareus' "$notices/libSOFD-MIT.txt"
  grep -Fq 'Copyright (c) 2026 Yuji Hirose' "$notices/cpp-httplib-MIT.txt"
  grep -Fq 'Björn Hoehrmann' "$notices/nlohmann-json-MIT.txt"
  grep -Fq 'Florian Loitsch' "$notices/nlohmann-json-MIT.txt"
  grep -Fq 'MIT AND Apache-2.0' "$notices/nlohmann-json-MIT.txt"
  grep -Fq 'Evan Nemerson' "$notices/nlohmann-Hedley-CC0.txt"
  grep -Fq 'SPDX-License-Identifier: CC0-1.0' "$notices/nlohmann-Hedley-CC0.txt"
  grep -Fq '3. Public License Fallback.' "$notices/CC0-1.0.txt"
  grep -Fq 'Permission is hereby granted' "$notices/nlohmann-json-MIT.txt"
  touch "$out"
''
