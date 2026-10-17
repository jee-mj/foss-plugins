{
  description = "Isolated JQ Gunk Windows source cross-build";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { self, nixpkgs }:
    let pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      packages.x86_64-linux.default = pkgs.callPackage ./pkgs/gunk-windows { };
      checks.x86_64-linux = pkgs.callPackage ./tests/gunk-windows.nix { };
    };
}
