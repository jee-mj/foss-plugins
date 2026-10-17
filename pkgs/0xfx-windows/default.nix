{ lib, pkgsCross, fetchFromGitHub, runCommand, cmake, ninja, python3, nsis
, compileSalt ? "", repackSalt ? "" }:
let
  cross = pkgsCross.mingwW64;
  upstream = fetchFromGitHub {
    owner = "averagenative"; repo = "0xFX";
    rev = "5b248779c96dce6e64d0ed29cfa598014dc4d3c4";
    hash = "sha256-h5f9uGwn87hMHM4buEM/haAKiC65L5A0p15nTi6hNsc=";
  };
  sdl = fetchFromGitHub {
    owner = "libsdl-org"; repo = "SDL"; rev = "8236e01a9f758d15927624925c6043f84d8a261f";
    hash = "sha256-9f7V15p8Cso1TVxcd7bEFGO3C3oIhQikyLh4pWXLaiA=";
  };
  kissNotices = fetchFromGitHub {
    owner = "mborgerding"; repo = "kissfft"; rev = "8f47a67f595a6641c566087bf5277034be64f24d";
    hash = "sha256-ukikTVnmKomKXTo6zc+PhpZzEkzXN2imFwZOYlfR3Pk=";
  };
  shineNotices = fetchFromGitHub {
    owner = "toots"; repo = "shine"; rev = "97f188efc3dc90315b79a2af1f477c0c18d85e82";
    hash = "sha256-Dx/gBuH2lrIKS+bax7iPmMimcami5tt0DBFEiTH13Bo=";
  };
  compiled = cross.stdenv.mkDerivation {
    pname = "0xfx-windows-x86_64-source";
    version = "1.3.0-source";
    src = upstream;
    inherit compileSalt;
    nativeBuildInputs = [ cmake ninja python3 ];
    dontStrip = true;
    enableParallelBuilding = true;
    postPatch = ''
      # These upstream archives and DLLs must never enter the link graph.
      rm -rf deps/SDL2-2.30.12 deps/SDL2-aarch64-linux
      cp -r ${sdl} deps/SDL2-source
      chmod -R u+w deps/SDL2-source
      python ${./adapt.py}
    '';
    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DCMAKE_SYSTEM_PROCESSOR=x86_64"
      "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
      "-DSDL_SHARED=OFF" "-DSDL_STATIC=ON"
      "-DSDL_TEST=OFF" "-DSDL_TESTS=OFF"
      "-DSDL2_DISABLE_INSTALL=ON"
    ];
    buildPhase = ''
      runHook preBuild
      cmake --build . --target 0xfx_clap 0xfx_vst3 0xfx_gui 0xfx_standalone --parallel "$NIX_BUILD_CORES"
      runHook postBuild
    '';
    doCheck = false; # Cross-produced executables are never executed.
    installPhase = ''
      mkdir -p "$out/CLAP" "$out/VST3" "$out/GUI" "$out/Console" "$out/build-evidence"
      cp 0xFX.clap "$out/CLAP/"
      cp -r 0xFX.vst3 "$out/VST3/"
      cp 0xfx_gui.exe "$out/GUI/"
      cp 0xfx_standalone.exe "$out/Console/"
      cp CMakeCache.txt "$out/build-evidence/"
      for target in 0xfx_clap 0xfx_vst3 0xfx_gui 0xfx_standalone; do
        cp "CMakeFiles/$target.dir/link.txt" "$out/build-evidence/$target-link.txt"
      done
    '';
    meta.license = lib.licenses.mit;
  };
in runCommand "0xfx-windows-x86_64-source-probe" {
  nativeBuildInputs = [ python3 nsis ];
  inherit repackSalt;
  passthru = { inherit upstream sdl compiled; };
  meta = {
    description = "Unexported 0xFX Windows source cross-build probe";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/payload" "$out/source" "$out/installer"
  cp -r ${compiled}/CLAP ${compiled}/VST3 "$out/payload/"
  cp -r ${compiled}/build-evidence "$out/"
  mkdir -p "$out/payload/Applications"
  cp ${compiled}/GUI/0xfx_gui.exe ${compiled}/Console/0xfx_standalone.exe "$out/payload/Applications/"
  cp -r ${upstream} "$out/source/upstream"
  chmod -R u+w "$out/source/upstream"
  rm -rf "$out/source/upstream/deps/SDL2-2.30.12" "$out/source/upstream/deps/SDL2-aarch64-linux"
  # SDL's Android project contains internal symlinks; materialize those source files.
  cp -rL ${sdl} "$out/source/SDL2"
  cp ${cross.stdenv.cc.cc.src} "$out/source/gcc-source.tar.xz"
  cp ${cross.windows.mingw_w64.src} "$out/source/mingw-w64-source.tar.bz2"
  cp -r ${cross.windows.mcfgthreads.src} "$out/source/mcfgthreads"
  mkdir -p "$out/payload/Notices" "$out/payload/Applications/presets" "$out/payload/Applications/resources/ir"
  cp -r ${upstream}/presets/factory "$out/payload/Applications/presets/"
  cp -r ${upstream}/resources/ir/bundled "$out/payload/Applications/resources/ir/"
  cp ${upstream}/LICENSE ${upstream}/README.md "$out/payload/"
  cp ${sdl}/LICENSE.txt "$out/payload/Notices/LICENSE-SDL2.txt"
  cp ${kissNotices}/COPYING "$out/payload/Notices/KissFFT-COPYING"
  cp ${kissNotices}/LICENSES/BSD-3-Clause "$out/payload/Notices/LICENSE-KissFFT.txt"
  cp ${shineNotices}/COPYING "$out/payload/Notices/LICENSE-Shine.txt"
  cp ${shineNotices}/README.md "$out/payload/Notices/Shine-README.md"
  cp ${./NOTICE-PROVENANCE.md} "$out/payload/Notices/"
  mkdir gcc-notices
  tar -xf ${cross.stdenv.cc.cc.src} --strip-components=1 -C gcc-notices \
    gcc-${cross.stdenv.cc.version}/COPYING3 gcc-${cross.stdenv.cc.version}/COPYING.RUNTIME
  cp gcc-notices/* "$out/payload/Notices/"
  cp ${cross.windows.mcfgthreads.src}/LICENSE.TXT "$out/payload/Notices/LICENSE-MCF-Gthread.txt"
  cp -r ${cross.windows.mcfgthreads.src}/licenses "$out/payload/Notices/GNU-runtime-licenses"
  mkdir -p "$out/payload/Notices/MinGW-w64"
  tar -xf ${cross.windows.mingw_w64.src} --strip-components=1 -C "$out/payload/Notices/MinGW-w64" \
    mingw-w64-v${cross.windows.mingw_w64.version}/COPYING \
    mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64 \
    mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64-runtime \
    mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER \
    mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER.PD
  # Preserve all vendored headers/sources with embedded notices, not just filenames called LICENSE.
  cp -r "$out/source/upstream/deps" "$out/payload/Notices/vendored-sources"
  cp ${./INSTALL.txt} "$out/payload/INSTALL.txt"
  cat > "$out/payload/Notices/BUILD-INFO.txt" <<'EOF'
  Operator source cross-build: 0xFX ${upstream.rev}; CMake project/NSIS 1.3.0,
  plugin config 0.1.0 retained verbatim (not a claim of release 1.3.1).
  SDL2 2.30.12 (${sdl.rev}) rebuilt from source; upstream precompiled SDL inputs removed.
  GCC ${cross.stdenv.cc.version}; binutils ${cross.stdenv.cc.bintools.version};
  MinGW-w64 ${cross.windows.mingw_w64.version}; MCF Gthread ${cross.windows.mcfgthreads.version}.
  Vendored CPLUG/CLAP/VST3 C API, ImGui, cJSON, KissFFT, dr_wav, miniaudio,
  nativefiledialog-extended, Shine and stb_image pinned by the upstream tree.
  No proprietary SDK acquisition. Sources retain each dependency's complete notices.
  Bundled IR provenance is upstream's public-domain attribution, retained verbatim.
  Conventional DSP; no neural models, weights, firmware or inference runtime.
  Original NSIS stages GUI/plugins, not console. This operator installer explicitly
  stages Console separately. Data-only inspection; no Windows program executed.
  EOF
  mkdir -p "$out/source/packaging/pkgs/0xfx-windows" "$out/source/packaging/tests"
  ${lib.concatStringsSep "\n" (map (name: ''cp ${./. + "/${name}"} "$out/source/packaging/pkgs/0xfx-windows/${name}"'') [
    "default.nix" "adapt.py" "package.py" "verify.py" "check-archive.py" "INSTALL.txt" "installer.nsi" "NOTICE-PROVENANCE.md" "standalone-flake.nix"
  ])}
  cp ${../../tests/0xfx-windows.nix} "$out/source/packaging/tests/0xfx-windows.nix"
  cp ${../../flake.lock} "$out/source/packaging/flake.lock"
  cp ${./standalone-flake.nix} "$out/source/packaging/flake.nix"
  python ${./package.py} "$out/payload" "$out/0xfx-windows-x86_64.zip"
  python ${./package.py} "$out/source" "$out/0xfx-source.zip"
  cp -r "$out/payload" payload
  chmod -R u+w payload
  python - <<'PY'
  import os
  from pathlib import Path
  for p in Path('payload').rglob('*'):
      os.utime(p, (315532800, 315532800))
  PY
  makensis -NOCD -DOUTPUT="$out/installer/0xfx-1.3.0-source-x86_64-setup.exe" ${./installer.nsi}
''
