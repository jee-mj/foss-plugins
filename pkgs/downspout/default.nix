{
  cmake,
  dbus,
  fetchFromGitHub,
  lib,
  libGL,
  libX11,
  libXcursor,
  libXext,
  libXrandr,
  libXrender,
  ninja,
  pkg-config,
  pluginArtifacts,
  python3,
  stdenv,
}:

let
  # Keep the release script's Linux bundle contract explicit: upstream's
  # install(DIRECTORY ... OPTIONAL) otherwise hides missing plugin builds.
  bundles = [
    "campione" "bassgen" "p_mix" "e_mix" "m_mix" "t_mix" "mixgen"
    "loopdelay" "lightverb" "melgen" "rift" "orchid" "ambo"
    "drumgen" "drumkit" "syrinx" "cadence" "arpgen"
    "counterpointer" "sidecar" "gremlin" "gremlin_driver" "ground"
    "floozy" "basilico" "canticle" "moka" "luma" "paunchlad"
    "lifeform" "xoxolo" "tuney_vst" "harmonic_atlas" "conductor"
    "drift" "mnemosyne" "polymeter" "oracle" "mosaic"
    "resonance_garden" "orbit" "guardian" "chipper" "skream"
    "worms" "magneto"
  ];
in
stdenv.mkDerivation {
  pname = "downspout";
  version = "0.16.2";

  src = fetchFromGitHub {
    owner = "danja";
    repo = "downspout";
    rev = "0514385b0adc55ef9a4f592a5d6b412e0758809f"; # v0.16.2
    hash = "sha256-k662LdECtL3xMy5Mb8HfzhS3xf/CJOychZ1plW5vBv4=";
  };

  patches = [ ./campione-dpf-browser.patch ];

  nativeBuildInputs = [ cmake ninja pkg-config python3 ];
  buildInputs = [ dbus libGL libX11 libXcursor libXext libXrandr libXrender ];

  cmakeFlags = [
    "-DBUILD_TESTING=ON"
    "-DDOWNSPOUT_ENABLE_DPF=ON"
    "-DDOWNSPOUT_BUILD_SCREENSHOT_APPS=OFF"
    "-DDOWNSPOUT_BUILD_AI_COORDINATOR=OFF"
    "-DDOWNSPOUT_VELOCILOOPS_DIR=/does-not-exist"
    # Upstream tests use assert(); CMake's default Release flags define NDEBUG.
    "-DCMAKE_CXX_FLAGS_RELEASE=-O2 -UNDEBUG"
    "-DCMAKE_C_FLAGS_RELEASE=-O2 -UNDEBUG"
  ];

  postPatch = ''
    test -f third_party/DPF/CMakeLists.txt
    test -f third_party/DPF/dgl/src/pugl-upstream/include/pugl/pugl.h
    # Both Campione picker paths must remain on the built-in DPF browser.
    if grep -Fq '::popen' plugins/campione/src/dpf/CampioneUI.cpp; then
      echo 'Campione UI still launches an external picker' >&2
      exit 1
    fi
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    ctest --test-dir . --output-on-failure --no-tests=error -j "$NIX_BUILD_CORES"
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    cd .. # cmake's build hook leaves the working directory in build/
    ${lib.concatMapStringsSep "\n" (name: ''
      test -s "build/bin/${name}.vst3/Contents/x86_64-linux/${name}.so" || {
        echo "Missing or empty VST3 shared library: ${name}" >&2
        exit 1
      }
    '') bundles}

    ${pluginArtifacts.install {
      sourceRoot = "build/bin";
      artifacts = map (name: {
        format = "vst3";
        source = "${name}.vst3";
        type = "directory";
        destination = "${name}.vst3";
      }) bundles;
    }}

    # Generate only reviewed attribution blocks; never ship entire vendor headers.
    python3 ${./collect-licenses.py} "$PWD" "$out/share/licenses/downspout" ${./CC0-1.0.txt}
    runHook postInstall
  '';

  meta = {
    description = "Generative and algorithmic VST3 audio plugins";
    homepage = "https://github.com/danja/downspout";
    # stb_truetype is distributed under its MIT alternative; JSON's Abseil
    # C++11 fallback is not compiled by this C++20 build.
    license = with lib.licenses; [
      mit isc zlib bitstreamVera cc0
      # The pinned stb_image dedication has no SPDX identifier. Give its
      # installed verbatim notice a package-local LicenseRef for the free gate.
      (publicDomain // { spdxId = "LicenseRef-stb-image-PD-fallback"; })
    ];
    platforms = [ "x86_64-linux" ];
  };
}
