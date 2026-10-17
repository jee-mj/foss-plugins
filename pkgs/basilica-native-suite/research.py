"""Resolve official release commits and inspect asset terms before source fetch."""
import base64
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent
RELEASES = [('Overture','0.5.0'), ('Tenebrae','0.5.0'), ('Nave','0.5.0'),
            ('Silentium','0.5.0'), ('Requiem','0.5.0'), ('Seraph','0.4.0'),
            ('Aureate','0.5.0'), ('Firmament','0.4.0'), ('Triptych','0.6.0'),
            ('Apotheosis','0.6.1'), ('Crypta','0.4.1'), ('Lancet','0.5.0')]

def api(path):
    return json.loads(subprocess.check_output(['gh','api',path]))

def content(repo, path, rev):
    return base64.b64decode(api(f'repos/{repo}/contents/{path}?ref={rev}')['content']).decode()

if __name__ == '__main__':
    records = {}
    for index, (name, version) in enumerate(RELEASES, 1):
        repo = f'basilica-audio/{name}'
        obj = api(f'repos/{repo}/git/ref/tags/v{version}')['object']
        while obj['type'] == 'tag':
            obj = api(f'repos/{repo}/git/tags/{obj["sha"]}')['object']
        assert obj['type'] == 'commit'
        rev = obj['sha']
        tree = api(f'repos/{repo}/git/trees/{rev}?recursive=1')['tree']
        assets = [x for x in tree if x['path'].lower().endswith(('.wav','.ttf','.otf','.onnx','.pt','.pth','.bin','.tflite'))]
        notices = {}
        for x in tree:
            p = x['path']
            if x['type'] == 'blob' and any(s in p.lower() for s in ('license','ofl','third-party','copyright')):
                if x.get('size',0) < 100000:
                    notices[p] = content(repo,p,rev)
        record = dict(name=name,version=version,revision=rev,identity=f'BA-{index:03}',
                      audio={'Silentium':'AUDIO-058','Seraph':'AUDIO-007'}.get(name),
                      assets=assets,notices=notices,cmake=content(repo,'CMakeLists.txt',rev))
        records[name] = record
        print(name, rev, 'assets', [(x['path'],x.get('size')) for x in assets], flush=True)
        print('NOTICES',list(notices),flush=True)
        (ROOT/'research.json').write_text(json.dumps(records,indent=2)+'\n')
