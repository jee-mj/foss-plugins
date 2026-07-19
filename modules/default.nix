{ config, lib, pkgs, ... }:

let
  cfg = config.programs."foss-plugins";
  packageSet = pkgs.callPackage ../pkgs { };
in
{
  options.programs."foss-plugins" = {
    enable = lib.mkEnableOption "FOSS audio plugin packages";

    packages = lib.mkOption {
      type = lib.types.listOf (lib.types.enum packageSet.freePackageNames);
      default = [ ];
      description = "Free plugin package names to install.";
    };

    unfreePackages = lib.mkOption {
      type = lib.types.listOf (lib.types.enum packageSet.unfreePackageNames);
      default = [ ];
      description = "Explicitly selected unknown-license plugin package names.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      map (name: packageSet.freePackages.${name}) cfg.packages
      ++ map (name: packageSet.unfreePackages.${name}) cfg.unfreePackages;
  };
}
