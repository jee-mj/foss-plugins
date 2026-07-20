{ runCommand, system, nixosSystem, fossPluginsModule }:

let
  evalModule = settings:
    (nixosSystem {
      inherit system;
      modules = [
        fossPluginsModule
        {
          system.stateVersion = "26.05";
          programs."foss-plugins" = settings;
        }
      ];
    }).config;

  forceSystemPackages = config:
    builtins.all (package: builtins.seq package true) config.environment.systemPackages;

  validSelection = builtins.tryEval (forceSystemPackages (evalModule {
    enable = true;
    packages = [ "amsynth" ];
  }));

  invalidSelection = builtins.tryEval (forceSystemPackages (evalModule {
    enable = true;
    packages = [ "not-a-plugin" ];
  }));
in
assert (evalModule { }).programs."foss-plugins".enable == false;
assert validSelection.success;
assert !invalidSelection.success;
runCommand "foss-plugins-module-options" { } ''
  touch "$out"
''
