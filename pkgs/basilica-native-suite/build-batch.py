"""Bounded source-build runner; capture only genuine current check receipts."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from evidence import HERE, ROOT, collect, manifest, prefix, validate_record

current = manifest()
results = json.loads((HERE/'results.json').read_text()) if (HERE/'results.json').exists() else {}
audits = json.loads((HERE/'asset-audit.json').read_text())
selected = sys.argv[1:]
assert set(selected) <= set(current['members']) - {'Miserere'}, 'only the twelve new products may be source-built'
for name, candidate in current['members'].items():
    if name == 'Miserere' or (selected and name not in selected):
        continue
    previous = results.get(name,{})
    if not selected:
        try:
            validate_record(name,previous,candidate,HERE/'proofs'/f'{name}.json',audits)
            continue
        except (ValueError,KeyError,FileNotFoundError):
            pass
    attempt = previous.get('attempt',0)+1
    assert attempt <= 2, f'{name}: source-build attempt budget exhausted; use refresh-proofs.py for verification-only refresh'
    command = ['nix','build','--impure','--no-link','--no-write-lock-file','--json',
               '--max-jobs','1','--cores','4','--expr',prefix()+f'c.checks.{name}']
    print('BUILD',name,flush=True)
    try:
        result = subprocess.run(command,cwd=ROOT,capture_output=True,text=True,timeout=1800)
    except subprocess.TimeoutExpired as error:
        stderr = error.stderr or b''
        if isinstance(stderr,bytes):
            stderr = stderr.decode(errors='replace')
        result = subprocess.CompletedProcess(command,124,'',stderr+'\n1800-second build limit exceeded\n')
    (Path(tempfile.gettempdir())/f'basilica-native-{name}.log').write_text(result.stderr)
    if result.returncode == 0:
        require_output = json.loads(result.stdout)[0]['outputs']['out']
        assert require_output == candidate['checkOutput']
        results[name] = previous | {'attempt':attempt}
        results = collect(current,results,names=[name])
    else:
        results[name] = dict(status='failed',exitCode=result.returncode,attempt=attempt,
                             attemptedBinding=candidate['binding'],diagnostic=result.stderr[-6000:].replace(str(ROOT),'REPOSITORY'))
        (HERE/'results.json').write_text(json.dumps(results,indent=2)+'\n')
    print(name,results[name]['status'],flush=True)
