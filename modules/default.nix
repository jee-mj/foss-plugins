{ config, lib, pkgs, ... }:

let
  cfg = config.programs."foss-plugins";
  packageSet = pkgs.callPackage ../pkgs { };

  installedPackages =
    map (name: packageSet.freePackages.${name}) cfg.packages
    ++ map (name: packageSet.unfreePackages.${name}) cfg.unfreePackages;

  # Generate shell snippet to symlink all bundles from a given lib/
  # subdirectory into the matching per-user dot-directory.
  linkFormat = libDir: dotDir:
    lib.concatMapStrings (pkg: ''
      if [ -d "${pkg}/${libDir}" ]; then
        for bundle in "${pkg}/${libDir}"/*; do
          [ -e "$bundle" ] || continue
          name=$(basename "$bundle")
          ln -sfn "$bundle" "$user_home/${dotDir}/$name"
        done
      fi
    '') installedPackages;
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
    # Install plugins into the system closure.
    # NixOS merges lib/ trees into /run/current-system/sw/lib/,
    # which is already in VST3_PATH / LV2_PATH / CLAP_PATH.
    environment.systemPackages = installedPackages;

    # Symlink plugins into per-user standard directories as a backstop
    # for hosts that don't scan the merged system profile.
    system.activationScripts.fossPlugins = lib.mkIf (installedPackages != [ ]) ''
      echo "Linking foss-plugins into per-user plugin directories..."
      for user_home in /home/*; do
        mkdir -p "$user_home/.vst3" "$user_home/.lv2" "$user_home/.clap"
        ${linkFormat "lib/vst3" ".vst3"}
        ${linkFormat "lib/lv2"  ".lv2"}
        ${linkFormat "lib/clap" ".clap"}
      done
    '';
  };
}
