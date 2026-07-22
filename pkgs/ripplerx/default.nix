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
  pname = "ripplerx";
  version = "1.5.19";

  src = fetchFromGitHub {
    owner = "tiagolr";
    repo = "ripplerx";
    rev = "7da35e4cc97b90eeed64856fb3d7202142c54881";
    hash = "sha256-YcrBJu7vLh8KZkds6OA48nhOHtZjRymxGrNmh7yTIxc=";
    fetchSubmodules = true;
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
    # Disable JUCE post-build copy (tries to write to system VST3/LV2 dirs)
    substituteInPlace CMakeLists.txt \
      --replace-fail 'COPY_PLUGIN_AFTER_BUILD TRUE' \
      'COPY_PLUGIN_AFTER_BUILD FALSE'
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

    cmake --build build --target RipplerX_VST3 RipplerX_LV2 -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for shared_lib in \
      "build/RipplerX_artefacts/Release/VST3/RipplerX.vst3/Contents/x86_64-linux/RipplerX.so" \
      "build/RipplerX_artefacts/Release/LV2/RipplerX.lv2/libRipplerX.so"; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$shared_lib"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "RipplerX_artefacts/Release/VST3/RipplerX.vst3";
          type = "directory";
          destination = "RipplerX.vst3";
        }
        {
          format = "lv2";
          source = "RipplerX_artefacts/Release/LV2/RipplerX.lv2";
          type = "directory";
          destination = "RipplerX.lv2";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Physical modelling synthesiser (modal/waveguide/Karplus-Strong)";
    homepage = "https://github.com/tiagolr/ripplerx";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
