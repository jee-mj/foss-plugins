{ callPackage }:

let
  pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  juceRuntime = callPackage ../lib/juce-runtime.nix { };

  projucer = callPackage ./rdpiano/projucer.nix { };
in
rec {
  # The free package set intentionally excludes unknown-license packages.
  freePackages = {
    amsynth = callPackage ./amsynth { inherit pluginArtifacts; };
    modal-synth = callPackage ./modal-synth { inherit pluginArtifacts juceRuntime; };
    space-dust-synthesizer = callPackage ./space-dust-synthesizer { inherit pluginArtifacts juceRuntime; };
    squelchbox = callPackage ./squelchbox { inherit pluginArtifacts; };
    ultramaster-kr106 = callPackage ./ultramaster-kr106 { inherit pluginArtifacts juceRuntime; };
  };

  unfreePackages = {
    mechanodd = callPackage ./mechanodd-spike.nix { };
    rdpiano = callPackage ./rdpiano { inherit pluginArtifacts projucer; };
  };

  freePackageNames = builtins.attrNames freePackages;
  unfreePackageNames = builtins.attrNames unfreePackages;
}
