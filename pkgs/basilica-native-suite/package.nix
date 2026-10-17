{ lib, gccStdenv, fetchFromGitHub, cmake, ninja, pkg-config, python3, patchelf
, juceRuntime, pluginArtifacts, name }:
let
  pins = builtins.fromJSON (builtins.readFile ./pins.json);
  pin = pins.${name};
  common = import ./common-sources.nix;
  dependency = key: let p = pins.${key}; parts = lib.splitString "/" p.repo; in fetchFromGitHub {
    owner = builtins.elemAt parts 0; repo = builtins.elemAt parts 1;
    rev = p.revision; inherit (p) hash;
  };
  linear = dependency "linear";
  stretch = dependency "stretch";
  juceSource = fetchFromGitHub {
    owner = "juce-framework"; repo = "JUCE";
    rev = common.JUCE.revision; # 8.0.14
    inherit (common.JUCE) hash;
  };
in gccStdenv.mkDerivation ({
  pname = "basilica-${lib.toLower name}";
  inherit (pin) version;
  src = fetchFromGitHub {
    owner = "basilica-audio"; repo = name; rev = pin.revision; inherit (pin) hash;
  };
  nativeBuildInputs = [ cmake ninja pkg-config python3 patchelf ];
  buildInputs = juceRuntime.runtimeLibs;
  dontPatchELF = true;
  enableParallelBuilding = true;
  postPatch = ''
    python3 ${./adapt.py} ${juceSource} ${lib.optionalString (name == "Seraph")
      "signalsmith-linear=${linear} signalsmith-stretch=${stretch}"}
  '';
  cmakeFlags = [ "-DCMAKE_BUILD_TYPE=Release" "-DFETCHCONTENT_FULLY_DISCONNECTED=ON" ];
  preConfigure = ''
    export CMAKE_BUILD_PARALLEL_LEVEL="''${NIX_BUILD_CORES:-1}"
  '';
  buildPhase = ''
    runHook preBuild
    cmake --build . --target ${name}_VST3 --parallel "''${NIX_BUILD_CORES:-1}"
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    patchelf --add-rpath "${juceRuntime.runtimeRpath}" \
      ${name}_artefacts/Release/VST3/${name}.vst3/Contents/x86_64-linux/${name}.so
    ${pluginArtifacts.install {
      sourceRoot = "${name}_artefacts/Release";
      artifacts = [ { format = "vst3"; source = "VST3/${name}.vst3"; type = "directory"; destination = "${name}.vst3"; } ];
    }}
    # Notice-bearing text must come from immutable upstream, including any
    # CMake comments; the build tree's CMake graph has been adapted.
    python3 ${./notices.py} "$src" "$out/share/doc/basilica-${lib.toLower name}/upstream"
    python3 ${./notices.py} ${juceSource} "$out/share/doc/basilica-${lib.toLower name}/JUCE"
    ${lib.optionalString (name == "Seraph") ''
      python3 ${./notices.py} ${linear} "$out/share/doc/basilica-seraph/signalsmith-linear"
      python3 ${./notices.py} ${stretch} "$out/share/doc/basilica-seraph/signalsmith-stretch"
    ''}${lib.optionalString (name == "Nave") ''
      install -Dm644 ${./nave-scalar-minimum.patch} "$out/share/doc/basilica-nave/downstream/nave-scalar-minimum.patch"
      install -Dm644 ${./NOTICE-Nave.md} "$out/share/doc/basilica-nave/downstream/NOTICE-Nave.md"
      install -Dm644 ../src/PluginProcessor.cpp "$out/share/doc/basilica-nave/downstream/PluginProcessor.cpp"
    ''}
    runHook postInstall
  '';
  passthru = { inherit (pin) revision identity audio; inherit juceSource; };
  meta = {
    description = "Experimental locally source-built Basilica ${name} Linux VST3";
    homepage = "https://github.com/basilica-audio/${name}";
    license = [ lib.licenses.agpl3Only ]
      ++ lib.optional (builtins.elem name [ "Silentium" "Seraph" "Firmament" "Triptych" "Apotheosis" "Crypta" ]) lib.licenses.ofl
      ++ lib.optional (name == "Seraph") lib.licenses.mit
      ++ lib.optional (name == "Crypta") lib.licenses.cc0;
    platforms = [ "x86_64-linux" ];
  };
} // lib.optionalAttrs (name == "Nave") {
  patches = [ ./nave-scalar-minimum.patch ];
})
