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
          packageMetadata = pkgs.callPackage ./lib/package-metadata.nix { };
          pluginArtifacts = pkgs.callPackage ./lib/plugin-artifacts.nix { };
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

          package-metadata =
            let
              forceFreePackageAssertions = packages:
                builtins.all (package: builtins.seq package true) (
                  builtins.attrValues (packageMetadata.assertFreePackages packages)
                );

              assertRejected = license:
                !(builtins.tryEval (
                  forceFreePackageAssertions {
                    fixture = { meta.license = license; };
                  }
                )).success;
            in
            assert builtins.length (packageMetadata.normalizeLicenses pkgs.lib.licenses.mit) == 1;
            assert packageMetadata.isFreeLicense pkgs.lib.licenses.mit;
            assert assertRejected pkgs.lib.licenses.unfree;
            assert assertRejected { free = true; };
            assert assertRejected [ pkgs.lib.licenses.mit pkgs.lib.licenses.unfree ];
            assert forceFreePackageAssertions packageSet.freePackages;
            assert !(builtins.elem "mechanodd" packageSet.freePackageNames);
            assert !(builtins.elem "rdpiano" packageSet.freePackageNames);
            pkgs.runCommand "foss-plugins-package-metadata" { } ''
              touch "$out"
            '';

          module-options = pkgs.callPackage ./tests/module-options.nix {
            inherit system;
            nixosSystem = nixpkgs.lib.nixosSystem;
            fossPluginsModule = self.nixosModules.default;
          };

          plugin-artifacts = pkgs.callPackage ./tests/plugin-artifacts.nix {
            inherit pluginArtifacts;
          };
        }
      );
    };
}
