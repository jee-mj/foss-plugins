{ callPackage }:

let
  pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
in
rec {
  # The free package set intentionally excludes unknown-license packages.
  freePackages = {
    amsynth = callPackage ./amsynth { inherit pluginArtifacts; };
  };

  unfreePackages = {
    mechanodd = callPackage ./mechanodd-spike.nix { };
  };

  freePackageNames = builtins.attrNames freePackages;
  unfreePackageNames = builtins.attrNames unfreePackages;
}
