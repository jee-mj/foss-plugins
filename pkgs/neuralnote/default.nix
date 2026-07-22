{
  cmake,
  fetchFromGitHub,
  gccStdenv,
  juceRuntime,
  lib,
  ninja,
  onnxruntime,
  patchelf,
  pkg-config,
  pluginArtifacts,
  stdenv,
}:

# NeuralNote uses ONNX Runtime via the nixpkgs onnxruntime package (shared library, 1.24.4).
# Upstream was built against 1.14.1 but the C API is backward compatible.
# The model (features_model.ort) is committed in the source repo.

gccStdenv.mkDerivation {
  pname = "neuralnote";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "DamRsn";
    repo = "NeuralNote";
    rev = "f979e51dfeab54d5921858af39403308ab06e60c";
    hash = "sha256-FBmkXaVhYJMrA6SG28AhhuPpZfFvi2Q6cmcOA0oKM3c=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
  ];

  buildInputs = juceRuntime.runtimeLibs ++ [ onnxruntime ];

  dontPatchELF = true;

  postPatch = ''
    # Replace the ONNX Runtime import block to use nixpkgs shared library.
    # The original uses STATIC IMPORTED with hardcoded ThirdParty paths.
    # We remove lines 118-139 (onnxruntime import setup including platform conditionals).
    sed -i '118,139d' CMakeLists.txt

    # Insert new onnxruntime setup using nixpkgs shared library.
    # Use a temp file approach to avoid sed escaping issues.
    cat > /tmp/nn_ort_insert.txt <<'INSERTEOF'
# nixpkgs onnxruntime (shared library)
add_library(onnxruntime SHARED IMPORTED)
set_target_properties(onnxruntime PROPERTIES
  IMPORTED_LOCATION "ONNXRT_LIB"
  INTERFACE_INCLUDE_DIRECTORIES "ONNXRT_INCLUDE"
)
target_include_directories("''${BaseTargetName}" PRIVATE "ONNXRT_INCLUDE")
INSERTEOF
    sed -i "s|ONNXRT_LIB|${onnxruntime}/lib/libonnxruntime.so|g" /tmp/nn_ort_insert.txt
    sed -i "s|ONNXRT_INCLUDE|${onnxruntime.dev}/include|g" /tmp/nn_ort_insert.txt
    sed -i '117r /tmp/nn_ort_insert.txt' CMakeLists.txt

    # Remove the old include dir line that referenced ThirdParty/onnxruntime
    sed -i '\|ThirdParty/onnxruntime/include|d' CMakeLists.txt

    # Disable RTNeural CPM.cmake download attempt
    echo '# CPM disabled — Nix provides all dependencies' > ThirdParty/RTNeural/cmake/CPM.cmake

    # Provide the ONNX model (features_model.ort).
    # The original build.sh moves this from the ONNX Runtime archive.
    # We provide it from the pre-converted model.
    cp ${../../repackaged/onnxruntime-neuralnote/features_model.ort} Lib/ModelData/features_model.ort
  '';

  configurePhase = ''
    runHook preConfigure

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DLTO=ON \
      -DBUILD_UNIT_TESTS=OFF \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target NeuralNote_VST3 NeuralNote_Standalone -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for binary in \
      "build/NeuralNote_artefacts/Release/VST3/NeuralNote.vst3/Contents/x86_64-linux/NeuralNote.so" \
      "build/NeuralNote_artefacts/Release/Standalone/NeuralNote"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$binary"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "NeuralNote_artefacts/Release/VST3/NeuralNote.vst3";
          type = "directory";
          destination = "NeuralNote.vst3";
        }
        {
          format = "standalone";
          source = "NeuralNote_artefacts/Release/Standalone/NeuralNote";
          type = "executable";
          destination = "NeuralNote";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Audio to MIDI transcription plugin using deep learning";
    homepage = "https://github.com/DamRsn/NeuralNote";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    fossPlugins = {
      classification = "accept-source";
      reviewed-commit = "f979e51dfeab54d5921858af39403308ab06e60c";
      reviewed-date = "2026-07-22";
      formats = [ "vst3" "standalone" ];
      risk = "low";
    };
  };
}
