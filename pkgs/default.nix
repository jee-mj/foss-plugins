{ callPackage }:

rec {
  # The free package set intentionally excludes unknown-license packages.
  freePackages = {
    "free-spike" = callPackage ./free-spike.nix { };
  };

  unfreePackages = {
    mechanodd = callPackage ./mechanodd-spike.nix { };
  };

  freePackageNames = builtins.attrNames freePackages;
  unfreePackageNames = builtins.attrNames unfreePackages;
}
