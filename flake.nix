{
  description = "Reproducible FOSS audio plugin packages";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # MechanOdd has no declared upstream license.  Keep its public package
      # attribute absent during pure evaluation; callers explicitly opt in via
      # NIXPKGS_ALLOW_UNFREE=1 together with --impure.
      unfreeOptIn = builtins.getEnv "NIXPKGS_ALLOW_UNFREE" == "1";

      packageSetFor = pkgs: pkgs.callPackage ./pkgs { };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          packageSet = packageSetFor pkgs;
        in
        packageSet.freePackages // nixpkgs.lib.optionalAttrs unfreeOptIn packageSet.unfreePackages
      );

      overlays.default = final: prev:
        let
          packageSet = packageSetFor final;
        in
        {
          fossPlugins = packageSet.freePackages // final.lib.optionalAttrs unfreeOptIn packageSet.unfreePackages;
        };

      nixosModules.default = import ./modules;

      checks = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          packageSet = packageSetFor pkgs;
          moduleConfig =
            (nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                self.nixosModules.default
                {
                  system.stateVersion = "26.05";
                }
              ];
            }).config;
        in
        {
          # These checks are intentionally small.  The full artifact-helper
          # fixtures and real plugin derivations follow after this laziness
          # preflight has established a safe MechanOdd public interface.
          free-package-set =
            assert packageSet ? freePackageNames;
            assert packageSet ? unfreePackageNames;
            assert !(builtins.elem "mechanodd" packageSet.freePackageNames);
            assert builtins.elem "mechanodd" packageSet.unfreePackageNames;
            pkgs.runCommand "foss-plugins-free-package-set" { } ''
              touch "$out"
            '';

          module-default =
            assert moduleConfig.programs."foss-plugins".enable == false;
            pkgs.runCommand "foss-plugins-module-default" { } ''
              touch "$out"
            '';
        }
      );
    };
}
