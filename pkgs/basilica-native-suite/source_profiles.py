"""Offline metadata-only evaluation with two immutable public nixpkgs sources."""
import json
import subprocess
from evidence import HERE, ROOT

def evaluate_profiles(family=None):
    profiles = json.loads((HERE/'public-nixpkgs-profiles.json').read_text())
    results = {}
    family_expression = str(family) if family is not None else '(f.outPath + "/pkgs/basilica-native-suite")'
    for name, profile in profiles.items():
        expression = f'''let
          f = builtins.getFlake "git+file://{ROOT}";
          public = builtins.fetchTree (builtins.fromJSON {json.dumps(json.dumps(profile))});
          p = import public.outPath {{system="x86_64-linux";}};
          s = p.callPackage {family_expression} {{}};
          paths = builtins.mapAttrs (_: value: {{drv=value.drvPath;out=value.outPath;}});
        in {{
          candidateDefinitions = paths (s.candidateDefinitions or {{}});
          candidateChecks = paths (s.candidateChecks or {{}});
          namedPackages = paths s.namedPackages;
          checks = paths s.checks;
          aggregate = s ? aggregate;
          aggregateOutput = if s ? aggregate then s.aggregate.outPath else null;
          profiles = builtins.mapAttrs (_: value: {{
            inherit (value) status;
            sourceStatus = value.sourceStatus or "missing";
            currentDerivationStatus = value.currentDerivationStatus or "missing";
          }}) s.profiles;
        }}'''
        command = ['nix','eval','--offline','--impure','--no-write-lock-file',
                   '--option','allow-import-from-derivation','false','--json','--expr',expression]
        result = subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
        if result.returncode:
            raise RuntimeError(result.stderr)
        assert 'will be built' not in result.stderr
        results[name] = dict(publicSource=profile,metadata=json.loads(result.stdout))
    return results

def validate_profiles(results):
    expected = {'basilica-'+name for name in (
        'overture','tenebrae','nave','silentium','requiem','seraph','aureate',
        'firmament','triptych','apotheosis','crypta','lancet','miserere')}
    for name, result in results.items():
        value = result['metadata']
        assert set(value['candidateDefinitions']) == set(value['candidateChecks']) == expected, name
        assert len(value['profiles']) == 13
        assert all(p['sourceStatus'] == 'source-audited' for p in value['profiles'].values())
        if name == 'verified-fd146':
            assert value['candidateDefinitions'] == value['namedPackages']
            assert value['candidateChecks'] == value['checks']
            assert len(value['namedPackages']) == len(value['checks']) == 13
            assert value['aggregate']
            assert all(p['currentDerivationStatus'] == 'verified' for p in value['profiles'].values())
        else:
            assert not value['namedPackages'] and not value['checks'] and not value['aggregate']
            assert all(p['status'] == p['currentDerivationStatus'] == 'stale' for p in value['profiles'].values())
    return results

if __name__ == '__main__':
    results = validate_profiles(evaluate_profiles())
    receipt = dict(scope='offline metadata-only public source profiles; IFD disabled; no builds',
                   command='python3 pkgs/basilica-native-suite/source_profiles.py',profiles=results)
    (HERE/'source-profile-verification.json').write_text(json.dumps(receipt,indent=2)+'\n')
    for name, result in results.items():
        value = result['metadata']
        print(name,dict(candidateDefinitions=len(value['candidateDefinitions']),
                       candidateChecks=len(value['candidateChecks']),namedPackages=len(value['namedPackages']),
                       verifiedChecks=len(value['checks']),aggregate=value['aggregate']))
