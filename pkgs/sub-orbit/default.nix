{ cmake, fetchFromGitHub, gccStdenv, juceRuntime, lib, ninja, patchelf
, pkg-config, pluginArtifacts
}:

let
  juceSource = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "29396c22c93392d6738e021b83196283d6e4d850"; # 8.0.12
    hash = "sha256-mq7lpPHbb1uF3o50/UZY9LiT81ACAk9ptHQ98fhdk1Q=";
  };
  catchSource = fetchFromGitHub {
    owner = "catchorg";
    repo = "Catch2";
    rev = "fa43b77429ba76c462b1898d6cd2f2d7a9416b14"; # v3.7.1
    hash = "sha256-Zt53Qtry99RAheeh7V24Csg/aMW25DT/3CN/h+BaeoM=";
  };
in
gccStdenv.mkDerivation {
  pname = "sub-orbit";
  version = "1.0.0-unstable";

  src = fetchFromGitHub {
    owner = "echoeslabmusic";
    repo = "Sub-Orbit";
    rev = "768bb5b65fd5da637c481f42c002041da24e4d22";
    hash = "sha256-0R75shW2yTDAtUEj+JE2sEAnoIF9E5a//koeqVpqpdI=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config patchelf ];
  buildInputs = juceRuntime.runtimeLibs;
  dontPatchELF = true;

  postPatch = ''
    substituteInPlace CMakeLists.txt \
      --replace-fail 'FORMATS AU VST3' 'FORMATS VST3'
  '';

  configurePhase = ''
    runHook preConfigure
    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
      -DFETCHCONTENT_SOURCE_DIR_JUCE=${juceSource} \
      -DFETCHCONTENT_SOURCE_DIR_CATCH2=${catchSource} \
      -DSUB_ORBIT_ENABLE_PLUGINVAL=OFF \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --target SubOrbit_VST3 SubOrbitTests -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    ctest --test-dir build --output-on-failure -j"$NIX_BUILD_CORES"
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    patchelf --add-rpath "${juceRuntime.runtimeRpath}" \
      "build/SubOrbit_artefacts/Release/VST3/SUB ORBIT.vst3/Contents/x86_64-linux/SUB ORBIT.so"
    ${pluginArtifacts.install {
      sourceRoot = "build/SubOrbit_artefacts/Release";
      artifacts = [
        { format = "vst3"; source = "VST3/SUB ORBIT.vst3"; type = "directory"; destination = "SUB ORBIT.vst3"; }
      ];
    }}
    install -Dm644 LICENSE "$out/share/doc/sub-orbit/LICENSE"
    install -Dm644 NOTICE "$out/share/doc/sub-orbit/NOTICE"
    install -Dm644 ${juceSource}/LICENSE.md "$out/share/doc/sub-orbit/JUCE-LICENSE.md"
    runHook postInstall
  '';

  meta = {
    description = "Low-band stereo width and sidechain ducking plugin (VST3)";
    homepage = "https://github.com/echoeslabmusic/Sub-Orbit";
    # Project: MIT; linked JUCE 8: AGPLv3; embedded VGA font: CC BY-SA 4.0.
    license = [ lib.licenses.mit lib.licenses.agpl3Only lib.licenses.cc-by-sa-40 ];
    platforms = [ "x86_64-linux" ];
  };
}
