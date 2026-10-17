{ lib, pkgsCross, fetchzip, runCommand, python3, nsis, meson, ninja, pkg-config,
  repackSalt ? "" }:
let
  revision = "5fac29094050eecf665479921e6ebbd3595b2281";
  version = "unstable-5fac290";
  dpfRevision = "29addec6f6e072162d0269fe8f1341b333c69e42";
  puglRevision = "e33b2f6b0cea6d6263990aa9abe6a69fdfba5973";
  src = fetchzip {
    url = "https://github.com/brummer10/ToneTwistPlugs/archive/${revision}.tar.gz";
    hash = "sha256-YDnRTHKIjmeTxsT8oLt7N7OcGc+tIKDfJr+++cYFkV0=";
  };
  dpf = fetchzip {
    url = "https://github.com/DISTRHO/DPF/archive/${dpfRevision}.tar.gz";
    hash = "sha256-WleyOtcEfUNgbwBIvqrZcGwLhLOKDsxcqNCVKvjyst0=";
  };
  pugl = fetchzip {
    url = "https://github.com/DISTRHO/pugl/archive/${puglRevision}.tar.gz";
    hash = "sha256-MPbhlHTJGCPH7bdHaBQMMtXC//yxeuPrSstf8pd+uQo=";
  };
  cross = pkgsCross.mingwW64;
  pixman = cross.pixman.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or []) ++ [ "-Ddefault_library=static" ];
  });
  zlib = cross.zlib.override { shared = false; };
  libpng = (cross.libpng.override { inherit zlib; apngSupport = false; }).overrideAttrs (old: {
    configureFlags = (old.configureFlags or []) ++ [ "--disable-shared" "--enable-static" ];
  });
  # Minimal Cairo Win32/image/PNG closure. No Linux graphics stack or target probes.
  cairo = cross.stdenv.mkDerivation {
    pname = "tonetwist-cairo-windows-static";
    inherit (cross.cairo) version src;
    nativeBuildInputs = [ meson ninja pkg-config python3 ];
    buildInputs = [ pixman zlib libpng ];
    preConfigure = ''patchShebangs version.py'';
    mesonFlags = [
      "-Dauto_features=disabled" "-Dpng=enabled" "-Dzlib=enabled"
      "-Ddefault_library=static" "-Dtests=disabled" "-Dgtk_doc=false"
      "-Dglib=disabled" "-Dfreetype=disabled" "-Dfontconfig=disabled"
      "-Dxlib=disabled" "-Dxcb=disabled" "-Dspectre=disabled"
      "-Dsymbol-lookup=disabled" "-Dtee=disabled"
    ];
    dontStrip = true;
  };
  products = [ "MetalTone" "CollisionDrive" "Rumor" "TubeScreamer" "ValveCaster" "BoobTube" ];
  plugin = cross.stdenv.mkDerivation {
    pname = "tonetwist-windows-bundles";
    inherit version src;
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ cairo pixman zlib libpng cross.windows.pthreads ];
    dontConfigure = true;
    dontStrip = true;
    enableParallelBuilding = true;
    postUnpack = ''
      cp -r ${dpf}/. "$sourceRoot/dpf/"
      chmod -R u+w "$sourceRoot/dpf"
      cp -r ${pugl}/. "$sourceRoot/dpf/dgl/src/pugl-upstream/"
      chmod -R u+w "$sourceRoot"
    '';
    postPatch = ''
      patch -d dpf/dgl/src/pugl-upstream -p1 < pugl.patch
    '';
    buildPhase = ''
      runHook preBuild
      flags=(CC="$CC" CXX="$CXX" AR="$AR" PKG_CONFIG="pkg-config --static"
        CROSS_COMPILING=true WINDOWS=true HAVE_CAIRO=true HAVE_OPENGL=false
        HAVE_JACK=false USE_FILE_BROWSER=false
        BUILD_LV2=false BUILD_VST2=false BUILD_JACK=false BUILD_AU=false
        CFLAGS=-DCAIRO_WIN32_STATIC_BUILD CXXFLAGS=-DCAIRO_WIN32_STATIC_BUILD
        LDFLAGS="-static -Wl,--no-insert-timestamp")
      make -j"$NIX_BUILD_CORES" -C dpf/dgl cairo "''${flags[@]}"
      for product in ${lib.concatStringsSep " " products}; do
        make -j"$NIX_BUILD_CORES" -C "plugins/$product" vst3 clap "''${flags[@]}"
      done
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/VST3" "$out/CLAP" "$out/Notices"
      for product in ${lib.concatMapStringsSep " " lib.toLower products}; do
        cp -r "bin/$product.vst3" "$out/VST3/"
        cp "bin/$product.clap" "$out/CLAP/"
      done
      cp ${./LICENSE-REVIEW.md} "$out/Notices/LICENSE-REVIEW.md"
      cp dpf/LICENSE "$out/Notices/LICENSE-DPF"
      cp ${./LICENSE-CLAP} "$out/Notices/LICENSE-CLAP"
      cp dpf/LICENSING.md "$out/Notices/DPF-LICENSING.md"
      cp dpf/dgl/src/pugl-upstream/COPYING "$out/Notices/LICENSE-Pugl"
      # Preserve all public embedded notices, including generated DSP and images.
      cp -r plugins "$out/Notices/source-headers-and-assets"
      cp -r dpf/distrho/src/clap "$out/Notices/CLAP-headers"
      cp -r dpf/distrho/src/travesty "$out/Notices/travesty-headers"
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
      for dependency in cairo pixman zlib libpng; do
        mkdir -p "$out/Notices/$dependency"
      done
      tar -xf ${cairo.src} --strip-components=1 -C "$out/Notices/cairo" --wildcards '*/COPYING*'
      tar -xf ${pixman.src} --strip-components=1 -C "$out/Notices/pixman" --wildcards '*/COPYING*'
      tar -xf ${zlib.src} --strip-components=1 -C "$out/Notices/zlib" --wildcards '*/LICENSE*'
      tar -xf ${libpng.src} --strip-components=1 -C "$out/Notices/libpng" --wildcards '*/LICENSE*'
      cat > "$out/Notices/BUILD-INFO.txt" <<'EOF'
      ToneTwist source cross-build, six products, Windows x86-64 CLAP and VST3.
      Source: https://github.com/brummer10/ToneTwistPlugs commit ${revision}
      DPF: ${dpfRevision}; nested Pugl: ${puglRevision}; upstream pugl.patch applied.
      Source NAR: sha256-YDnRTHKIjmeTxsT8oLt7N7OcGc+tIKDfJr+++cYFkV0=
      Compiler: MinGW-w64 GCC ${cross.stdenv.cc.version}; binutils ${cross.stdenv.cc.bintools.version}
      MinGW-w64 ${cross.windows.mingw_w64.version}; MCF Gthread ${cross.windows.mcfgthreads.version}
      Cairo ${cairo.version}; pixman ${pixman.version}; zlib ${zlib.version}; libpng ${libpng.version}
      Statically linked graphics and compiler runtimes; Windows system DLLs required.
      No proprietary VST SDK: DPF ISC travesty implementation.
      License classification conditional: see LICENSE-REVIEW.md and preserved source headers.
      Corresponding source and packaging recipe accompany this output in source/.
      EOF
      runHook postInstall
    '';
  };
in runCommand "tonetwist-${version}-windows-x86_64" {
  outputs = [ "out" "installer" ];
  nativeBuildInputs = [ python3 nsis ];
  inherit repackSalt;
  passthru = {
    inherit plugin src dpf pugl revision dpfRevision puglRevision cairo pixman zlib libpng products;
    licenseStatus = "conditional-mixed-source-notices";
  };
  meta = {
    description = "ToneTwist six-product Windows x64 source build, manual ZIP and operator installer";
    homepage = "https://github.com/brummer10/ToneTwistPlugs";
    # Mixed public source grants are recorded, not replaced by a guessed suite license.
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/source" "$installer"
  cp -r ${plugin} "$out/payload"
  chmod -R u+w "$out/payload"
  cp ${dpf}/dgl/src/resources/LICENSE-DejaVuSans.ttf.txt "$out/payload/Notices/LICENSE-DejaVuSans"
  cp -r ${src} "$out/source/upstream"
  cp -r ${dpf} "$out/source/dpf"
  cp -r ${pugl} "$out/source/pugl"
  cp ${./default.nix} "$out/source/default.nix"
  cp ${./package.py} "$out/source/package.py"
  cp ${./installer.nsi} "$out/source/installer.nsi"
  cp ${./LICENSE-REVIEW.md} "$out/source/LICENSE-REVIEW.md"
  cp ${./LICENSE-CLAP} "$out/source/LICENSE-CLAP"
  cp ${cairo.src} "$out/source/cairo.tar.xz"
  cp ${pixman.src} "$out/source/pixman.tar.gz"
  cp ${zlib.src} "$out/source/zlib.tar.gz"
  cp ${libpng.src} "$out/source/libpng.tar.xz"
  cp ${../../flake.lock} "$out/source/flake.lock"
  cat > "$out/source/dependencies.json" <<'EOF'
  ${builtins.toJSON (builtins.mapAttrs (_: dependency: {
    inherit (dependency) version;
    urls = dependency.src.urls or [];
    hash = dependency.src.outputHash;
    hashAlgo = dependency.src.outputHashAlgo;
  }) { inherit cairo pixman zlib libpng; })}
  EOF
  python ${./package.py} "$out/payload" "$out/tonetwist-${version}-windows-x86_64.zip"
  cp -r "$out/payload" payload
  chmod -R u+w payload
  python ${./package.py} --normalize payload
  cp ${./installer.nsi} installer.nsi
  makensis -V3 -DOUTPUT="$installer/tonetwist-${version}-windows-x86_64-setup.exe" installer.nsi
  cp ${./installer.nsi} "$installer/installer.nsi"
  cp ${nsis.srcWinDistributable}/COPYING "$installer/NSIS-COPYING"
''
