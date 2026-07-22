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
  juce-src = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "8.0.8";
    hash = "sha256-kp3rMaHWBbEh4UaRMxcLo/DiSJV942OY+LYxh6W7dFc=";
  };
  clap-juce-extensions-src = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "02f91b7";
    hash = "sha256-cPi+prl+jLq/KvjZ5M2MxxZVLSKCiJB9SQHK8psW2OU=";
    fetchSubmodules = true;
  };
in
gccStdenv.mkDerivation {
  pname = "setekh";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "fullfxmedia";
    repo = "setekh";
    rev = "468a9bd28fa565b488711cfdbbbb10e1b287bde1";
    hash = "sha256-qSO1oCcvyoaN+JVVTJp/lzBeVNd/9k7nSelHpY1BbfI=";
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
    # Replace the entire CMakeLists.txt to use pre-fetched dependencies
    # instead of CPM.cmake network fetches.
    cat > CMakeLists.txt <<'NIX_EOF'
    cmake_minimum_required(VERSION 3.26)
    project(Setekh VERSION 0.0.1 LANGUAGES C CXX)

    if (MSVC)
      set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
    endif()

    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)

    set(LIB_DIR ''${CMAKE_CURRENT_SOURCE_DIR}/libs)
    add_subdirectory(''${LIB_DIR}/juce)
    add_subdirectory(''${LIB_DIR}/clap-juce-extensions)

    if (MSVC)
        add_compile_options(/Wall)
    else()
        add_compile_options(-Wall -Wextra -Wpedantic)
    endif()

    add_subdirectory(plugin)
    NIX_EOF

    # Inject pre-fetched dependency sources
    mkdir -p libs
    cp -r ${juce-src} libs/juce
    cp -r ${clap-juce-extensions-src} libs/clap-juce-extensions

    # Disable JUCE post-build copy (tries to write to system VST3/CLAP dirs)
    substituteInPlace plugin/CMakeLists.txt \
      --replace-fail 'COPY_PLUGIN_AFTER_BUILD TRUE' \
      'COPY_PLUGIN_AFTER_BUILD FALSE'
  '';

  configurePhase = ''
    runHook preConfigure

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_STANDALONE=OFF \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target Setekh_VST3 Setekh_LV2 Setekh_CLAP -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for shared_lib in \
      "build/plugin/Setekh_artefacts/Release/VST3/Setekh.vst3/Contents/x86_64-linux/Setekh.so" \
      "build/plugin/Setekh_artefacts/Release/LV2/Setekh.lv2/libSetekh.so" \
      "build/plugin/Setekh_artefacts/Release/CLAP/Setekh.clap"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$shared_lib"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build/plugin";
      artifacts = [
        {
          format = "vst3";
          source = "Setekh_artefacts/Release/VST3/Setekh.vst3";
          type = "directory";
          destination = "Setekh.vst3";
        }
        {
          format = "lv2";
          source = "Setekh_artefacts/Release/LV2/Setekh.lv2";
          type = "directory";
          destination = "Setekh.lv2";
        }
        {
          format = "clap";
          source = "Setekh_artefacts/Release/CLAP/Setekh.clap";
          type = "file";
          destination = "Setekh.clap";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Minimalistic multi-format distortion plugin (VST3, LV2, CLAP)";
    homepage = "https://fullfxmedia.com/plugins/setekh/";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
