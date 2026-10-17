"""Build/validate accepted current API checks and its metadata-correct aggregate."""
import json
import subprocess
from evidence import HERE, ROOT, manifest
from finalize import validate_all

current = manifest()
validate_all(HERE,current)
prefix = f'''let f = builtins.getFlake "git+file://{ROOT}";
  p = import f.inputs.nixpkgs {{system="x86_64-linux";}};
  c = p.callPackage (f.outPath + "/pkgs/basilica-native-suite/candidates.nix") {{}};
  s = p.callPackage (f.outPath + "/pkgs/basilica-native-suite") {{}};
in '''
expression = prefix+'''{
  packages = builtins.mapAttrs (_: package: package.outPath) s.namedPackages;
  packageDrvs = builtins.mapAttrs (_: package: package.drvPath) s.namedPackages;
  checks = builtins.mapAttrs (_: check: check.outPath) s.checks;
  checkDrvs = builtins.mapAttrs (_: check: check.drvPath) s.checks;
  artifactChecks = builtins.listToAttrs (map (name: {name="basilica-${p.lib.toLower name}";value=c.artifactChecks.${name}.outPath;}) c.names);
  profiles = builtins.mapAttrs (_: profile: profile.status) s.profiles;
  aggregate = s ? aggregate;
  aggregateOutput = if s ? aggregate then s.aggregate.outPath else null;
  aggregateDrv = if s ? aggregate then s.aggregate.drvPath else null;
  aggregateMetadata = if s ? aggregate then {
    inherit (s.aggregate.meta) description platforms;
    licenses = map (license: {inherit (license) spdxId free;}) s.aggregate.meta.license;
  } else null;
}'''
metadata = json.loads(subprocess.check_output(['nix','eval','--impure','--no-write-lock-file','--json','--expr',expression],cwd=ROOT))
assert len(metadata['packages']) == len(metadata['checks']) == len(metadata['profiles']) == 13
assert metadata['aggregate'] is True
assert metadata['packages']['basilica-miserere'] == '/nix/store/415izqbh7cjcaki676h2nh33kygn5pn3-basilica-miserere-0.7.0'
for name, candidate in current['members'].items():
    attribute = 'basilica-'+name.lower()
    assert metadata['packageDrvs'][attribute] == candidate['binding']['packageDrv']
    assert metadata['checks'][attribute] == candidate['checkOutput']
    assert metadata['checkDrvs'][attribute] == candidate['checkDrv']
    assert metadata['profiles'][name] == ('reused-reviewed-source-build' if name == 'Miserere' else 'passed')
command = ['nix','build','--impure','--no-link','--no-write-lock-file','--json',
           '--max-jobs','1','--cores','4','--expr',prefix+'builtins.attrValues s.checks ++ [ s.aggregate ]']
outputs = json.loads(subprocess.check_output(command,cwd=ROOT,text=True))
assert {value['outputs']['out'] for value in outputs} == set(metadata['checks'].values()) | {metadata['aggregateOutput']}
validate_all(HERE,current)
receipt = dict(metadata=metadata,buildExitCode=0,checksBuilt=outputs,
               command=[argument.replace(str(ROOT),'REPOSITORY') for argument in command],
               scope='unsigned local evidence, current candidate identities, thirteen accepted profiles and checked aggregate')
(HERE/'api-verification.json').write_text(json.dumps(receipt,indent=2)+'\n')
print(json.dumps(metadata,indent=2))
