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
      # Discovery metadata is independent of package availability and unfree opt-in.
      catalog = builtins.fromJSON (builtins.readFile ./catalog/audio-104.json);

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
          # Metadata validation does not build or execute upstream plugins.
          audio-catalog = pkgs.runCommand "foss-plugins-audio-catalog" {
            nativeBuildInputs = [ pkgs.python3 ];
          } ''
            mkdir -p lib tests/fixtures scripts catalog docs
            cp ${./lib/catalog_acceleration.py} lib/catalog_acceleration.py
            cp ${./tests/audio-catalog.py} tests/audio-catalog.py
            cp ${./tests/test_catalog_acceleration.py} tests/test_catalog_acceleration.py
            cp ${./tests/test_render_acceleration_matrix.py} tests/test_render_acceleration_matrix.py
            cp ${./tests/audio-catalog-identities.json} tests/audio-catalog-identities.json
            cp -R ${./tests/fixtures/acceleration} tests/fixtures/acceleration
            cp ${./scripts/merge-acceleration.py} scripts/merge-acceleration.py
            cp ${./scripts/render-acceleration-matrix.py} scripts/render-acceleration-matrix.py
            cp ${./catalog/audio-104.json} catalog/audio-104.json
            cp ${./docs/acceleration-matrix.md} docs/acceleration-matrix.md
            python3 tests/audio-catalog.py --require-assessed
            python3 -m unittest discover -s tests -p 'test_*acceleration*.py' -v
            python3 scripts/render-acceleration-matrix.py --check
            touch "$out"
          '';

          # This laziness preflight establishes a safe MechanOdd public interface
          # before the artifact-helper fixtures and real plugin derivations.
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

          downspout = pkgs.callPackage ./tests/downspout.nix {
            inherit packageSet;
          };

          toneshifteq = pkgs.callPackage ./tests/toneshifteq.nix {
            inherit packageSet;
          };

          peakeater = pkgs.callPackage ./tests/peakeater.nix {
            peakeater = packageSet.freePackages.peakeater;
          };

          intersect = pkgs.callPackage ./tests/intersect.nix {
            intersect = packageSet.freePackages.intersect;
          };

          intersect-provider = pkgs.callPackage ./tests/intersect-provider.nix {
            intersect = packageSet.freePackages.intersect;
          };

          audio-restoration-vst = pkgs.callPackage ./tests/audio-restoration-vst.nix {
            audio-restoration-vst = packageSet.freePackages.audio-restoration-vst;
          };

          audio-restoration-vst-provider = pkgs.callPackage ./tests/audio-restoration-vst-provider.nix {
            audio-restoration-vst = packageSet.freePackages.audio-restoration-vst;
          };
        } // nixpkgs.lib.optionalAttrs unfreeOptIn {
          intersect-cuda12 = pkgs.callPackage ./tests/intersect.nix {
            intersect = packageSet.unfreePackages.intersect-cuda12;
          };
          intersect-cuda12-provider = pkgs.callPackage ./tests/intersect-provider.nix {
            intersect = packageSet.unfreePackages.intersect-cuda12;
          };
          intersect-migraphx = pkgs.callPackage ./tests/intersect.nix {
            intersect = packageSet.unfreePackages.intersect-migraphx;
          };
          intersect-migraphx-provider = pkgs.callPackage ./tests/intersect-provider.nix {
            intersect = packageSet.unfreePackages.intersect-migraphx;
          };
          audio-restoration-vst-cuda = pkgs.callPackage ./tests/audio-restoration-vst-provider.nix {
            audio-restoration-vst = packageSet.freePackages.audio-restoration-vst;
            cudaLoad = true;
          };
        }
      );
    };
}
