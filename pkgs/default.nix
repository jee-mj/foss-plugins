{ callPackage }:

let
  pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  juceRuntime = callPackage ../lib/juce-runtime.nix { };
in
rec {
  # The free package set intentionally excludes unknown-license packages.
  freePackages = {
    amsynth = callPackage ./amsynth { inherit pluginArtifacts; };
    modal-synth = callPackage ./modal-synth { inherit pluginArtifacts juceRuntime; };
    space-dust-synthesizer = callPackage ./space-dust-synthesizer { inherit pluginArtifacts juceRuntime; };
    ultramaster-kr106 = callPackage ./ultramaster-kr106 { inherit pluginArtifacts juceRuntime; };
  };

  unfreePackages = {
    mechanodd = callPackage ./mechanodd-spike.nix { };
  };

  freePackageNames = builtins.attrNames freePackages;
  unfreePackageNames = builtins.attrNames unfreePackages;
}
