{ lib, stdenv, pkgsCross, fetchFromGitHub, runCommand, python3, cmake, ninja
, pkg-config, alsa-lib, freetype, fontconfig, libGL, libx11, libxext, libxcursor
, libxinerama, libxrandr, nsis, repackSalt ? "" }:
let
  sources = import ./sources.nix { inherit fetchFromGitHub; };
  # Aggregate every source/license byte for these actually compiled modules.
  # The two-file representation bounds binary member count without losing notices.
  juceNoticeModules = [
    "juce_core" "juce_data_structures" "juce_events" "juce_graphics"
    "juce_gui_basics" "juce_gui_extra" "juce_audio_basics" "juce_audio_devices"
    "juce_audio_formats" "juce_audio_processors" "juce_audio_utils" "juce_dsp"
    "juce_audio_plugin_client"
  ];
  linuxInputs = [ alsa-lib freetype fontconfig libGL libx11 libxext libxcursor libxinerama libxrandr ];
  nativeJuceaide = stdenv.mkDerivation {
    pname = "gunk-native-juceaide";
    version = "7.0.12";
    src = sources.juce;
    nativeBuildInputs = [ cmake ninja pkg-config ];
    buildInputs = linuxInputs;
    cmakeFlags = [ "-DJUCE_BUILD_HELPER_TOOLS=ON" ];
    buildPhase = ''cmake --build . --target juceaide --parallel "$NIX_BUILD_CORES"'';
    installPhase = ''
      mkdir -p "$out/bin"
      cp extras/Build/juceaide/juceaide_artefacts/Release/juceaide "$out/bin/"
    '';
    meta.license = lib.licenses.gpl3Only;
  };
  cross = pkgsCross.mingwW64;
  mkPlugin = windows: (if windows then cross.stdenv else stdenv).mkDerivation {
    pname = "gunk-${if windows then "windows" else "linux"}-vst3-probe";
    version = "0.2.2";
    src = sources.upstream;
    nativeBuildInputs = [ cmake ninja pkg-config python3 ];
    buildInputs = lib.optionals (!windows) linuxInputs;
    dontStrip = windows;
    enableParallelBuilding = true;
    postPatch = ''
      mkdir -p deps
      cp -r ${sources.juce} deps/JUCE
      cp -r ${sources.q} deps/q
      cp -r ${sources.aubio} deps/aubio
      chmod -R u+w deps
      cp -r ${sources.infra}/. deps/q/infra/
      # Expose aubio's conventional installed header namespace from its source tree.
      mkdir -p deps/aubio/include
      ln -s ../src deps/aubio/include/aubio
      substituteInPlace CMakeLists.txt \
        --replace-fail 'SYSTEM PUBLIC "''${aubio_src_SOURCE_DIR}/src"' \
        'SYSTEM PUBLIC "''${aubio_src_SOURCE_DIR}/src" "''${aubio_src_SOURCE_DIR}/include"'
      # Non-LTO probe: Nix's plain ar lacks the GCC LTO plugin; the wrapper
      # does not expose gcc-ar. This changes optimization only, not source guards.
      substituteInPlace CMakeLists.txt \
        --replace-fail '$<$<CONFIG:Release>:juce::juce_recommended_lto_flags>' ""
      # Host tool import only. JUCE platform/compiler guards remain untouched.
      cat > deps/JUCE/extras/Build/juceaide/CMakeLists.txt <<'EOF'
      add_executable(juceaide IMPORTED GLOBAL)
      set_target_properties(juceaide PROPERTIES IMPORTED_LOCATION "${nativeJuceaide}/bin/juceaide")
      add_executable(juce::juceaide ALIAS juceaide)
      EOF
    '' + lib.optionalString windows ''
      # Replace Ubuntu-specific runtime paths with the Nix GCC runtime selection.
      substituteInPlace CMakeLists.txt \
        --replace-fail /usr/x86_64-w64-mingw32/lib/libwinpthread.a ""
      substituteInPlace cmake/vst3_manifest_wrapper.sh.in \
        --replace-fail '@CMAKE_SOURCE_DIR@/build/JQGunk_artefacts/RelWithDebInfo/VST3/JQ Gunk.vst3/Contents/Resources/moduleinfo.json' \
        '${nativePlugin}/VST3/JQ Gunk.vst3/Contents/Resources/moduleinfo.json'
      chmod +x cmake/vst3_manifest_wrapper.sh.in
      patchShebangs cmake/vst3_manifest_wrapper.sh.in
    '';
    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      "-DFETCHCONTENT_SOURCE_DIR_JUCE=../deps/JUCE"
      "-DFETCHCONTENT_SOURCE_DIR_CYCFI_Q=../deps/q"
      "-DFETCHCONTENT_SOURCE_DIR_AUBIO_SRC=../deps/aubio"
    ] ++ lib.optionals windows [
      "-DCMAKE_CXX_FLAGS=-I../cmake/include-fix"
      "-DCMAKE_SHARED_LINKER_FLAGS=-static"
      "-DCMAKE_MODULE_LINKER_FLAGS=-static"
    ];
    buildPhase = ''
      runHook preBuild
      cmake --build . --target JQGunk_VST3 --parallel "$NIX_BUILD_CORES"
      runHook postBuild
    '';
    installPhase = ''
      mkdir -p "$out/VST3"
      cp -r "JQGunk_artefacts/Release/VST3/JQ Gunk.vst3" "$out/VST3/"
    '';
    meta.license = lib.licenses.gpl3Plus;
  };
  nativePlugin = mkPlugin false;
  plugin = mkPlugin true;
in runCommand "gunk-windows-x86_64-source-probe" {
  nativeBuildInputs = [ python3 nsis ];
  outputs = [ "out" "installer" ];
  inherit repackSalt;
  passthru = { inherit sources nativeJuceaide nativePlugin plugin; };
  meta = {
    description = "Unexported JQ Gunk Windows source-build probe; see technical receipt";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/payload" "$out/source" "$out/payload/Notices"
  cp -r ${plugin}/. "$out/payload/"
  cp -r ${sources.upstream} "$out/source/upstream"
  cp ${sources.upstream}/LICENSE ${sources.upstream}/THIRD-PARTY-NOTICES "$out/payload/Notices/"
  cp ${sources.juce}/LICENSE.md "$out/payload/Notices/LICENSE-JUCE.md"
  python ${./collect_notices.py} ${sources.juce}/modules "$out/payload/Notices" \
    ${lib.concatStringsSep " " juceNoticeModules}
  cp ${./NOTICE-CLOSURE.md} "$out/payload/Notices/NOTICE-CLOSURE.md"
  cp ${sources.aubio}/COPYING "$out/payload/Notices/LICENSE-aubio"
  cp ${sources.q}/LICENSE "$out/payload/Notices/LICENSE-Q"
  cp ${sources.upstream}/Wavetables/Surge/NOTICE "$out/payload/Notices/SURGE-NOTICE"
  cp ${cross.windows.mcfgthreads.src}/LICENSE.TXT "$out/payload/Notices/LICENSE-MCF-Gthread"
  cp -r ${cross.windows.mcfgthreads.src}/licenses "$out/payload/Notices/GNU-runtime-licenses"
  mkdir mingw-notices
  tar -xf ${cross.windows.mingw_w64.src} -C mingw-notices --strip-components=1 \
    mingw-w64-v${cross.windows.mingw_w64.version}/COPYING \
    mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64 \
    mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64-runtime \
    mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER \
    mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER.PD
  cp -r mingw-notices "$out/payload/Notices/MinGW-w64"
  mkdir -p "$out/payload/AppData/JQGunk"
  cp -r ${sources.upstream}/Presets/Factory "$out/payload/AppData/JQGunk/Factory Presets"
  cp -r ${sources.upstream}/Wavetables "$out/payload/AppData/JQGunk/Wavetables"
  cp ${./INSTALL.txt} "$out/payload/INSTALL.txt"
  cat > "$out/payload/Notices/BUILD-INFO.txt" <<'EOF'
  JQ Gunk 0.2.2, operator source cross-build, Windows x86-64 VST3.
  Source: https://github.com/cemkod/gunk/tree/${sources.upstream.rev}
  JUCE 7.0.12: ${sources.juce.rev}; aubio 0.4.9: ${sources.aubio.rev}
  Cycfi Q: ${sources.q.rev} (master selected 2026-10-17, not historical provenance).
  Cycfi Infra: ${sources.infra.rev} (exact gitlink of selected Q).
  Compiler: MinGW-w64 GCC ${cross.stdenv.cc.version}; binutils ${cross.stdenv.cc.bintools.version}.
  MinGW-w64 ${cross.windows.mingw_w64.version}; MCF Gthread ${cross.windows.mcfgthreads.version}.
  Public Nix inputs fixed by the accompanying flake.lock; offline CMake dependencies.
  Build graph adapted 2026-10-17: native JUCE helper import, aubio installed-header
  namespace alias, LTO disabled, Ubuntu pthread path replaced by Nix static runtime,
  shell interpreter and native manifest path fixed. No DSP/GUI code or guards changed.
  Original upstream bundle target not used: Nix payload contains the complete JUCE
  bundle plus factory presets/wavetables, notices and corrected manual instructions.
  JUCE's native-generated moduleinfo.json is copied as upstream prescribes.
  Windows factory enumeration and DAW behavior have not been tested.
  GPL-3.0-or-later project/aubio and GPL-3.0 JUCE route; Q/Infra MIT;
  Surge wavetable attribution retained. Every byte from the 13 compiled JUCE
  module source/license trees accompanies BOTH binary ZIP and installer as a
  raw-byte notice stream plus reconstruction index, including embedded VST3 SDK
  BSD-3-Clause, libpng, IJG JPEG and zlib notices. Legal text remains contiguous.
  See NOTICE-CLOSURE.md. GNU/MinGW runtime terms are included here and in source.
  No Windows executable was run. PE inspection is data-only.
  EOF
  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: source: ''cp -r ${source} "$out/source/${name}"'') (builtins.removeAttrs sources [ "upstream" ]))}
  cp -r ${cross.windows.mcfgthreads.src} "$out/source/mcfgthreads"
  cp ${cross.windows.mingw_w64.src} "$out/source/mingw-w64-source.tar.bz2"
  cp ${cross.stdenv.cc.cc.src} "$out/source/gcc-source.tar.xz"
  cp ${../../flake.lock} "$out/source/flake.lock"
  mkdir -p "$out/source/packaging/pkgs/gunk-windows" "$out/source/packaging/tests"
  ${lib.concatStringsSep "\n" (map (name: ''cp ${./. + "/${name}"} "$out/source/packaging/pkgs/gunk-windows/${name}"'') [
    "default.nix" "sources.nix" "package.py" "INSTALL.txt" "installer.nsi" "spike-flake.nix"
    "check_installer.py" "collect_notices.py" "NOTICE-CLOSURE.md"
  ])}
  cp ${../../tests/gunk-windows.nix} "$out/source/packaging/tests/gunk-windows.nix"
  cp ${../../flake.lock} "$out/source/packaging/flake.lock"
  cp ${./spike-flake.nix} "$out/source/packaging/flake.nix"
  python ${./package.py} "$out/payload" "$out/gunk-windows-x86_64.zip"
  python ${./package.py} "$out/source" "$out/gunk-source.zip"
  mkdir -p "$installer"
  cp -r "$out/payload" payload
  # NSIS records file mtimes even though the manual ZIP writer does not.
  python - <<'PY'
  import os
  from pathlib import Path
  for path in Path('payload').rglob('*'):
      os.utime(path, (315532800, 315532800))
  PY
  makensis -NOCD -DOUTPUT="$installer/gunk-0.2.2-windows-x86_64-setup.exe" ${./installer.nsi}
''
