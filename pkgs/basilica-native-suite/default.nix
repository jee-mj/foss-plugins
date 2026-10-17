{ lib, callPackage, symlinkJoin
, juceRuntime ? callPackage ../../lib/juce-runtime.nix { }
, pluginArtifacts ? callPackage ../../lib/plugin-artifacts.nix { }
, basilica-miserere ? callPackage ../basilica-miserere { inherit juceRuntime pluginArtifacts; }
}:
let
  # Candidates deliberately do not import results, archives, audits or this API.
  candidates = callPackage ./candidates.nix { inherit juceRuntime pluginArtifacts basilica-miserere; };
  results = if builtins.pathExists ./results.json then builtins.fromJSON (builtins.readFile ./results.json) else { };
  audits = builtins.fromJSON (builtins.readFile ./asset-audit.json);
  sourceAudited = name: let a = audits.${name} or { }; s = candidates.sources.${name}; in
    (a.revision or null) == s.revision && (a.hash or null) == s.hash && (a.unexpected or null) == [ ];
  sourceEligible = name: sourceAudited name
    && builtins.all sourceAudited (builtins.attrNames candidates.bindings.${name}.dependencies)
    && candidates.sourceConsistent name;
  proofFor = name: let path = ./proofs + "/${name}.json"; in
    if builtins.pathExists path then {
      data = builtins.fromJSON (builtins.readFile path);
      sha256 = builtins.hashFile "sha256" path;
    } else { data = { }; sha256 = null; };
  eligible = name:
    let
      r = results.${name} or { };
      archived = proofFor name;
      proof = archived.data;
      b = candidates.bindings.${name};
      verification = proof.verification or { };
      source = candidates.sources.${name};
    in sourceEligible name
      && (r.schema or null) == 2 && (proof.schema or null) == 2
      && (r.status or null) == "passed" && (r.exitCode or null) == 0 && (proof.exitCode or null) == 0
      && (r.name or null) == name && (r.identity or null) == b.identity && r ? audio && r.audio == b.audio
      && (r.version or null) == source.version && (r.revision or null) == source.revision
      && (r.sourceHash or null) == source.hash && (r.format or null) == "VST3"
      && (r.packageOutput or null) == b.packageOutput && (r.packageDrv or null) == b.packageDrv
      && (r.checkOutput or null) == toString candidates.checks.${name}
      && (r.checkDrv or null) == candidates.checks.${name}.drvPath
      && (r.binding or null) == b && (proof.binding or null) == b
      && (r.receiptSha256 or null) == archived.sha256 && archived.sha256 != null
      && (r.verification or null) == verification
      && (r.verificationSha256 or null) == (proof.verificationSha256 or null)
      && (verification.plugin or null) == b.packageOutput
      && (verification.format or null) == "VST3" && (verification.architecture or null) == "ELF64 x86-64"
      && builtins.match "[0-9a-f]{64}" (verification.sha256 or "") != null
      && builtins.elem "RTLD_NOW" (verification.checks or [ ])
      && (r.sourceModification or null) == (proof.sourceModification or null)
      && (name != "Nave" || (
        (proof.sourceModification.compatibility.patchSha256 or null) == b.modification.patchSha256
        && (proof.sourceModification.compatibility.sourceRevision or null) == source.revision
        && (proof.sourceModification.noticeSha256 or null) == b.modification.noticeSha256
        && (proof.sourceModification.compatibility.compileExitCode or null) == 0
        && (proof.sourceModification.compatibility.runtimeExitCode or null) == 0
        && (proof.sourceModification.compatibility.simdEnabled or false)));
  accepted = builtins.filter eligible candidates.names;
  sourceAuditedNames = builtins.filter sourceEligible candidates.names;
  attr = name: "basilica-${lib.toLower name}";
  packages = lib.listToAttrs (map (name: lib.nameValuePair (attr name) candidates.packages.${name}) accepted);
  checks = lib.listToAttrs (map (name: lib.nameValuePair (attr name) candidates.checks.${name}) accepted);
  complete = builtins.length accepted == 13 && builtins.all eligible candidates.names;
  members = builtins.attrValues packages;
  declared = p: p ? meta && p.meta ? license && p.meta ? description && p.meta.description != ""
    && builtins.elem "x86_64-linux" (p.meta.platforms or [ ])
    && lib.flatten (lib.toList p.meta.license) != [ ]
    && builtins.all (license: builtins.isAttrs license && (license.free or false)
      && (license.spdxId or "") != "") (lib.flatten (lib.toList p.meta.license));
  licenses = lib.unique (lib.concatMap (p: lib.flatten (lib.toList p.meta.license)) members);
in {
  # Portable experimental definitions are source-audited, not build-verified.
  candidateDefinitions = lib.listToAttrs (map (name: lib.nameValuePair (attr name) candidates.packages.${name}) sourceAuditedNames);
  candidateChecks = lib.listToAttrs (map (name: lib.nameValuePair (attr name) candidates.checks.${name}) sourceAuditedNames);
  namedPackages = packages;
  inherit checks;
  profiles = lib.genAttrs candidates.names (name: {
    inherit (candidates.bindings.${name}) identity audio;
    inherit (candidates.sources.${name}) version revision hash;
    format = "VST3";
    support = "experimental-local-linux";
    sourceStatus = if sourceEligible name then "source-audited" else "blocked";
    currentDerivationStatus = if eligible name then "verified"
      else if results ? ${name} then "stale" else "not-tested";
    status = if eligible name then (if name == "Miserere" then "reused-reviewed-source-build" else "passed")
      else if results ? ${name} then "stale" else "not-tested";
    reason = if eligible name then "current candidate and archived sandbox receipt match"
      else if sourceEligible name then "source-audited experimental recipe; current derivation is not verified by the archived receipt"
      else "a required source identity or clean audit is absent or stale";
  } // lib.optionalAttrs (name == "Nave" && eligible name) {
    modifiedSource = results.Nave.sourceModification;
  });
} // lib.optionalAttrs complete (
  assert lib.assertMsg (builtins.all declared members) "Basilica aggregate metadata: every member must declare free licenses, description and Linux platform";
  {
    aggregate = symlinkJoin {
      name = "basilica-native-suite-experimental";
      paths = members;
      postBuild = lib.concatMapStringsSep "\n" (check: "test -s ${check}/proof.json") (builtins.attrValues checks);
      meta = {
        description = "Experimental locally verified thirteen-product Basilica Linux VST3 suite";
        platforms = [ "x86_64-linux" ];
        license = licenses;
      };
    };
  })
