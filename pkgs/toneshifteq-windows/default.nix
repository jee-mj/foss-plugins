{ lib, pkgsCross, fetchFromGitHub, runCommand, python3, nsis, meson, ninja,
  pkg-config, which, xxd, repackSalt ? "", compileSalt ? "" }:
let
  revision = "2c9798ded641988d59e6d5e79fa88feb2d9ff13c";
  libxputtyRevision = "439d5cd5fed48618f773375ae6624e91ff82ee1e";
  version = "1.3.0";
  src = fetchFromGitHub {
    owner = "brummer10"; repo = "ToneShiftEQ"; rev = revision;
    fetchSubmodules = true;
    hash = "sha256-y85UbyIbkFS8UDxzLg23nPQyqS/GRX1VEcVg5Rr/9Go=";
  };
  cross = pkgsCross.mingwW64;
  pixman = cross.pixman.overrideAttrs (old: {
    mesonFlags = (old.mesonFlags or []) ++ [ "-Ddefault_library=static" ];
  });
  zlib = cross.zlib.override { shared = false; };
  libpng = (cross.libpng.override { inherit zlib; apngSupport = false; }).overrideAttrs (old: {
    configureFlags = (old.configureFlags or []) ++ [ "--disable-shared" "--enable-static" ];
  });
  # Same locked minimal Win32/image Cairo closure as ToneTwist. Embedded fonts
  # use libxputty's stb_truetype/Cairo user-font path, not FreeType/fontconfig.
  cairo = cross.stdenv.mkDerivation {
    pname = "toneshifteq-cairo-windows-static";
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
  # IR WAV/AIFF and libsndfile's built-in formats; optional compressed codecs
  # are disabled explicitly rather than accidentally discovered on the host.
  sndfile = cross.libsndfile.overrideAttrs (old: {
    pname = "toneshifteq-libsndfile-windows-static";
    buildInputs = [];
    outputs = [ "out" "dev" ];
    env = {};
    configureFlags = (old.configureFlags or []) ++ [
      "--disable-shared" "--enable-static" "--disable-external-libs"
      "--disable-mpeg" "--disable-sqlite" "--disable-full-suite"
    ];
  });
  dependencies = { inherit cairo pixman zlib libpng sndfile; };
  toolchain = {
    gcc = cross.stdenv.cc.cc;
    binutils = cross.stdenv.cc.bintools.bintools;
    mingw = cross.windows.mingw_w64;
    mcfgthreads = cross.windows.mcfgthreads;
  };
  sources = dependencies // toolchain;
  plugin = cross.stdenv.mkDerivation {
    pname = "toneshifteq-windows-bundles";
    inherit version src compileSalt;
    nativeBuildInputs = [ pkg-config which xxd ];
    buildInputs = [ cairo pixman zlib libpng sndfile cross.windows.pthreads ];
    dontConfigure = true;
    dontStrip = true;
    buildPhase = ''
      runHook preBuild
      flags=(CC="$CC" CXX="$CXX" AR="$AR" LD="$LD" STRIP=true TERM= V=1
        TARGET=Windows CROSS_COMPILING=1 PKGCONFIG=pkg-config PKGCONFIG_FLAGS=--static
        CFLAGS="-DCAIRO_WIN32_STATIC_BUILD -D_USE_MATH_DEFINES"
        PAWPAW_LFLAGS="-static -Wl,--no-insert-timestamp $(pkg-config --static --libs cairo sndfile) -lcomdlg32 -ldwmapi -lgdi32 -lole32 -lwinmm -lpthread")
      make -j"$NIX_BUILD_CORES" clap vst3 "''${flags[@]}"
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/CLAP" "$out/VST3" "$out/Notices" "$out/relink"
      cp bin/toneshifteq.clap "$out/CLAP/"
      cp -r bin/Toneshifteq.vst3 "$out/VST3/"
      # Entire public notices retain full font, xdgmime, stb and embedded grants.
      cp LICENSE "$out/Notices/LICENSE-ToneShiftEQ"
      cp -r ${src}/libxputty "$out/Notices/libxputty"
      cp -r ${src}/EQ12 "$out/Notices/EQ12"
      cp -r EQ12 "$out/relink/EQ12"
      cp -r libxputty "$out/relink/libxputty"
      cp makefile "$out/relink/"
      cp ${./LICENSE-REVIEW.md} "$out/Notices/LICENSE-REVIEW.md"
      cp ${cross.windows.mcfgthreads.src}/LICENSE.TXT "$out/Notices/LICENSE-MCF-Gthread"
      cp -r ${cross.windows.mcfgthreads.src}/licenses "$out/Notices/GNU-runtime-licenses"
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: dep: ''
        mkdir -p "$out/relink/libraries/${name}"
        cp -r ${lib.getLib dep}/lib/. "$out/relink/libraries/${name}/"
      '') dependencies)}
      runHook postInstall
    '';
  };
in runCommand "toneshifteq-${version}-windows-x86_64" {
  outputs = [ "out" "installer" ];
  nativeBuildInputs = [ python3 nsis ];
  inherit repackSalt;
  passthru = { inherit plugin src revision libxputtyRevision dependencies toolchain; };
  meta = {
    description = "ToneShiftEQ Master/Live Windows x64 CLAP and VST3 source build";
    homepage = "https://github.com/brummer10/ToneShiftEQ";
    platforms = [ "x86_64-linux" ];
  };
} ''
  mkdir -p "$out/payload/Notices" "$out/source" "$installer"
  cp -r ${plugin}/CLAP ${plugin}/VST3 "$out/payload/"
  cp -r ${plugin}/Notices/. "$out/payload/Notices/"
  cp -r ${plugin}/relink "$out/source/"
  cp -r ${src} "$out/source/upstream"
  mkdir -p "$out/source/packaging/pkgs/toneshifteq-windows"
  ${lib.concatMapStringsSep "\n" (name: ''
    cp ${./. + "/${name}"} "$out/source/packaging/pkgs/toneshifteq-windows/${name}"
  '') [ "default.nix" "package.py" "collect-notices.py" "installer.nsi" "LICENSE-REVIEW.md" ]}
  cp ${../../flake.lock} "$out/source/packaging/flake.lock"
  ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: dep: ''
    cp -r ${dep.src} "$out/source/${name}-source"
    python ${./collect-notices.py} ${dep.src} "$out/payload/Notices/${name}"
    mkdir -p "$out/source/${name}-patches"
    ${lib.concatMapStringsSep "\n" (patch: ''
      cp ${patch} "$out/source/${name}-patches/${baseNameOf (toString patch)}"
    '') (dep.patches or [])}
  '') sources)}
  cat > "$out/payload/Notices/BUILD-INFO.txt" <<'EOF'
  ToneShiftEQ ${version}, Windows x86-64, source cross-build; Master and Live in two bundles.
  Source ${revision}; recursive NAR sha256-y85UbyIbkFS8UDxzLg23nPQyqS/GRX1VEcVg5Rr/9Go=
  libxputty ${libxputtyRevision}; native GNU Make, not DPF.
  Compiler GCC ${toolchain.gcc.version}; binutils ${toolchain.binutils.version}; MinGW-w64 ${toolchain.mingw.version}; MCF Gthread ${toolchain.mcfgthreads.version}.
  Static Cairo ${cairo.version}, pixman ${pixman.version}, zlib ${zlib.version}, libpng ${libpng.version}, libsndfile ${sndfile.version}.
  Embedded Roboto/stb_truetype Cairo user-font implementation retained.
  Optional libsndfile external compressed codecs disabled; built-in WAV/AIFF retained.
  _USE_MATH_DEFINES exposes MinGW math constants under upstream strict C++17.
  Windows LV2 and standalone explicitly unsupported. No proprietary SDK required.
  Corresponding source and relink inputs accompany the package in source/.
  Source/library/toolchain hashes and patches recorded in source/dependencies.json and source/packaging/flake.lock.
  EOF
  cat > "$out/source/dependencies.json" <<'EOF'
  ${builtins.toJSON (lib.mapAttrs (_: dep: {
    inherit (dep) version;
    urls = dep.src.urls or [];
    hash = dep.src.outputHash;
    hashAlgo = dep.src.outputHashAlgo;
    patches = map (patch: {
      name = baseNameOf (toString patch);
      hash = patch.outputHash or (builtins.hashFile "sha256" patch);
      hashAlgo = patch.outputHashAlgo or "sha256";
    }) (dep.patches or []);
  }) sources)}
  EOF
  python ${./package.py} "$out/payload" "$out/toneshifteq-${version}-windows-x86_64.zip"
  cp -r "$out/payload" payload
  chmod -R u+w payload
  python ${./package.py} --normalize payload
  cp ${./installer.nsi} installer.nsi
  makensis -V3 -DOUTPUT="$installer/toneshifteq-${version}-windows-x86_64-setup.exe" installer.nsi
  cp ${./installer.nsi} "$installer/installer.nsi"
  cp ${nsis.srcWinDistributable}/COPYING "$installer/NSIS-COPYING"
''
