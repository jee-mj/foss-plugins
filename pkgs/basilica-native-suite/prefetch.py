"""Fetch only the source assets reviewed in research.json; emit immutable pins."""
import json
import subprocess
from pathlib import Path
from research import api

root = Path(__file__).parent
records = json.loads((root/'research.json').read_text())
pins = {}
for name, r in records.items():
    pins[name] = {k:r[k] for k in ('name','version','revision','identity','audio')}
for name, repo, ref in [('linear','Signalsmith-Audio/linear','0.3.1'),
                         ('stretch','Signalsmith-Audio/signalsmith-stretch','57b93f4e9206a089a45387eaa39bdc9f310d3308')]:
    rev = api(f'repos/{repo}/commits/{ref}')['sha']
    pins[name] = dict(name=name,repo=repo,revision=rev)
for name,r in pins.items():
    repo = r.get('repo', 'basilica-audio/'+name)
    url = f'https://github.com/{repo}/archive/{r["revision"]}.tar.gz'
    result = json.loads(subprocess.check_output(['nix','store','prefetch-file','--json','--unpack',url]))
    r['hash'] = result['hash']
    print(name,r['revision'],r['hash'],flush=True)
    (root/'pins.json').write_text(json.dumps(pins,indent=2)+'\n')
