{ gccStdenv, callPackage, python3, patch }:
let
  reproduction = callPackage ./nave-repro.nix { };
  nave = callPackage ./package.nix {
    name = "Nave";
    juceRuntime = callPackage ../../lib/juce-runtime.nix { };
    pluginArtifacts = callPackage ../../lib/plugin-artifacts.nix { };
  };
in gccStdenv.mkDerivation {
  name = "basilica-nave-scalar-compatibility";
  dontUnpack = true;
  nativeBuildInputs = [ python3 patch ];
  buildPhase = ''
    python3 ${./test-nave-compatibility.py} ${nave.src} ${./nave-scalar-minimum.patch} ${nave.juceSource} "$out"
    cp -r ${reproduction} "$out/overload-reproduction"
  '';
  dontInstall = true;
}
