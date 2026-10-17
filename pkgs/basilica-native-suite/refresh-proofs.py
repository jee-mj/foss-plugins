"""Build all current candidate checks without relying on eligibility results."""
import json
import subprocess
from evidence import HERE, ROOT, collect, manifest, prefix

current = manifest()
command = ['nix','build','--impure','--no-link','--no-write-lock-file','--json',
           '--max-jobs','1','--cores','4','--expr',prefix()+'builtins.attrValues c.checks']
outputs = json.loads(subprocess.check_output(command,cwd=ROOT,text=True))
expected = {value['checkOutput'] for value in current['members'].values()}
assert {value['outputs']['out'] for value in outputs} == expected
previous = json.loads((HERE/'results.json').read_text())
collect(current,previous)
receipt = dict(buildExitCode=0,checks=outputs,
               command=[argument.replace(str(ROOT),'REPOSITORY') for argument in command],
               scope='unsigned observed local sandbox receipts; no result-dependent candidates')
(HERE/'proof-capture.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('Captured thirteen actual current check receipts; stage proofs and results before API evaluation.')
