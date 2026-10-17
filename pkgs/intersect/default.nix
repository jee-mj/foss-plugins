{ lib, gccStdenv, fetchFromGitHub, callPackage, cmake, ninja, pkg-config
, python3, patchelf, curl, juceRuntime, pluginArtifacts
, provider ? "cpu"
}:
let
  ortRuntime = callPackage ./runtime.nix { inherit provider; };
  # All providers use exactly the same 1.24.2 public API, not nixpkgs' current ORT.
  ortHeaders = if provider == "cpu" then ortRuntime else callPackage ./runtime.nix { provider = "cpu"; };
  sourceRevision = "f89e556d074ee46d88717ddfe92a84d3df824879";
in gccStdenv.mkDerivation {
  pname = "intersect" + lib.optionalString (provider != "cpu") "-${provider}";
  version = "0.17.0";
  src = fetchFromGitHub {
    owner = "tucktuckg00se";
    repo = "INTERSECT";
    rev = sourceRevision;
    fetchSubmodules = true;
    hash = "sha256-dNIjasfRn6Szv+7sfwd7GKL0pW4lQWUbj0wg4h9+bDg=";
  };
  nativeBuildInputs = [ cmake ninja pkg-config python3 patchelf ];
  buildInputs = juceRuntime.runtimeLibs ++ [ curl ];
  dontPatchELF = true;
  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'FORMATS VST3 AU Standalone' 'FORMATS VST3 COPY_PLUGIN_AFTER_BUILD FALSE' \
      --replace-fail 'juce::juce_recommended_lto_flags' ""
    python3 ${./offline.py} ${ortRuntime} ${provider}
  '';
  cmakeFlags = [
    "-DINTERSECT_VERSION=0.17.0"
    "-DINTERSECT_ORT_VERSION=1.24.2"
    "-DINTERSECT_ORT_HEADERS_ROOT=${ortHeaders}"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DBUILD_TESTING=OFF"
  ];
  buildPhase = ''
    runHook preBuild
    cmake --build . --target Intersect_VST3 -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    patchelf --add-rpath "${juceRuntime.runtimeRpath}" \
      Intersect_artefacts/Release/VST3/INTERSECT.vst3/Contents/x86_64-linux/INTERSECT.so
    ${pluginArtifacts.install {
      sourceRoot = "Intersect_artefacts/Release";
      artifacts = [ { format = "vst3"; source = "VST3/INTERSECT.vst3"; type = "directory"; destination = "INTERSECT.vst3"; } ];
    }}
    install -Dm644 ../LICENSE "$out/share/licenses/intersect/LICENSE"
    runHook postInstall
  '';
  passthru = {
    inherit provider ortRuntime ortHeaders sourceRevision;
    runtimeId = ortRuntime.runtimeId;
    # Parent may register these only after its own acceptance decision.
    # Use .override { provider = "cuda12"; } or "migraphx"; CPU evaluation
    # never evaluates their library closures.
  };
  meta = {
    description = "Slicing sampler with optional background stem separation (source-built VST3)";
    homepage = "https://github.com/tucktuckg00se/INTERSECT";
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
