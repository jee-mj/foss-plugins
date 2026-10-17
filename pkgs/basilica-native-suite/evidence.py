"""Unsigned local evidence: independently evaluated candidates and exact receipts."""
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

def prefix(root=ROOT):
    return f'''let f = builtins.getFlake "git+file://{root}";
      p = import f.inputs.nixpkgs {{system="x86_64-linux";}};
      c = p.callPackage (f.outPath + "/pkgs/basilica-native-suite/candidates.nix") {{}};
    in '''

def manifest(root=ROOT):
    expression = prefix(root)+'''{
      sources = c.sources;
      members = builtins.listToAttrs (map (name: {inherit name; value={
        binding=c.bindings.${name};
        sourceConsistent=c.sourceConsistent name;
        checkDrv=c.checks.${name}.drvPath;
        checkOutput=c.checks.${name}.outPath;
      };}) c.names);
    }'''
    return json.loads(subprocess.check_output(['nix','eval','--impure','--no-write-lock-file','--json','--expr',expression],cwd=root))

def require(condition, description):
    if not condition:
        raise ValueError('stale receipt: '+description)

def equal(left, right):
    # JSON-typed equality, including the distinction between false and zero.
    return json.dumps(left,sort_keys=True) == json.dumps(right,sort_keys=True)

def validate_record(name, record, candidate, archive, audits, actual=True):
    """Validate input evidence; never relabel or mutate the supplied record."""
    b = candidate['binding']
    source = b['source']
    for key, wanted in dict(schema=2,name=name,identity=b['identity'],audio=b['audio'],
                            version=source['version'],revision=source['revision'],sourceHash=source['hash'],
                            status='passed',exitCode=0,format='VST3',packageDrv=b['packageDrv'],
                            packageOutput=b['packageOutput'],checkDrv=candidate['checkDrv'],
                            checkOutput=candidate['checkOutput'],binding=b).items():
        require(key in record and equal(record[key],wanted),name+': '+key)
    require(candidate['sourceConsistent'],name+': actual package source identity')
    for dependency, pin in {name:source,**b['dependencies']}.items():
        audit = audits.get(dependency,{})
        require(audit.get('revision') == pin['revision'] and audit.get('hash') == pin['hash']
                and audit.get('unexpected') == [],name+': consumed source audit '+dependency)
    payload = Path(archive).read_bytes()
    require(hashlib.sha256(payload).hexdigest() == record.get('receiptSha256'),name+': receipt digest')
    proof = json.loads(payload)
    require(equal(proof.get('schema'),2) and equal(proof.get('binding'),b) and equal(proof.get('exitCode'),0),name+': proof binding')
    for key in ('verification','verificationSha256','sourceModification'):
        require(equal(record.get(key),proof.get(key)),name+': '+key)
    verification = proof['verification']
    require(verification.get('plugin') == b['packageOutput'] and verification.get('format') == 'VST3'
            and verification.get('architecture') == 'ELF64 x86-64'
            and 'RTLD_NOW' in verification.get('checks',[]),name+': verifier output')
    if actual:
        current = Path(candidate['checkOutput'])/'proof.json'
        require(current.read_bytes() == payload,name+': archive differs from actual check output')
        raw = (Path(b['artifactCheckOutput'])/'verification.json').read_bytes()
        require(hashlib.sha256(raw).hexdigest() == proof['verificationSha256'],name+': actual verifier receipt')
    if name == 'Nave':
        modification = proof['sourceModification']
        compatibility = modification['compatibility']
        require(modification['patchSha256'] == compatibility['patchSha256'] == b['modification']['patchSha256'],name+': patch evidence')
        require(modification['noticeSha256'] == b['modification']['noticeSha256'],name+': modified source notice')
        require(compatibility['sourceRevision'] == source['revision'] and compatibility['compileExitCode'] == 0
                and compatibility['runtimeExitCode'] == 0 and compatibility['simdEnabled'] is True
                and compatibility['patchedCalls'] == 2 and compatibility['scalarBoundaryCases'] == 14
                and compatibility['sourceClampCases'] == 6 and len(modification['assets']) == 16,name+': compatibility/asset evidence')
        if actual:
            live = json.loads((Path(b['artifactCheckOutput'])/'compatibility.json').read_text())
            require(live == compatibility,name+': actual compatibility receipt')
    return proof

def collect(candidate_manifest, previous, directory=HERE, names=None):
    """Capture only actual current checks, after a successful nix build."""
    directory = Path(directory)
    audits = json.loads((directory/'asset-audit.json').read_text())
    captured = {}
    archives = {}
    for name, candidate in candidate_manifest['members'].items():
        if names is not None and name not in names:
            continue
        payload = (Path(candidate['checkOutput'])/'proof.json').read_bytes()
        proof = json.loads(payload)
        b = proof['binding']
        s = b['source']
        record = dict(schema=2,name=name,identity=b['identity'],audio=b['audio'],version=s['version'],
                      revision=s['revision'],sourceHash=s['hash'],format='VST3',status='passed',exitCode=0,
                      packageDrv=b['packageDrv'],packageOutput=b['packageOutput'],checkDrv=candidate['checkDrv'],
                      checkOutput=candidate['checkOutput'],binding=b,receiptSha256=hashlib.sha256(payload).hexdigest(),
                      verification=proof['verification'],verificationSha256=proof['verificationSha256'],
                      sourceModification=proof['sourceModification'])
        old = previous.get(name,{})
        # History is labelled history, never rewritten into current proof.
        if 'previousAttempt' in old:
            record['previousAttempt'] = old['previousAttempt']
        if 'attempt' in old:
            record['attempt'] = old['attempt']
        validate_record(name,record,candidate,Path(candidate['checkOutput'])/'proof.json',audits)
        captured[name] = record
        archives[name] = payload
    (directory/'proofs').mkdir(exist_ok=True)
    for name, payload in archives.items():
        (directory/'proofs'/f'{name}.json').write_bytes(payload)
    merged = previous | captured if names is not None else captured
    (directory/'results.json').write_text(json.dumps(merged,indent=2)+'\n')
    return merged
