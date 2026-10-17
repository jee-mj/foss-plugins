{ lib, callPackage, fetchFromGitHub
, juceRuntime ? callPackage ../../lib/juce-runtime.nix { }
, pluginArtifacts ? callPackage ../../lib/plugin-artifacts.nix { }
, basilica-miserere ? callPackage ../basilica-miserere { inherit juceRuntime pluginArtifacts; }
}:
let
  pins = builtins.fromJSON (builtins.readFile ./pins.json);
  roster = import ./inventory.nix;
  common = import ./common-sources.nix;
  newNames = builtins.attrNames roster;
  names = newNames ++ [ "Miserere" ];
  expectedKeys = lib.sort builtins.lessThan (newNames ++ [ "linear" "stretch" ]);
  validPin = name: let p = pins.${name} or { }; in
    builtins.match "[0-9a-f]{40}" (p.revision or "") != null
    && builtins.match "sha256-[A-Za-z0-9+/]{43}=" (p.hash or "") != null;
  inventoryValid = builtins.attrNames pins == expectedKeys
    && builtins.all (name: let p = pins.${name}; in validPin name
      && (p.name or null) == name && (p.identity or null) == roster.${name}.identity
      && p ? audio && p.audio == roster.${name}.audio && (p.version or "") != "") newNames
    && builtins.all (name: validPin name && (pins.${name}.name or null) == name
      && !(pins.${name} ? identity)) [ "linear" "stretch" ]
    && pins.linear.repo == "Signalsmith-Audio/linear"
    && pins.stretch.repo == "Signalsmith-Audio/signalsmith-stretch";
  packages = lib.genAttrs newNames (name: callPackage ./package.nix {
    inherit name juceRuntime pluginArtifacts;
  }) // { Miserere = basilica-miserere; };
  fetch = p: let parts = lib.splitString "/" p.repo; in fetchFromGitHub {
    owner = builtins.elemAt parts 0; repo = builtins.elemAt parts 1;
    rev = p.revision; inherit (p) hash;
  };
  sourcePins = (lib.genAttrs newNames (name: pins.${name} // { repo = "basilica-audio/${name}"; }))
    // common // { inherit (pins) linear stretch; };
  sources = lib.mapAttrs (name: p: {
    inherit (p) revision hash;
    version = p.version or null;
    repo = p.repo;
    sourceOut = toString (fetch p);
    sourceDrv = (fetch p).drvPath;
  }) sourcePins;
  artifactChecks = lib.genAttrs names (name:
    if name == "Miserere" then callPackage ../../tests/basilica-miserere.nix {
      inherit basilica-miserere;
    } else callPackage ../../tests/basilica-native-suite.nix {
      inherit name; plugin = packages.${name};
    });
  digest = path: builtins.hashFile "sha256" path;
  compatibility = callPackage ./nave-compatibility.nix { };
  bindings = lib.genAttrs names (name: {
    schema = 2;
    inherit name;
    identity = if name == "Miserere" then common.Miserere.identity else roster.${name}.identity;
    audio = if name == "Miserere" then common.Miserere.audio else roster.${name}.audio;
    source = sources.${name};
    dependencies = { JUCE = sources.JUCE; }
      // lib.optionalAttrs (name == "Seraph") { inherit (sources) linear stretch; };
    packageDrv = packages.${name}.drvPath;
    packageOutput = toString packages.${name};
    artifactCheckDrv = artifactChecks.${name}.drvPath;
    artifactCheckOutput = toString artifactChecks.${name};
    format = "VST3";
    architecture = "ELF64 x86-64";
    recipe = {
      package = digest (if name == "Miserere" then ../basilica-miserere/default.nix else ./package.nix);
      adapter = digest (if name == "Miserere" then ../basilica-miserere/adapt.py else ./adapt.py);
      artifactTest = digest (if name == "Miserere" then ../../tests/basilica-miserere.nix else ../../tests/basilica-native-suite.nix);
      verifier = digest (if name == "Miserere" then ../../tests/basilica-miserere.nix else ./verify.py);
      receiptCheck = digest ./receipt-check.nix;
      receiptWriter = digest ./write-proof.py;
      runtimeHelper = digest ../../lib/juce-runtime.nix;
      artifactHelper = digest ../../lib/plugin-artifacts.nix;
    };
    modification = if name != "Nave" then null else {
      patchSha256 = digest ./nave-scalar-minimum.patch;
      noticeSha256 = digest ./NOTICE-Nave.md;
      compatibilityDrv = compatibility.drvPath;
      compatibilityOutput = toString compatibility;
    };
  });
  checks = lib.genAttrs names (name: callPackage ./receipt-check.nix {
    binding = bindings.${name}; artifactCheck = artifactChecks.${name};
  });
  sourceConsistent = name:
    toString packages.${name}.src == sources.${name}.sourceOut
    && packages.${name}.src.drvPath == sources.${name}.sourceDrv
    && packages.${name}.version == sources.${name}.version
    && packages.${name}.revision == sources.${name}.revision
    && toString packages.${name}.juceSource == sources.JUCE.sourceOut
    && packages.${name}.juceSource.drvPath == sources.JUCE.sourceDrv;
in
assert lib.assertMsg inventoryValid "Basilica inventory: expected exactly twelve named BA identities/aliases and two pinned dependencies";
{
  inherit names newNames roster sources packages bindings artifactChecks checks sourceConsistent;
}
