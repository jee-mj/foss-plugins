{
  boost,
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
    rev = "8.0.12";
    hash = "sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=";
  };
in
gccStdenv.mkDerivation {
  pname = "cavey";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "TarcanGul";
    repo = "cavey";
    rev = "f129163313dce33d31d28241ada46ff68710b903";
    hash = "sha256-fPWdmy3ShfUZF6126lX9nqnBY8W/K4F1lDDWioVXQ6Y=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
  ];

  buildInputs = juceRuntime.runtimeLibs ++ [ boost ];

  dontPatchELF = true;

  postPatch = ''
    # Replace CMakeLists.txt with a clean version that:
    # - Uses pre-fetched JUCE via JUCE_SOURCE_DIR
    # - Uses nixpkgs boost
    # - Strips Catch2/test/coverage infrastructure
    cat > CMakeLists.txt <<'NIX_EOF'
    cmake_minimum_required(VERSION 3.21)

    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_EXTENSIONS OFF)

    project(CaveyPlugin VERSION 0.1.0)

    add_subdirectory(''${JUCE_SOURCE_DIR} juce)

    find_package(Boost 1.89 REQUIRED COMPONENTS json)

    set(CAVEY_SOURCE_FILES
        src/PluginProcessor.cpp
        src/PluginEditor.cpp
        src/types/BackendParameter.cpp
        src/components/CaveyLookAndFeel.cpp
        src/components/Parameter.cpp
        src/components/LoadingComponent.cpp
        src/components/AiSetupComponent.cpp
        src/controllers/OllamaController.cpp
        src/effects/CaveyEffects.cpp
    )

    juce_add_plugin(CaveyPlugin
        COMPANY_NAME "TarcanGul"
        BUNDLE_ID com.tarcangul.Cavey
        IS_SYNTH FALSE
        NEEDS_MIDI_INPUT FALSE
        NEEDS_MIDI_OUTPUT FALSE
        IS_MIDI_EFFECT FALSE
        EDITOR_WANTS_KEYBOARD_FOCUS FALSE
        COPY_PLUGIN_AFTER_BUILD FALSE
        PLUGIN_MANUFACTURER_CODE Cave
        PLUGIN_CODE Cave
        FORMATS VST3 Standalone
        PRODUCT_NAME "Cavey"
    )

    juce_generate_juce_header(CaveyPlugin)

    target_sources(CaveyPlugin PRIVATE
        ''${CAVEY_SOURCE_FILES}
        src/controllers/SystemPrompt.md
    )

    juce_add_binary_data(CaveyAssets SOURCES src/controllers/SystemPrompt.md)
    target_link_libraries(CaveyPlugin PRIVATE CaveyAssets)

    target_compile_features(CaveyPlugin PRIVATE cxx_std_23)

    target_compile_definitions(CaveyPlugin
        PRIVATE
            JUCE_WEB_BROWSER=0
            JUCE_USE_CURL=0
            JUCE_VST3_CAN_REPLACE_VST2=0
    )

    target_link_libraries(CaveyPlugin
        PRIVATE
            Boost::headers
            Boost::json
            juce::juce_audio_utils
            juce::juce_audio_plugin_client
            juce::juce_gui_extra
            juce::juce_dsp
            juce::juce_graphics
            juce::juce_gui_basics
            juce::juce_events
            juce::juce_data_structures
            juce::juce_core
    )
    NIX_EOF
  '';

  configurePhase = ''
    runHook preConfigure

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DJUCE_SOURCE_DIR="${juce-src}" \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target CaveyPlugin_VST3 CaveyPlugin_Standalone -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/CaveyPlugin_artefacts/Release/VST3/Cavey.vst3/Contents/x86_64-linux/Cavey.so" \
      "build/CaveyPlugin_artefacts/Release/Standalone/Cavey"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "CaveyPlugin_artefacts/Release/VST3/Cavey.vst3";
          type = "directory";
          destination = "Cavey.vst3";
        }
        {
          format = "standalone";
          source = "CaveyPlugin_artefacts/Release/Standalone/Cavey";
          type = "executable";
          destination = "Cavey";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "AI-powered audio effect generator using local LLM (Ollama)";
    homepage = "https://github.com/TarcanGul/cavey";
    # AGPL-3.0-or-later. Placed behind unfree/experimental gate due to:
    # - LLM integration requiring runtime Ollama dependency
    # - Local network surface (localhost:11434)
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
