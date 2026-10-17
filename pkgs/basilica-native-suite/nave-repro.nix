{ gccStdenv, callPackage }:
let
  nave = callPackage ./package.nix {
    name = "Nave";
    juceRuntime = callPackage ../../lib/juce-runtime.nix { };
    pluginArtifacts = callPackage ../../lib/plugin-artifacts.nix { };
  };
in gccStdenv.mkDerivation {
  name = "basilica-nave-minimum-overload-repro";
  dontUnpack = true;
  buildPhase = ''
    flags="-std=c++20 -DNDEBUG -DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1 -DJUCE_STANDALONE_APPLICATION=1 -I${nave.juceSource}/modules"
    if $CXX $flags -DMODE=0 -fsyntax-only ${./nave-minimum-repro.cpp} > old.log 2>&1; then
      exit 1
    fi
    # Require the original diagnostic, rather than an unrelated compiler error.
    grep -F 'SIMDRegister<long long int>' old.log
    grep -F 'invalid use of incomplete type' old.log
    $CXX $flags -DMODE=1 -fsyntax-only ${./nave-minimum-repro.cpp}
    $CXX $flags -DMODE=2 -fsyntax-only ${./nave-minimum-repro.cpp}
  '';
  installPhase = ''
    mkdir -p "$out"
    cp old.log "$out/original-diagnostic.txt"
    printf '%s\n' 'explicit jmin: rejected; deduced scalar jmin: accepted; scalar std::min: accepted; SIMD enabled' > "$out/result.txt"
  '';
}
