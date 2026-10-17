{ cmake, fetchFromGitHub, gccStdenv, juceRuntime, lib, ninja, patchelf
, pkg-config, pluginArtifacts
}:

let
  # Upstream asks for a sibling JUCE 8 checkout without pinning a revision.
  juceSource = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "29396c22c93392d6738e021b83196283d6e4d850"; # 8.0.12
    hash = "sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=";
  };
in
gccStdenv.mkDerivation {
  pname = "instawidth";
  version = "1.0.0-unstable";

  src = fetchFromGitHub {
    owner = "hariel1985";
    repo = "InstaWidth";
    rev = "fcefc76077b7ec8f03d1a52deef475146cf67fd1";
    hash = "sha256-W96k/YxYVIb1pcbVH6Qq/kdN/tvL40qyVeNeyR+6yb8=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config patchelf ];
  buildInputs = juceRuntime.runtimeLibs;
  dontPatchELF = true;

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'add_subdirectory(''${CMAKE_CURRENT_SOURCE_DIR}/../JUCE ''${CMAKE_CURRENT_BINARY_DIR}/JUCE)' \
        'add_subdirectory(${juceSource} JUCE EXCLUDE_FROM_ALL)' \
      --replace-fail 'FORMATS VST3 AU LV2' 'FORMATS VST3 LV2'
  '';

  configurePhase = ''
    runHook preConfigure
    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --target InstaWidth_VST3 InstaWidth_LV2 -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    for binary in \
      build/InstaWidth_artefacts/Release/VST3/InstaWidth.vst3/Contents/x86_64-linux/InstaWidth.so \
      build/InstaWidth_artefacts/Release/LV2/InstaWidth.lv2/libInstaWidth.so; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done
    ${pluginArtifacts.install {
      sourceRoot = "build/InstaWidth_artefacts/Release";
      artifacts = [
        { format = "vst3"; source = "VST3/InstaWidth.vst3"; type = "directory"; destination = "InstaWidth.vst3"; }
        { format = "lv2"; source = "LV2/InstaWidth.lv2"; type = "directory"; destination = "InstaWidth.lv2"; }
      ];
    }}
    install -Dm644 LICENSE "$out/share/doc/instawidth/LICENSE"
    install -Dm644 README.md "$out/share/doc/instawidth/README.md"
    install -Dm644 ${juceSource}/LICENSE.md "$out/share/doc/instawidth/JUCE-LICENSE.md"
    runHook postInstall
  '';

  meta = {
    description = "Three-band mid/side stereo width plugin (VST3, LV2)";
    homepage = "https://github.com/hariel1985/InstaWidth";
    # Project README: GPL-3.0-or-later; JUCE 8: AGPLv3; Rajdhani: OFL.
    license = [ lib.licenses.gpl3Plus lib.licenses.agpl3Only lib.licenses.ofl ];
    platforms = [ "x86_64-linux" ];
  };
}
