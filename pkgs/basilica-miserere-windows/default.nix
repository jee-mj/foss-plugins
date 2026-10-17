{ lib, stdenv, pkgsCross, fetchFromGitHub, runCommand, python3, cmake, ninja
, pkg-config, alsa-lib, freetype, fontconfig, libGL, libx11, libxext, libxcursor
, libxinerama, libxrandr, repackSalt ? "" }:
let
  version = "0.7.0";
  revision = "6ce6cc2deb616f337622e36c747a292f505ea0b7";
  juceRevision = "2cdfca8feb300fb424002ba2c2751569e5bacb64";
  src = fetchFromGitHub {
    owner = "basilica-audio";
    repo = "Miserere";
    rev = revision;
    hash = "sha256-gzAKD2fO8DzPaFRBVOYq7Apj7haEBgrTl0qsUzTJXME=";
  };
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = juceRevision;
    hash = "sha256-oXFYfFqySW2XtM1e5/ifxAp9qSIVLzY1WAUKE3EscoQ=";
  };
  nativeJuceaide = stdenv.mkDerivation {
    pname = "miserere-native-juceaide";
    version = "8.0.14";
    src = juceSrc;
    nativeBuildInputs = [ cmake ninja pkg-config ];
    buildInputs = [ alsa-lib freetype fontconfig libGL libx11 libxext libxcursor libxinerama libxrandr ];
    cmakeFlags = [ "-DJUCE_BUILD_HELPER_TOOLS=ON" ];
    buildPhase = ''cmake --build . --target juceaide --parallel "$NIX_BUILD_CORES"'';
    installPhase = ''
      mkdir -p "$out/bin"
      cp extras/Build/juceaide/juceaide_artefacts/Release/juceaide "$out/bin/"
      "$out/bin/juceaide" version
    '';
    meta.license = lib.licenses.agpl3Only;
  };
  cross = pkgsCross.mingwW64;
  plugin = cross.stdenv.mkDerivation {
    pname = "basilica-miserere-windows-vst3";
    inherit version src;
    nativeBuildInputs = [ cmake ninja python3 ];
    dontStrip = true;
    enableParallelBuilding = true;
    postPatch = ''
      cp -r ${juceSrc} JUCE
      chmod -R u+w JUCE
      python ${./adapt.py} ${nativeJuceaide}/bin/juceaide
    '';
    preConfigure = ''
      cmakeFlagsArray+=(
        "-DCMAKE_SHARED_LINKER_FLAGS=-static -static-libgcc -static-libstdc++ -Wl,--no-insert-timestamp"
        "-DCMAKE_MODULE_LINKER_FLAGS=-static -static-libgcc -static-libstdc++ -Wl,--no-insert-timestamp"
      )
    '';
    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DCMAKE_CXX_FLAGS=-ffile-prefix-map=/build=."
    ];
    buildPhase = ''
      runHook preBuild
      cmake --build . --target Miserere_VST3 --parallel "$NIX_BUILD_CORES"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/VST3" "$out/Notices"
      cp -r Miserere_artefacts/Release/VST3/Miserere.vst3 "$out/VST3/"
      cp ../LICENSE "$out/Notices/LICENSE-Miserere"
      cp ../JUCE/LICENSE.md "$out/Notices/LICENSE-JUCE"
      cp ../resources/fonts/OFL-EBGaramond.txt "$out/Notices/"
      cp ${cross.windows.mcfgthreads.src}/LICENSE.TXT "$out/Notices/LICENSE-MCF-Gthread"
      cp -r ${cross.windows.mcfgthreads.src}/licenses "$out/Notices/GNU-runtime-licenses"
      mkdir mingw-notices
      tar -xf ${cross.windows.mingw_w64.src} -C mingw-notices --strip-components=1 \
        mingw-w64-v${cross.windows.mingw_w64.version}/COPYING \
        mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64 \
        mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64-runtime \
        mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER \
        mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER.PD
      cp -r mingw-notices "$out/Notices/MinGW-w64"
      cat > "$out/Notices/BUILD-INFO.txt" <<'EOF'
      Basilica Miserere ${version}; AUDIO-003/miserere, repository alias BA-013
      Source: https://github.com/basilica-audio/Miserere/tree/${revision}
      JUCE 8.0.14: https://github.com/juce-framework/JUCE/tree/${juceRevision}
      Compiler: MinGW-w64 GCC ${cross.stdenv.cc.version}; binutils ${cross.stdenv.cc.bintools.version}
      Headers/runtime: MinGW-w64 ${cross.windows.mingw_w64.version}; MCF Gthread ${cross.windows.mcfgthreads.version}
      Linux native juceaide built from the identical JUCE source; no Windows code executed.
      Modified build graph 2026-10-17: pinned offline providers, native helper import,
      VST3-only, tests/manifest execution and copy-after-build off, no Windows attrib,
      no LTO. DSP and GUI sources unchanged. Fonts embedded from public source assets.
      Miserere and JUCE: AGPL-3.0; EB Garamond: OFL-1.1 (retain included terms).
      JUCE's bundled third-party notices are retained in the accompanying JUCE source.
      Corresponding source and complete recipe accompany this manual ZIP in the source ZIP.
      This is an operator source cross-build, not an official release binary.
      Runtime/DAW behavior has not been tested; PE inspection is data-only.
      EOF
      runHook postInstall
    '';
    meta = {
      description = "Basilica Miserere Windows x86-64 VST3 source cross-build spike";
      license = [ lib.licenses.agpl3Only lib.licenses.ofl ];
      platforms = [ "x86_64-windows" ];
    };
  };
in runCommand "basilica-miserere-${version}-windows-x86_64" {
  nativeBuildInputs = [ python3 ];
  inherit repackSalt;
  passthru = { inherit plugin src juceSrc nativeJuceaide revision juceRevision; };
  meta = {
    description = "Manual-copy Windows VST3 ZIP and corresponding source for Basilica Miserere";
    license = [ lib.licenses.agpl3Only lib.licenses.ofl ];
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/source/packaging/pkgs/basilica-miserere-windows" "$out/source/packaging/tests"
  cp -r ${plugin} "$out/payload"
  cp -r ${src} "$out/source/upstream"
  cp -r ${juceSrc} "$out/source/JUCE"
  cp ${./default.nix} "$out/source/packaging/pkgs/basilica-miserere-windows/default.nix"
  cp ${./adapt.py} "$out/source/packaging/pkgs/basilica-miserere-windows/adapt.py"
  cp ${./package.py} "$out/source/packaging/pkgs/basilica-miserere-windows/package.py"
  cp ${./spike-flake.nix} "$out/source/packaging/pkgs/basilica-miserere-windows/spike-flake.nix"
  cp ${./spike-flake.nix} "$out/source/packaging/flake.nix"
  cp ${../../flake.lock} "$out/source/packaging/flake.lock"
  cp ${../../tests/basilica-miserere-windows.nix} "$out/source/packaging/tests/basilica-miserere-windows.nix"
  cp -r ${cross.windows.mcfgthreads.src} "$out/source/mcfgthreads"
  python ${./package.py} "$out/payload" "$out/basilica-miserere-${version}-windows-x86_64.zip"
  python ${./package.py} "$out/source" "$out/basilica-miserere-${version}-source.zip"
''
