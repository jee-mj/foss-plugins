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
}:

let
  # Pin JUCE to a specific commit instead of "master"
  juce-src = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "8.0.12";
    hash = "sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=";
  };
in
gccStdenv.mkDerivation {
  pname = "openkick";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "navidsatarmaker";
    repo = "OpenKick";
    rev = "e8b0d350fe1d4394011fd60c68dc7980aa0bd5b0";
    hash = "sha256-yDXnr4GNJDIrqAVniap9jC/vlfL7J6tKkJXicaYRxjo=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
  ];

  buildInputs = juceRuntime.runtimeLibs;

  dontPatchELF = true;

  postPatch = ''
    # Replace FetchContent JUCE fetch with pre-fetched source
    substituteInPlace CMakeLists.txt \
      --replace-fail 'FetchContent_Declare(
        juce
        GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
        GIT_TAG        master
    )
    FetchContent_MakeAvailable(juce)' \
      "add_subdirectory(${juce-src} juce)"
  '';

  configurePhase = ''
    runHook preConfigure

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target OpenKick_VST3 OpenKick_Standalone -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/OpenKick_artefacts/Release/VST3/OpenKick.vst3/Contents/x86_64-linux/OpenKick.so" \
      "build/OpenKick_artefacts/Release/Standalone/OpenKick"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "OpenKick_artefacts/Release/VST3/OpenKick.vst3";
          type = "directory";
          destination = "OpenKick.vst3";
        }
        {
          format = "standalone";
          source = "OpenKick_artefacts/Release/Standalone/OpenKick";
          type = "executable";
          destination = "OpenKick";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Lightweight VST3 volume-ducking and transient sidechain utility";
    homepage = "https://github.com/navidsatarmaker/OpenKick";
    # Unfree: MIT claimed in README but no LICENSE file in repository.
    # Placed behind unfree gate pending upstream resolution.
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
