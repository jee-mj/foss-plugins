{ lib, callPackage, gccStdenv, fetchgit, fetchFromGitHub, cmake, ninja, pkg-config
, patchelf, cudaPackages, lame, mpg123, juceRuntime, pluginArtifacts
, provider ? "cpu"
}:
assert lib.assertMsg (builtins.elem provider [ "cpu" "cuda" ])
  "AudioRestorationVST supports cpu/cuda only; legacy ROCm 1.17.3 is not MIGraphX and HIP DSP is incomplete";
let
  cudaSupport = provider == "cuda";
  # Mode inspection must not evaluate the selected runtime or its license gate.
  providerCmakeFlag = "-DONNXRUNTIME_USE_CUDA=${if cudaSupport then "ON" else "OFF"}";
  # Deliberate runtime binary dependency: full ORT source includes test models.
  # Plugin/JUCE remain source-built; no ORT/ONNX source is fetched transitively.
  runtime = callPackage ./runtime.nix { inherit provider cudaPackages; };
  juceSource = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "c352e2489000ffeb9e397051377d75eef2efe641"; # 8.0.11, upstream submodule
    hash = "sha256-sUxPFxQ/Q1ESlp6tdGI8hGkc3szYkFwBO8xARg2JiR4=";
  };
  bundle = "Vinyl Restoration Suite v1.6.35";
in
gccStdenv.mkDerivation {
  pname = "audio-restoration-vst" + lib.optionalString (provider != "cpu") "-${provider}";
  version = "1.6.35";
  src = fetchgit {
    url = "https://github.com/flarkflarkflark/AudioRestorationVST.git";
    rev = "df7bf68c764095634b45d79f3a40839f0ff39306";
    hash = "sha256-LMrJgJ+ehmtw6zkbhillxXf9VYm7VgdjkQbJcncd0gQ=";
    # fetchgit sets remote.origin.partialclonefilter=blob:none before fetching.
    # Do not replace this with an archive fetch: the archive contains models.
    fetchSubmodules = false;
    nonConeMode = true;
    sparseCheckout = [ "/CMakeLists.txt" "/LICENSE" "/Source/" "/flarkaudiologo.png" ];
  };
  nativeBuildInputs = [ cmake ninja pkg-config patchelf ];
  buildInputs = juceRuntime.runtimeLibs ++ [ runtime lame mpg123 ];
  dontPatchELF = true;
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'add_subdirectory(JUCE)' 'add_subdirectory(${juceSource} JUCE)' \
      --replace-fail 'set(ONNXRUNTIME_INCLUDE_DIR "''${ONNXRUNTIME_DIR}/include")' \
        'set(ONNXRUNTIME_INCLUDE_DIR "${lib.getDev runtime}/include/onnxruntime")' \
      --replace-fail 'set(ONNXRUNTIME_LIBRARY "''${ONNXRUNTIME_DIR}/lib/libonnxruntime.so")' \
        'set(ONNXRUNTIME_LIBRARY "${lib.getLib runtime}/lib/libonnxruntime.so")'
    # Libraries remain in their Nix closure, not copied into the VST3 bundle.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'if(ONNXRUNTIME_RUNTIME_LIBS)' 'if(FALSE)'
    # CPU is the default even for an opt-in CUDA-capable build. Provider choice
    # remains explicit in the plugin UI; existing saved user settings still apply.
    substituteInPlace Source/DSP/OnnxDenoiser.h \
      --replace-fail 'Provider preferredProvider = Provider::autoSelect;' \
        'Provider preferredProvider = Provider::cpu;'
    substituteInPlace Source/Utils/SettingsManager.h \
      --replace-fail 'juce::String provider = "Auto";' 'juce::String provider = "CPU";'
    substituteInPlace Source/Utils/SettingsManager.cpp \
      --replace-fail 'props->getValue (kProviderKey, "Auto")' 'props->getValue (kProviderKey, "CPU")'
    # ThrowOnError releases OrtStatus and enters the existing catch/false path.
    # The caller's provider order controls whether CPU fallback is permitted.
    substituteInPlace Source/DSP/OnnxDenoiser.cpp \
      --replace-fail 'OrtSessionOptionsAppendExecutionProvider_CUDA (sessionOptions, 0);' \
        'Ort::ThrowOnError (OrtSessionOptionsAppendExecutionProvider_CUDA (sessionOptions, 0));'
  '';
  cmakeFlags = [
    "-DENABLE_ONNX_RUNTIME=ON"
    "-DONNXRUNTIME_DIR=${lib.getLib runtime}"
    "-DONNXRUNTIME_VERSION=${runtime.version}"
    providerCmakeFlag
    "-DONNXRUNTIME_USE_ROCM=OFF"
    "-DONNXRUNTIME_USE_DML=OFF"
    "-DONNXRUNTIME_USE_COREML=OFF"
    "-DENABLE_GPU_ACCELERATION=OFF"
    "-DVRS_USE_VCPKG=OFF"
    "-DVRS_COPY_PLUGIN_AFTER_BUILD=OFF"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar"
    "-DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib"
  ];
  buildPhase = ''
    runHook preBuild
    cmake --build . --target VinylRestorationSuite_VST3 -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    shared_lib="VinylRestorationSuite_artefacts/Release/VST3/${bundle}.vst3/Contents/x86_64-linux/${bundle}.so"
    patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$shared_lib"
    ${pluginArtifacts.install {
      sourceRoot = "VinylRestorationSuite_artefacts/Release";
      artifacts = [{ format = "vst3"; source = "VST3/${bundle}.vst3"; type = "directory"; destination = "${bundle}.vst3"; }];
    }}
    install -Dm644 ../LICENSE "$out/share/doc/audio-restoration-vst/LICENSE"
    install -Dm644 ${juceSource}/LICENSE.md "$out/share/doc/audio-restoration-vst/JUCE-LICENSE.md"
    runHook postInstall
  '';
  passthru = { inherit provider runtime juceSource cudaSupport providerCmakeFlag; };
  meta = {
    description = "Source-built vinyl restoration VST3 with optional ONNX CUDA provider (models supplied separately)";
    homepage = "https://github.com/flarkflarkflark/AudioRestorationVST";
    license = [ lib.licenses.mit lib.licenses.agpl3Only ];
    platforms = [ "x86_64-linux" ];
  };
}
