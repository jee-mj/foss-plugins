{
  description = "Isolated Basilica Miserere Windows source-build probe (blocked on JUCE MinGW support)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { self, nixpkgs }:
    let pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      packages.x86_64-linux.default = pkgs.callPackage ./pkgs/basilica-miserere-windows { };
      checks.x86_64-linux.artifacts = pkgs.callPackage ./tests/basilica-miserere-windows.nix { };
    };
}
