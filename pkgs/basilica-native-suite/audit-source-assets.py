"""Pinned official Git trees: fail closed on unexpected weights/large blobs."""
import json
import subprocess
from pathlib import Path
from research import api

here = Path(__file__).parent
root = here.resolve().parents[1]
expression = f'''let f = builtins.getFlake "git+file://{root}";
  p = import f.inputs.nixpkgs {{system="x86_64-linux";}};
in (p.callPackage (f.outPath + "/pkgs/basilica-native-suite/candidates.nix") {{}}).sources'''
pins = json.loads(subprocess.check_output(['nix','eval','--impure','--no-write-lock-file','--json','--expr',expression]))
audit = {}
for name, pin in pins.items():
    repo = pin.get('repo','basilica-audio/'+name)
    response = api(f'repos/{repo}/git/trees/{pin["revision"]}?recursive=1')
    assert not response.get('truncated'), f'{name}: incomplete tree'
    tree = response['tree']
    suspicious = []
    reviewed = []
    for item in tree:
        path = item['path']
        extension = Path(path).suffix.lower()
        fixture = name == 'Firmament' and path == 'tests/fixtures/v020-state.bin' and item.get('size') == 543
        # Committed AGPL GUI filmstrips, not external asset downloads.
        gui = item.get('sha') in ('ba29a02bee6223d95c9b8a847f7986f530855e84',
                                  '8741b3220b4d4ae2539cc2535f1b6a6b6a65c8f7',
                                  '2d23869a40fd52ea9e6775fad2d359ca34a48675',
                                  'bb9f761d5b8419d278bff4ea66481812744823c4') and path.startswith('resources/gui/') and path.endswith('.png')
        # The upstream command-line utility's gitlink is outside the plugin's
        # DOWNLOAD_ONLY header graph. No command-line utility is built/fetched.
        cli = name == 'stretch' and path == 'cmd/util' and item['sha'] == 'aeb4e31077a453566b58fff1c7e7e998ac824157'
        if fixture or gui or cli:
            reviewed.append(dict(path=path,gitObject=item['sha'],reason='state fixture' if fixture else 'bundled AGPL GUI PNG' if gui else 'unused CLI-only gitlink'))
        weights = extension in ('.onnx','.pt','.pth','.ckpt','.safetensors','.gguf','.tflite','.h5','.pb','.weights','.model','.bin')
        if ((weights or item.get('size',0)>4*1024*1024 or item['type']=='commit')
                and not (fixture or gui or cli)):
            suspicious.append(item)
    audit[name] = dict(revision=pin['revision'],hash=pin['hash'],files=sum(x['type']=='blob' for x in tree),
                       maximumBlobBytes=max(x.get('size',0) for x in tree),reviewed=reviewed,unexpected=suspicious)
    print(name,audit[name],flush=True)
(here/'asset-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
assert not any(record['unexpected'] for record in audit.values()), 'unexpected weights, submodules or large source assets'
