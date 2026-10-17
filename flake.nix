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
      productCatalog = builtins.fromJSON (builtins.readFile ./catalog/products.json);

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
          # callPackage also adds override helpers to attribute-set test APIs.
          windowsChecks = prefix: path:
            nixpkgs.lib.mapAttrs' (name: value: nixpkgs.lib.nameValuePair "${prefix}-${name}" value)
              (nixpkgs.lib.filterAttrs (_: value: nixpkgs.lib.isDerivation value)
                (pkgs.callPackage path { }));
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
          product-catalog = pkgs.runCommand "foss-plugins-product-catalog" {
            nativeBuildInputs = [ pkgs.python3 ];
          } ''
            mkdir -p lib tests scripts catalog reports
            cp ${./lib/product_catalog.py} lib/product_catalog.py
            cp ${./scripts/merge-product-reports.py} scripts/merge-product-reports.py
            cp ${./tests/test_product_catalog.py} tests/test_product_catalog.py
            cp ${./tests/product-catalog-identities.json} tests/product-catalog-identities.json
            cp ${./tests/audio-catalog-identities.json} tests/audio-catalog-identities.json
            cp ${./catalog/products.json} catalog/products.json
            python3 - <<'PY'
            import json
            from pathlib import Path
            from lib.product_catalog import load_json, merge_reports
            catalog = load_json('catalog/products.json')
            assert merge_reports(catalog['repositories']) == catalog
            for report in catalog['repositories']:
                Path('reports', report['identity'] + '.json').write_text(json.dumps(report))
            PY
            PRODUCT_REPORTS="$PWD/reports" python3 -m unittest discover -s tests -p test_product_catalog.py -v
            touch "$out"
          '';

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
            assert builtins.length packageSet.freePackageNames == 32;
            assert builtins.length packageSet.unfreePackageNames == 14;
            assert builtins.attrNames packageSet.basilicaFamily.candidateDefinitions == [
              "basilica-apotheosis" "basilica-aureate" "basilica-crypta" "basilica-firmament"
              "basilica-lancet" "basilica-miserere" "basilica-nave" "basilica-overture"
              "basilica-requiem" "basilica-seraph" "basilica-silentium" "basilica-tenebrae" "basilica-triptych"
            ];
            assert builtins.attrNames packageSet.basilicaFamily.candidateChecks
              == builtins.attrNames packageSet.basilicaFamily.candidateDefinitions;
            assert builtins.all (name: builtins.elem name packageSet.freePackageNames)
              (builtins.attrNames packageSet.basilicaFamily.candidateDefinitions);
            assert !(packageSet.freePackages ? basilica-native-suite);
            assert !(packageSet.freePackages ? aggregate);
            assert packageSet.freePackages.basilica-miserere.drvPath
              == packageSet.basilicaFamily.candidateDefinitions.basilica-miserere.drvPath;
            assert builtins.all (name: builtins.elem name packageSet.freePackageNames) [
              "instawidth" "sub-orbit" "reevr" "wolf-shaper" "vaporizer2" "wolf-shaper-windows" "basilica-miserere"
            ];
            assert builtins.all (name: builtins.elem name packageSet.unfreePackageNames) [
              "tonetwist-windows" "drumcloud-windows" "toneshifteq-windows" "gunk-windows" "0xfx-windows"
            ];
            assert packageSet.freePackages.reevr.drvPath == pkgs.reevr.drvPath;
            assert packageSet.freePackages.wolf-shaper.drvPath == pkgs.wolf-shaper.drvPath;
            assert packageSet.freePackages.vaporizer2.drvPath == pkgs.vaporizer2.drvPath;
            assert packageSet.freePackages.wolf-shaper-windows.outputs == [ "out" "installer" ];
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

          instawidth = pkgs.callPackage ./tests/instawidth.nix {
            instawidth = packageSet.freePackages.instawidth;
          };

          sub-orbit = pkgs.callPackage ./tests/sub-orbit.nix {
            sub-orbit = packageSet.freePackages.sub-orbit;
          };

          nixpkgs-audio = pkgs.callPackage ./tests/nixpkgs-audio.nix {
            inherit packageSet;
          };

          wolf-shaper-windows = pkgs.callPackage ./tests/wolf-shaper-windows.nix { };

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

          basilica-miserere = pkgs.callPackage ./tests/basilica-miserere.nix {
            basilica-miserere = packageSet.freePackages.basilica-miserere;
          };
        } // builtins.removeAttrs packageSet.basilicaFamily.candidateChecks [ "basilica-miserere" ]
        // nixpkgs.lib.optionalAttrs unfreeOptIn ({
          toneshifteq-windows = pkgs.callPackage ./tests/toneshifteq-windows.nix { };
          tonetwist-windows = pkgs.callPackage ./tests/tonetwist-windows.nix { };
          drumcloud-windows = pkgs.callPackage ./tests/drumcloud-windows.nix { };
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
        } // windowsChecks "gunk-windows" ./tests/gunk-windows.nix
          // windowsChecks "0xfx-windows" ./tests/0xfx-windows.nix)
      );
    };
}
