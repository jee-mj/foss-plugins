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

gccStdenv.mkDerivation {
  pname = "modal-synth";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "crispinha";
    repo = "modal-synth";
    rev = "50ffe92f34866685bb5f4c55d827039cfee6ef26";
    hash = "sha256-QXACmFM0NaiLdDik1ESlIO4QDQxxa0EylpQKu1F5GZI=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
  ];

  buildInputs = juceRuntime.runtimeLibs;

  # JUCE loads several runtime libraries with dlopen, so fixup must not shrink them.
  dontPatchELF = true;

  configurePhase = ''
    runHook preConfigure

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DMODAL_BUILD_DOCS=OFF -DMODAL_BUILD_TESTS=OFF \
      -DMODAL_INSTALL_PLUGIN=OFF \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target ModalSynthPlug_VST3 ModalSynthPlug_Standalone -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/ModalSynthPlug_artefacts/Release/VST3/Modal synthesiser.vst3/Contents/x86_64-linux/Modal synthesiser.so" \
      "build/ModalSynthPlug_artefacts/Release/Standalone/Modal synthesiser"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "ModalSynthPlug_artefacts/Release/VST3/Modal synthesiser.vst3";
          type = "directory";
          destination = "Modal synthesiser.vst3";
        }
        {
          format = "standalone";
          source = "ModalSynthPlug_artefacts/Release/Standalone/Modal synthesiser";
          type = "executable";
          destination = "Modal synthesiser";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Modal synthesis software instrument";
    homepage = "https://github.com/crispinha/modal-synth";
    license = [ lib.licenses.gpl3Plus lib.licenses.agpl3Only ];
    mainProgram = "Modal synthesiser";
    platforms = lib.platforms.linux;
  };
}
