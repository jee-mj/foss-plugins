"""Inspect/load a VST3 module without invoking its factory or entry points."""
import ctypes
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path

def verify(root, name, upstream=None):
    bundle = root / f'lib/vst3/{name}.vst3'
    binary = bundle / f'Contents/x86_64-linux/{name}.so'
    assert bundle.is_dir() and binary.is_file() and binary.stat().st_size, 'missing or empty VST3 bundle'
    assert sorted(root.glob('lib/vst3/*.vst3')) == [bundle], 'unexpected bundles'
    data = binary.read_bytes()
    assert data[:6] == b'\x7fELF\x02\x01' and int.from_bytes(data[18:20],'little') == 62, 'expected ELF64 x86-64'
    exports = subprocess.check_output(['nm','-D','--defined-only',str(binary)],text=True)
    for symbol in ('GetPluginFactory','ModuleEntry','ModuleExit'):
        assert any(line.split()[-1] == symbol for line in exports.splitlines()), symbol
    loaded = ctypes.CDLL(str(binary),mode=os.RTLD_NOW | os.RTLD_LOCAL)
    assert loaded.GetPluginFactory
    rpath = subprocess.check_output(['patchelf','--print-rpath',str(binary)],text=True).strip().split(':')
    for soname in ('libX11.so.6','libXcursor.so.1','libXinerama.so.1','libXrandr.so.2','libGL.so.1'):
        library = next((Path(d)/soname for d in rpath if (Path(d)/soname).is_file()),None)
        assert library is not None, soname
        ctypes.CDLL(str(library),mode=os.RTLD_NOW | os.RTLD_LOCAL)
    assert not (root/'bin').exists()
    assert not any(root.rglob('*.onnx'))
    embedded = {}
    notices = root / f'share/doc/basilica-{name.lower()}'
    assert (notices/'upstream/LICENSE').stat().st_size > 0
    assert (notices/'JUCE/LICENSE.md').stat().st_size > 0
    if name == 'Crypta':
        for required in ('resources/irs/LICENSES.md','resources/irs/CC0-1.0.txt'):
            assert (notices/'upstream'/required).stat().st_size > 0, required
    if name == 'Seraph':
        assert (notices/'upstream/THIRD-PARTY-NOTICES.md').stat().st_size > 0
        for dependency in ('signalsmith-linear','signalsmith-stretch'):
            assert any(path.is_file() and 'license' in path.name.lower()
                       for path in (notices/dependency).rglob('*')), dependency
    if upstream:
        # Every committed embedded font and factory IR must remain in the module.
        for pattern in ('resources/fonts/*.ttf','resources/irs/*.wav'):
            for asset in upstream.glob(pattern):
                payload = asset.read_bytes()
                assert payload in data, f'missing embedded asset: {asset.name}'
                embedded[str(asset.relative_to(upstream))] = hashlib.sha256(payload).hexdigest()
        for installed in (notices/'upstream').rglob('*'):
            if installed.is_file():
                relative = installed.relative_to(notices/'upstream')
                assert installed.read_bytes() == (upstream/relative).read_bytes(), str(relative)
        if embedded:
            assert (notices/'upstream/resources/fonts/OFL-EBGaramond.txt').is_file()
    notice_hashes = {str(path.relative_to(notices)):hashlib.sha256(path.read_bytes()).hexdigest()
                     for path in sorted(notices.rglob('*')) if path.is_file()}
    return dict(name=name,plugin=str(root),format='VST3',architecture='ELF64 x86-64',sha256=hashlib.sha256(data).hexdigest(),
                embedded=embedded,notices=notice_hashes,checks=['nonempty bundle','ELF','factory exports','RTLD_NOW','JUCE dlopen libraries','embedded assets','notices'],
                scope='experimental local Linux; no factory invocation, GUI, audio instance or host acceptance')

if __name__ == '__main__':
    result = verify(Path(sys.argv[1]),sys.argv[2],Path(sys.argv[3]) if len(sys.argv)>3 else None)
    text = json.dumps(result,indent=2)+'\n'
    if os.environ.get('receipt'):
        Path(os.environ['receipt']).write_text(text)
    print(text)
