{ config, lib, pkgs, ... }:

let
  cfg = config.programs."foss-plugins";
  packageSet = pkgs.callPackage ../pkgs { };

  installedPackages =
    map (name: packageSet.freePackages.${name}) cfg.packages
    ++ map (name: packageSet.unfreePackages.${name}) cfg.unfreePackages;

  # Build colon-separated search paths for each plugin format.
  pluginPath = format: dir:
    let
      dirs = map (p: "${p}/${dir}") installedPackages;
    in
    if dirs == [ ] then null else builtins.concatStringsSep ":" dirs;
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
    # Install plugins into system closure.
    environment.systemPackages = installedPackages;

    # Set DAW search paths so hosts (Ardour, Carla, Reaper, etc.) can find them.
    environment.variables = lib.mkMerge [
      (lib.mkIf (pluginPath "vst3" "lib/vst3" != null) {
        VST3_PATH = pluginPath "vst3" "lib/vst3";
      })
      (lib.mkIf (pluginPath "lv2" "lib/lv2" != null) {
        LV2_PATH = pluginPath "lv2" "lib/lv2";
      })
      (lib.mkIf (pluginPath "clap" "lib/clap" != null) {
        CLAP_PATH = pluginPath "clap" "lib/clap";
      })
    ];

    # Symlink plugins into standard per-user directories so hosts that
    # don't honour VST3_PATH/LV2_PATH/CLAP_PATH can still find them.
    system.activationScripts.fossPlugins = lib.mkIf (installedPackages != [ ]) ''
      echo "Linking foss-plugins into standard plugin directories..."

      link_plugins() {
        local fmt="$1" dir="$2" target="$3"
        if [ -d "$target" ]; then
          for pkg in ${lib.concatStringsSep " " (map (p: "${p}/${dir}") installedPackages)}; do
            if [ -d "$pkg" ]; then
              for bundle in "$pkg"/*; do
                name=$(basename "$bundle")
                ln -sfn "$bundle" "$target/$name"
              done
            fi
          done
        fi
      }

      # Per-user directories
      for user_home in /home/*; do
        user=$(basename "$user_home")
        link_plugins "vst3" "lib/vst3" "$user_home/.vst3"
        link_plugins "lv2"  "lib/lv2"  "$user_home/.lv2"
        link_plugins "clap" "lib/clap" "$user_home/.clap"
      done
    '';
  };
}
