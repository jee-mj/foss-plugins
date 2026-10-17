{
  description = "Isolated unexported 0xFX Windows source build";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
  outputs = { self, nixpkgs }:
    let p = import nixpkgs { system = "x86_64-linux"; };
    in {
      packages.x86_64-linux.default = p.callPackage ./pkgs/0xfx-windows { };
      checks.x86_64-linux = nixpkgs.lib.filterAttrs (_: value: nixpkgs.lib.isDerivation value)
        (p.callPackage ./tests/0xfx-windows.nix { });
    };
}
