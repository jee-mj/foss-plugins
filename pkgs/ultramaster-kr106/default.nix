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
  pname = "ultramaster-kr106";
  version = "2.5.13";

  src = fetchFromGitHub {
    owner = "kayrockscreenprinting";
    repo = "ultramaster_kr106";
    rev = "bc15caee5843ab238a25d0969e68d57db2b1615f";
    hash = "sha256-R0nvtdhhrT+ucpBSsWjJEUCInd4/0jDammlUsaCgL6M=";
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

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DKR106_COPY_AFTER_BUILD=OFF

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --config Release -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/KR106_artefacts/Release/VST3/Ultramaster KR-106.vst3/Contents/x86_64-linux/Ultramaster KR-106.so" \
      "build/KR106_artefacts/Release/LV2/Ultramaster KR-106.lv2/libUltramaster KR-106.so" \
      "build/KR106_artefacts/Release/CLAP/Ultramaster KR-106.clap" \
      "build/KR106_artefacts/Release/Standalone/Ultramaster KR-106"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "KR106_artefacts/Release/VST3/Ultramaster KR-106.vst3";
          type = "directory";
          destination = "Ultramaster KR-106.vst3";
        }
        {
          format = "lv2";
          source = "KR106_artefacts/Release/LV2/Ultramaster KR-106.lv2";
          type = "directory";
          destination = "Ultramaster KR-106.lv2";
        }
        {
          format = "clap";
          source = "KR106_artefacts/Release/CLAP/Ultramaster KR-106.clap";
          type = "executable";
          destination = "Ultramaster KR-106.clap";
        }
        {
          format = "standalone";
          source = "KR106_artefacts/Release/Standalone/Ultramaster KR-106";
          type = "executable";
          destination = "Ultramaster KR-106";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Juno-6, Juno-60, and Juno-106 synthesizer emulation";
    homepage = "https://kayrock.org/kr106";
    license = [ lib.licenses.gpl3Only lib.licenses.agpl3Only ];
    mainProgram = "Ultramaster KR-106";
    platforms = lib.platforms.linux;
  };
}
