{
  cmake,
  fetchFromGitHub,
  gccStdenv,
  juceRuntime,
  lib,
  ninja,
  nlohmann_json,
  patchelf,
  pkg-config,
  pluginArtifacts,
}:

let
  # Pin JUCE and the lumena submodule
  juce-src = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "8.0.14";
    hash = "sha256-oXFYfFqySW2XtM1e5/ifxAp9qSIVLzY1WAUKE3EscoQ=";
  };
  lumena-src = fetchFromGitHub {
    owner = "pixelsncodes";
    repo = "lumena";
    rev = "03fcd8a9c282fdd0427ddc0a6e0dcb5676939dc5";
    hash = "sha256-Z8JbFORvOh7CY1mWxo2utT4lcyzcfXHkk8hslWr8Qiw=";
  };
in
gccStdenv.mkDerivation {
  pname = "lumen";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "pixelsncodes";
    repo = "lumen";
    rev = "fa0927c19ce74da35454b9da893c1b406f528b6b";
    hash = "sha256-a9y52JE9nX7e3sYM+399Dg4J43SLHEvRln+I/HTWZQM=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
  ];

  buildInputs = juceRuntime.runtimeLibs ++ [ nlohmann_json ];

  dontPatchELF = true;

  postPatch = ''
    # Replace FetchContent JUCE with pre-fetched source
    substituteInPlace CMakeLists.txt \
      --replace-fail 'include(FetchContent)
    FetchContent_Declare(JUCE
        GIT_REPOSITORY https://github.com/juce-framework/JUCE.git
        GIT_TAG        8.0.14
        GIT_SHALLOW    TRUE
    )
    FetchContent_MakeAvailable(JUCE)' \
      "add_subdirectory(${juce-src} juce)"

    # Inject lumena submodule (not fetched by shallow clone)
    rm -rf external/lumena
    cp -r ${lumena-src} external/lumena
    chmod -R u+w external/lumena

    # Patch lumena to use nixpkgs nlohmann_json instead of FetchContent download
    sed -i '/include(FetchContent)/d' external/lumena/CMakeLists.txt
    sed -i '/FetchContent_Declare(nlohmann_json/,/FetchContent_MakeAvailable(nlohmann_json)/d' external/lumena/CMakeLists.txt
    # Inject find_package in place of the removed FetchContent block
    sed -i '/^# Dependencies:/a find_package(nlohmann_json REQUIRED)' external/lumena/CMakeLists.txt

    # Disable the post-build copy VST3 script (writes to system paths)
    echo "" > cmake/CopyVST3.cmake
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

    cmake --build build --target Lumen_VST3 Lumen_Standalone -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/Lumen_artefacts/Release/VST3/Lumen.vst3/Contents/x86_64-linux/Lumen.so" \
      "build/Lumen_artefacts/Release/Standalone/Lumen"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "Lumen_artefacts/Release/VST3/Lumen.vst3";
          type = "directory";
          destination = "Lumen.vst3";
        }
        {
          format = "standalone";
          source = "Lumen_artefacts/Release/Standalone/Lumen";
          type = "executable";
          destination = "Lumen";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Wavetable synthesiser with deterministic image-to-tone engine (Lens)";
    homepage = "https://github.com/pixelsncodes/lumen";
    # MIT license for Lumen itself, but the lumena submodule license is unverified.
    # Placed behind unfree gate until lumena license is confirmed compatible.
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
