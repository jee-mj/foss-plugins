{
  cmake,
  fetchFromGitHub,
  gccStdenv,
  juceRuntime,
  lib,
  ninja,
  patchelf,
  pkg-config,
  pluginArtifacts,
  python3,
}:

let
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "29396c22c93392d6738e021b83196283d6e4d850";
    hash = "sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=";
  };
in
gccStdenv.mkDerivation {
  pname = "space-dust-synthesizer";
  version = "1.0.16";

  src = fetchFromGitHub {
    owner = "gadalleore";
    repo = "Space_Dust_Synthesizer";
    rev = "1d07997ce14e4c72a1e50c7cf4ff3c74595c23fb";
    hash = "sha256-yyonO+s+VCm8ikfGTdFb82zu3DRhhjotNJQLsnPusCs=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
    python3
  ];

  buildInputs = juceRuntime.runtimeLibs;

  # JUCE loads several runtime libraries with dlopen, so fixup must not shrink them.
  dontPatchELF = true;

  configurePhase = ''
    runHook preConfigure

    cp -R ${juceSrc} JUCE
    chmod -R u+w JUCE
    python3 patches/apply-juce-mpe-patch.py --juce "$PWD/JUCE"

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DJUCE_DIR="$PWD/JUCE" \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib \
      -DCMAKE_CXX_FLAGS="-DJUCE_WEB_BROWSER=0 -DJUCE_USE_CURL=0" \
      -DENABLE_VLD=OFF -DENABLE_ASAN=OFF -DENABLE_TSAN=OFF \
      -DENABLE_MEMORY_SAFETY_LOGGING=OFF -DENABLE_TRANSIENT_TEST=OFF

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target SpaceDust_VST3 SpaceDust_Standalone -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/SpaceDust_artefacts/Release/VST3/Space Dust.vst3/Contents/x86_64-linux/Space Dust.so" \
      "build/SpaceDust_artefacts/Release/Standalone/Space Dust"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "SpaceDust_artefacts/Release/VST3/Space Dust.vst3";
          type = "directory";
          destination = "Space Dust.vst3";
        }
        {
          format = "standalone";
          source = "SpaceDust_artefacts/Release/Standalone/Space Dust";
          type = "executable";
          destination = "Space Dust";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Polyphonic JUCE synthesizer plugin";
    homepage = "https://github.com/gadalleore/Space_Dust_Synthesizer";
    license = [ lib.licenses.gpl3Only lib.licenses.agpl3Only ];
    mainProgram = "Space Dust";
    platforms = lib.platforms.linux;
  };
}
