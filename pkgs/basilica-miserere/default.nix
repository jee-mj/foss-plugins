{ lib, gccStdenv, fetchFromGitHub, cmake, ninja, pkg-config, python3
, patchelf, juceRuntime, pluginArtifacts
}:
let
  revision = "6ce6cc2deb616f337622e36c747a292f505ea0b7";
  juceRevision = "2cdfca8feb300fb424002ba2c2751569e5bacb64";
  juceSource = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = juceRevision; # 8.0.14
    hash = "sha256-oXFYfFqySW2XtM1e5/ifxAp9qSIVLzY1WAUKE3EscoQ=";
  };
in gccStdenv.mkDerivation {
  pname = "basilica-miserere";
  version = "0.7.0";
  src = fetchFromGitHub {
    owner = "basilica-audio";
    repo = "Miserere";
    rev = revision;
    hash = "sha256-gzAKD2fO8DzPaFRBVOYq7Apj7haEBgrTl0qsUzTJXME=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config python3 patchelf ];
  buildInputs = juceRuntime.runtimeLibs;
  dontPatchELF = true;
  enableParallelBuilding = true;

  postPatch = ''
    # Only edit upstream CMake provisioning/targets. JUCE builds its own native
    # helper in this graph; no dependency on the Windows spike's private helper.
    python3 ${./adapt.py} ${juceSource}
  '';
  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
  ];
  buildPhase = ''
    runHook preBuild
    cmake --build . --target Miserere_VST3 --parallel "$NIX_BUILD_CORES"
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    patchelf --add-rpath "${juceRuntime.runtimeRpath}" \
      Miserere_artefacts/Release/VST3/Miserere.vst3/Contents/x86_64-linux/Miserere.so
    ${pluginArtifacts.install {
      sourceRoot = "Miserere_artefacts/Release";
      artifacts = [
        { format = "vst3"; source = "VST3/Miserere.vst3"; type = "directory"; destination = "Miserere.vst3"; }
      ];
    }}
    install -Dm644 ../LICENSE "$out/share/doc/basilica-miserere/LICENSE-Miserere"
    install -Dm644 ${juceSource}/LICENSE.md "$out/share/doc/basilica-miserere/LICENSE-JUCE"
    install -Dm644 ../resources/fonts/OFL-EBGaramond.txt \
      "$out/share/doc/basilica-miserere/OFL-EBGaramond.txt"
    runHook postInstall
  '';
  passthru = { inherit revision juceRevision juceSource; };
  meta = {
    description = "Experimental locally source-built Basilica Miserere Linux VST3 vocal processor";
    homepage = "https://github.com/basilica-audio/Miserere";
    license = [ lib.licenses.agpl3Only lib.licenses.ofl ];
    platforms = [ "x86_64-linux" ];
  };
}
