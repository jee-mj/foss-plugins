"""Compact observed verifier receipt. Contains no own check-output identity."""
import hashlib
import json
import sys
from pathlib import Path

binding = json.loads(Path(sys.argv[1]).read_text())
artifact = Path(sys.argv[2])
output = Path(sys.argv[3])
payload = (artifact/'verification.json').read_bytes()
verification = json.loads(payload)
assert verification['plugin'] == binding['packageOutput']
assert verification['format'] == binding['format'] == 'VST3'
assert verification['architecture'] == binding['architecture'] == 'ELF64 x86-64'
assert len(verification['sha256']) == 64
assert 'RTLD_NOW' in verification['checks']
notices = verification.pop('notices',None)
if notices is not None:
    verification['noticeFiles'] = len(notices)
    verification['noticeManifestSha256'] = hashlib.sha256(json.dumps(notices,sort_keys=True).encode()).hexdigest()
proof = dict(schema=2,binding=binding,exitCode=0,verification=verification,
             verificationSha256=hashlib.sha256(payload).hexdigest(),sourceModification=None)
if binding['name'] == 'Nave':
    compatibility = json.loads((artifact/'compatibility.json').read_text())
    assert compatibility['patchSha256'] == binding['modification']['patchSha256']
    assert compatibility['sourceRevision'] == binding['source']['revision']
    assert compatibility['compileExitCode'] == compatibility['runtimeExitCode'] == 0
    assert compatibility['simdEnabled'] is True
    assert compatibility['patchedCalls'] == 2
    assert compatibility['scalarBoundaryCases'] == 14 and compatibility['sourceClampCases'] == 6
    assert len(json.loads((artifact/'assets.json').read_text())) == 16
    proof['sourceModification'] = dict(compatibility=compatibility,
        assets=json.loads((artifact/'assets.json').read_text()),
        patchSha256=binding['modification']['patchSha256'],noticeSha256=binding['modification']['noticeSha256'])
output.mkdir()
(output/'proof.json').write_text(json.dumps(proof,indent=2,sort_keys=True)+'\n')
