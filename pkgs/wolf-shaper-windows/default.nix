{ lib, pkgsCross, fetchzip, runCommand, python3, nsis, repackSalt ? "" }:

let
  version = "1.0.2";
  revision = "4d7b6a1805d774fad553323bc9325c508428ac9e";
  dpfRevision = "d8c26737120cc36aacfb61c7c6b667eb6814e392";
  src = fetchzip {
    url = "https://github.com/wolf-plugins/wolf-shaper/releases/download/v${version}/wolf-shaper-v${version}-source.tar.gz";
    hash = "sha256-cE68kB8ui/VhoIe4hEH3bLG/Ken4az6jSdAnYhKmPm4=";
  };
  cross = pkgsCross.mingwW64;
  plugin = cross.stdenv.mkDerivation {
    pname = "wolf-shaper-windows-bundles";
    inherit version src;
    buildInputs = [ cross.windows.pthreads ];
    dontConfigure = true;
    dontStrip = true; # DPF strips at link time; do not treat these as Linux ELF.
    enableParallelBuilding = true;
    buildPhase = ''
      runHook preBuild
      flags=(CC="$CC" CXX="$CXX" AR="$AR" PKG_CONFIG=false
        CROSS_COMPILING=true WINDOWS=true
        DISTRHO_NAMESPACE=WolfShaperDISTRHO DGL_NAMESPACE=WolfShaperDGL
        FILE_BROWSER_DISABLED=true
        LDFLAGS=-Wl,--no-insert-timestamp)
      make -j"$NIX_BUILD_CORES" -C dpf/dgl opengl "''${flags[@]}"
      # Deliberately avoid top-level `gen`: it executes an LV2 generator.
      make -j"$NIX_BUILD_CORES" -C src vst3 clap "''${flags[@]}"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/VST3" "$out/CLAP" "$out/Notices"
      cp -r bin/wolf-shaper.vst3 "$out/VST3/"
      cp bin/wolf-shaper.clap "$out/CLAP/"
      cp LICENSE "$out/Notices/LICENSE-wolf-shaper"
      cp dpf/LICENSE "$out/Notices/LICENSE-DPF"
      cp dpf/LICENSING.md "$out/Notices/DPF-LICENSING.md"
      cp dpf/dgl/src/nanovg/LICENSE.txt "$out/Notices/LICENSE-NanoVG"
      cp dpf/dgl/src/resources/LICENSE-DejaVuSans.ttf.txt "$out/Notices/LICENSE-DejaVuSans"
      cp dpf/dgl/src/pugl-upstream/COPYING "$out/Notices/LICENSE-Pugl"
      cp "resources/fonts/Chivo/SIL Open Font License.txt" "$out/Notices/LICENSE-Chivo"
      cp ${./LICENSE-CLAP} "$out/Notices/LICENSE-CLAP"
      cp src/Utils/src/Mathf.cpp "$out/Notices/Mathf.cpp"
      cp ${cross.windows.mcfgthreads.src}/LICENSE.TXT "$out/Notices/LICENSE-MCF-Gthread"
      cp -r ${cross.windows.mcfgthreads.src}/licenses "$out/Notices/GNU-runtime-licenses"
      mkdir mingw-notices
      tar -xf ${cross.windows.mingw_w64.src} -C mingw-notices --strip-components=1 \
        mingw-w64-v${cross.windows.mingw_w64.version}/COPYING \
        mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64 \
        mingw-w64-v${cross.windows.mingw_w64.version}/COPYING.MinGW-w64-runtime \
        mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER \
        mingw-w64-v${cross.windows.mingw_w64.version}/DISCLAIMER.PD \
        mingw-w64-v${cross.windows.mingw_w64.version}/mingw-w64-libraries/winpthreads/COPYING
      cp -r mingw-notices "$out/Notices/MinGW-w64"
      # Preserve embedded third-party copyright/license headers, too.
      cp -r libs/DSPFilters/include "$out/Notices/DSPFilters-headers"
      cp -r dpf/distrho/src/clap "$out/Notices/CLAP-headers"
      cp -r dpf/dgl/src/nanovg "$out/Notices/NanoVG-source"
      cat > "$out/Notices/BUILD-INFO.txt" <<'EOF'
      Wolf Shaper ${version}, release v${version}
      Upstream commit: ${revision}
      DPF submodule commit: ${dpfRevision}
      Release source: https://github.com/wolf-plugins/wolf-shaper/releases/download/v${version}/wolf-shaper-v${version}-source.tar.gz
      Unpacked source NAR: sha256-cE68kB8ui/VhoIe4hEH3bLG/Ken4az6jSdAnYhKmPm4=
      GPL-3.0-or-later. Retain notices and provide corresponding source when redistributing.
      Compiler: MinGW-w64 GCC ${cross.stdenv.cc.version}, binutils ${cross.stdenv.cc.bintools.version}
      Windows headers/runtime: mingw-w64 ${cross.windows.mingw_w64.version}
      GCC threading implementation: MCF Gthread ${cross.windows.mcfgthreads.version}
      C++/GCC/pthread runtimes statically linked; Windows system DLLs and OpenGL required.
      VST3 uses DPF's ISC travesty implementation, not the proprietary Steinberg SDK.
      Chivo fonts, NanoVG and DSPFilters are embedded in the plugin.
      This is a source cross-build, not an upstream binary redistribution.
      EOF
      runHook postInstall
    '';
    meta = {
      description = "Wolf Shaper Windows x86-64 VST3 and CLAP source cross-build";
      homepage = "https://github.com/wolf-plugins/wolf-shaper";
      license = lib.licenses.gpl3Plus;
      platforms = [ "x86_64-windows" ];
    };
  };
in
runCommand "wolf-shaper-${version}-windows-x86_64" {
  outputs = [ "out" "installer" ];
  nativeBuildInputs = [ python3 nsis ];
  inherit repackSalt;
  passthru = { inherit plugin src revision dpfRevision; };
  meta = {
    description = "Manual-copy ZIP and operator-packaged NSIS installer for Wolf Shaper";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out" "$installer"
  cp -r ${plugin} "$out/payload"
  chmod -R u+w "$out/payload"
  # Include the exact source and packaging recipe beside the distributables.
  mkdir -p "$out/source"
  cp -r ${src} "$out/source/upstream"
  cp ${./default.nix} "$out/source/default.nix"
  cp ${./package.py} "$out/source/package.py"
  cp ${./installer.nsi} "$out/source/installer.nsi"
  cp ${./LICENSE-CLAP} "$out/source/LICENSE-CLAP"
  python ${./package.py} "$out/payload" "$out/wolf-shaper-${version}-windows-x86_64.zip"
  cp ${./installer.nsi} installer.nsi
  # NSIS preserves File timestamps: normalize them independently of store mtimes.
  cp -r "$out/payload" payload
  chmod -R u+w payload
  python ${./package.py} --normalize payload
  makensis -V3 -DOUTPUT="$installer/wolf-shaper-${version}-windows-x86_64-setup.exe" installer.nsi
  cp ${./installer.nsi} "$installer/installer.nsi"
  cp ${nsis.srcWinDistributable}/COPYING "$installer/NSIS-COPYING"
''
