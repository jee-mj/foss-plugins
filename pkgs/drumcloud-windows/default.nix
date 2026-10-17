{ lib, pkgsCross, fetchzip, runCommand, python3, nsis,
  repackSalt ? "", rebuildSalt ? "" }:
let
  version = "1.9.0-beta.8";
  revision = "294ed7fb3116f1f16c7430e5df7e1954349405c6";
  dpfRevision = "9959b7567b57e39b6573547f4281a879bbc23475";
  puglRevision = "5e2621d714ddf1cb0f86e852f8ba5dffe04aa3a3";
  pins = {
    drumcloud = {
      inherit revision;
      url = "https://github.com/Chmod666music/Fuimadane-DrumCloud/archive/${revision}.tar.gz";
      hash = "sha256-FCv0zrg30jyiPrsNfHtttoutWfI94UVaONx+85EvkKo=";
    };
    dpf = {
      revision = dpfRevision;
      url = "https://github.com/Chmod666music/DPF/archive/${dpfRevision}.tar.gz";
      hash = "sha256-+S2HN07emY+DUz2E+8K+KlIH1PFAiunp74YFHloZITk=";
    };
    pugl = {
      revision = puglRevision;
      url = "https://github.com/DISTRHO/pugl/archive/${puglRevision}.tar.gz";
      hash = "sha256-a13PBEn929aq6dNwVaLK1XHGebEJgxfDe4ADp/UB83g=";
    };
  };
  fetch = pin: fetchzip { inherit (pin) url hash; };
  upstream = fetch pins.drumcloud;
  dpf = fetch pins.dpf;
  pugl = fetch pins.pugl;
  src = runCommand "drumcloud-${version}-recursive-source" { } ''
    mkdir -p "$out"
    cp -r ${upstream}/. "$out/"
    chmod -R u+w "$out"
    cp -r ${dpf}/. "$out/DPF/"
    chmod -R u+w "$out/DPF"
    cp -r ${pugl}/. "$out/DPF/dgl/src/pugl-upstream/"
  '';
  cross = pkgsCross.mingwW64;
  python = python3.withPackages (p: [ p.pefile ]);
  plugin = cross.stdenv.mkDerivation {
    pname = "drumcloud-windows-bundles";
    inherit version src rebuildSalt;
    buildInputs = [ cross.windows.pthreads ];
    nativeBuildInputs = [ python ];
    dontConfigure = true;
    dontStrip = true;
    enableParallelBuilding = true;
    buildPhase = ''
      runHook preBuild
      flags=(CC="$CC" CXX="$CXX" AR="$AR" PKG_CONFIG=false
        CROSS_COMPILING=true WINDOWS=true USE_FILE_BROWSER=true
        LDFLAGS="-static -Wl,--no-insert-timestamp")
      make -j"$NIX_BUILD_CORES" -C DPF/dgl opengl "''${flags[@]}"
      make -j"$NIX_BUILD_CORES" clap vst3 "''${flags[@]}"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/CLAP" "$out/VST3" "$out/Notices"
      cp bin/d_drumcloud.clap "$out/CLAP/"
      cp -r bin/d_drumcloud.vst3 "$out/VST3/"
      cp LICENSE.txt "$out/Notices/LICENSE-DrumCloud.txt"
      cp SendNoteExamplePlugin.cpp "$out/Notices/SendNoteExamplePlugin.cpp"
      cp README.md BUILD.md CROSS_PLATFORM_TESTING.md RELEASE_NOTES.md "$out/Notices/"
      cp ${./LICENSE-REVIEW.md} "$out/Notices/LICENSE-REVIEW.md"
      cp DPF/LICENSE "$out/Notices/LICENSE-DPF"
      cp DPF/LICENSING.md "$out/Notices/DPF-LICENSING.md"
      cp DPF/dgl/src/pugl-upstream/COPYING "$out/Notices/LICENSE-Pugl"
      cp -r thirdparty/dr_libs "$out/Notices/dr_libs"
      cp -r DPF/distrho/src/clap "$out/Notices/CLAP-headers"
      cp ${./LICENSE-CLAP} "$out/Notices/LICENSE-CLAP"
      cp -r DPF/distrho/src/travesty "$out/Notices/travesty-headers"
      cp -r DPF/dgl/src/nanovg "$out/Notices/NanoVG-source"
      cp -r DPF/dgl/src/resources "$out/Notices/DGL-resources"
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
      cat > "$out/Notices/BUILD-INFO.txt" <<'EOF'
      DrumCloud ${version}; source cross-build, not upstream release binaries.
      Upstream: ${revision}
      Chmod666music/DPF: ${dpfRevision}
      DISTRHO/pugl: ${puglRevision}
      NAR hashes and immutable URLs: SOURCE-PINS.json.
      MinGW-w64 GCC ${cross.stdenv.cc.version}; binutils ${cross.stdenv.cc.bintools.version}.
      mingw-w64 ${cross.windows.mingw_w64.version}; MCF Gthread ${cross.windows.mcfgthreads.version}.
      GCC threading uses Nixpkgs' MCF implementation, not Ubuntu's POSIX variant.
      C++/GCC/thread runtimes statically linked; Windows system DLLs/OpenGL required.
      Native Windows file browser retained (USE_FILE_BROWSER=true).
      VST3 uses DPF ISC travesty headers, no external Steinberg SDK.
      UI glyphs are drawn directly; no project TTF/OTF font acquisition.
      Original PNG artwork retained in corresponding source; not a runtime resource.
      DGL resources/fonts and embedded third-party notices retained conservatively.
      Custom DrumCloud license: no verified standard modification/redistribution grant.
      Static PE checks do not establish DAW, audio, GUI or Wine runtime behavior.
      EOF
      printf '%s\n' '${builtins.toJSON pins}' > "$out/Notices/SOURCE-PINS.json"
      python ${./package.py} --imports "$out"
      runHook postInstall
    '';
    meta = {
      description = "DrumCloud Windows x86-64 CLAP/VST3 source cross-build";
      homepage = "https://github.com/Chmod666music/Fuimadane-DrumCloud";
      license = lib.licenses.unfree;
      platforms = [ "x86_64-windows" ];
    };
  };
in
runCommand "drumcloud-${version}-windows-x86_64" {
  outputs = [ "out" "installer" ];
  nativeBuildInputs = [ python nsis ];
  inherit repackSalt;
  passthru = { inherit plugin src pins version revision dpfRevision puglRevision; };
  meta = {
    description = "DrumCloud manual-copy ZIP and separate operator NSIS installer";
    homepage = "https://github.com/Chmod666music/Fuimadane-DrumCloud";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out" "$installer" "$out/source"
  cp -r ${plugin} "$out/payload"
  cp -r ${src} "$out/source/upstream"
  cp ${./default.nix} "$out/source/default.nix"
  cp ${./package.py} "$out/source/package.py"
  cp ${./installer.nsi} "$out/source/installer.nsi"
  cp ${./LICENSE-REVIEW.md} "$out/source/LICENSE-REVIEW.md"
  cp ${./LICENSE-CLAP} "$out/source/LICENSE-CLAP"
  python ${./package.py} "$out/payload" "$out/drumcloud-${version}-windows-x86_64.zip"
  cp -r "$out/payload" payload
  chmod -R u+w payload
  python ${./package.py} --normalize payload
  cp ${./installer.nsi} installer.nsi
  makensis -V3 -DOUTPUT="$installer/drumcloud-${version}-windows-x86_64-setup.exe" installer.nsi
  cp ${./installer.nsi} "$installer/installer.nsi"
  cp ${nsis.srcWinDistributable}/COPYING "$installer/NSIS-COPYING"
''
