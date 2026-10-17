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
  # Match conanfile.py and CMakeLists.txt at the pinned upstream release.
  juceSource = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "69795dc8e589a9eb5df251b6dd994859bf7b3fab"; # 7.0.5
    hash = "sha256-NRF9oSE04hk6KVSxuUBpP+z+DKRyb6pzBXtz/pLz0/0=";
  };
  clapSource = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "b6cdda9f1fad06ba14e74e036f737d2ed11db2e7";
    hash = "sha256-izwjrtjadZ3i4gx8iG71J1wVj4FVCZGyTLCDxH3A7Yg=";
    fetchSubmodules = true;
  };
in
gccStdenv.mkDerivation {
  pname = "peakeater";
  version = "0.8.2";

  src = fetchFromGitHub {
    owner = "vvvar";
    repo = "PeakEater";
    rev = "a99b8db4e67a125216634fdcab663050f7cc3add"; # v0.8.2
    hash = "sha256-u4Tqbgk6xU+EW52PRpx5iP0MrjltX+s8mnmY7FK2Kxw=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config patchelf ];
  buildInputs = juceRuntime.runtimeLibs;
  dontPatchELF = true;

  postPatch = ''
    # Use the upstream build graph, replacing only dependency provisioning and
    # selecting plugin formats. No Conan, pluginval, archives or user installs.
    substituteInPlace CMakeLists.txt \
      --replace-fail 'find_package(JUCE CONFIG REQUIRED)' \
        'add_subdirectory(${juceSource} juce EXCLUDE_FROM_ALL)' \
      --replace-fail 'FORMATS AU VST3 LV2 Standalone' \
        'FORMATS VST3 LV2 COPY_PLUGIN_AFTER_BUILD FALSE'
  '';

  configurePhase = ''
    runHook preConfigure
    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PROJECT_NAME=peakeater -DCMAKE_PROJECT_VERSION=0.8.2 \
      -DCONAN_PROJECT_COMPANY=T-Audio \
      -DCONAN_PROJECT_URL=https://github.com/vvvar/PeakEater \
      -DCMAKE_CXX_STANDARD=20 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
      -DFETCHCONTENT_FULLY_DISCONNECTED=ON \
      -DFETCHCONTENT_SOURCE_DIR_CLAP-JUCE-EXTENSIONS=${clapSource} \
      -DCLAP_JUCE_EXTENSIONS_BUILD_EXAMPLES=OFF -DBUILD_TESTING=OFF \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --target peakeater_VST3 peakeater_CLAP peakeater_LV2 -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    for shared_lib in \
      build/peakeater_artefacts/Release/VST3/peakeater.vst3/Contents/x86_64-linux/peakeater.so \
      build/peakeater_artefacts/Release/CLAP/peakeater.clap \
      build/peakeater_artefacts/Release/LV2/peakeater.lv2/libpeakeater.so; do
      patchelf --add-rpath "${juceRuntime.runtimeRpath}" "$shared_lib"
    done

    ${pluginArtifacts.install {
      sourceRoot = "build/peakeater_artefacts/Release";
      artifacts = [
        { format = "vst3"; source = "VST3/peakeater.vst3"; type = "directory"; destination = "peakeater.vst3"; }
        { format = "clap"; source = "CLAP/peakeater.clap"; type = "file"; destination = "peakeater.clap"; }
        { format = "lv2"; source = "LV2/peakeater.lv2"; type = "directory"; destination = "peakeater.lv2"; }
      ];
    }}
    install -Dm644 LICENSE.md "$out/share/doc/peakeater/LICENSE.md"
    runHook postInstall
  '';

  meta = {
    description = "Waveshaping clipper plugin (VST3, CLAP, LV2)";
    homepage = "https://github.com/vvvar/PeakEater";
    # README says GPL-3.0 and LICENSE.md contains GPL v3; no later-version grant.
    license = lib.licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
  };
}
