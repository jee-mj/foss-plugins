"""Strict data-only PE, layout, archive and NSIS-payload contract."""
import hashlib
import json
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
import pefile

root, report = map(Path, sys.argv[1:])
payload = root / 'payload'
system = {
    'kernel32.dll', 'msvcrt.dll', 'user32.dll', 'gdi32.dll', 'ole32.dll',
    'oleaut32.dll', 'uuid.dll', 'comdlg32.dll', 'shell32.dll', 'shlwapi.dll',
    'advapi32.dll', 'winmm.dll', 'ws2_32.dll', 'version.dll', 'imm32.dll',
    'dwmapi.dll', 'ntdll.dll', 'opengl32.dll', 'comctl32.dll', 'setupapi.dll',
    'cfgmgr32.dll', 'hid.dll', 'winspool.drv', 'rpcrt4.dll', 'bcrypt.dll',
}
targets = {
    'CLAP/0xFX.clap': (True, None, {b'clap_entry'}),
    'VST3/0xFX.vst3/Contents/x86_64-win/0xFX.vst3':
        (True, None, {b'GetPluginFactory', b'InitDll', b'ExitDll'}),
    'Applications/0xfx_gui.exe': (False, 2, set()),
    'Applications/0xfx_standalone.exe': (False, 3, set()),
}
results = {}
for name, (dll, subsystem, required) in targets.items():
    path = payload / name
    pe = pefile.PE(str(path))
    assert pe.FILE_HEADER.Machine == 0x8664, name
    assert pe.OPTIONAL_HEADER.Magic == 0x20b, name
    assert bool(pe.FILE_HEADER.Characteristics & 0x2000) == dll, name
    if subsystem is not None:
        assert pe.OPTIONAL_HEADER.Subsystem == subsystem, name
    symbols = pe.DIRECTORY_ENTRY_EXPORT.symbols if hasattr(pe, 'DIRECTORY_ENTRY_EXPORT') else []
    exports = {s.name for s in symbols}
    assert required <= exports, (name, required - exports)
    assert not any(s.forwarder for s in symbols), name
    imports = {i.dll.decode().lower() for i in
               getattr(pe, 'DIRECTORY_ENTRY_IMPORT', []) + getattr(pe, 'DIRECTORY_ENTRY_DELAY_IMPORT', [])}
    assert imports <= system, (name, imports - system)
    results[name] = {'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                     'bytes': path.stat().st_size, 'imports': sorted(imports),
                     'exports': sorted(e.decode() for e in exports if e),
                     'subsystem': pe.OPTIONAL_HEADER.Subsystem}
assert b'com.averagenative.0xfx' in (payload / 'CLAP/0xFX.clap').read_bytes()
vst3 = (payload / 'VST3/0xFX.vst3/Contents/x86_64-win/0xFX.vst3').read_bytes()
# Hand-derived from config.h multichar literals and SMTG_COM_COMPATIBLE UID macro.
# Windows GUID byte storage, not an invented normalized factory UUID.
for uid in ['584678306f63706d3030303100000000', '58467830646574693030303100000000']:
    assert bytes.fromhex(uid) in vst3, uid
assert len(list((payload / 'Applications/resources/ir/bundled').glob('*.wav'))) == 4
assert list((payload / 'Applications/presets/factory').rglob('*.0xfx'))
for name in ['LICENSE', 'Notices/LICENSE-SDL2.txt', 'Notices/MinGW-w64/COPYING',
             'Notices/LICENSE-MCF-Gthread.txt', 'Notices/BUILD-INFO.txt']:
    assert (payload / name).stat().st_size > 100, name
for name in ['cplug/LICENSE', 'imgui/LICENSE.txt', 'nfd/LICENSE']:
    assert (payload / 'Notices/vendored-sources' / name).stat().st_size > 100, name
for name in ['LICENSE-KissFFT.txt', 'KissFFT-COPYING', 'LICENSE-Shine.txt', 'COPYING3', 'COPYING.RUNTIME']:
    assert (payload / 'Notices' / name).stat().st_size > 100, name
for archive, folder in [('0xfx-windows-x86_64.zip', payload), ('0xfx-source.zip', root / 'source')]:
    with zipfile.ZipFile(root / archive) as z:
        expected = {p.relative_to(folder).as_posix(): p for p in folder.rglob('*') if p.is_file()}
        assert len(z.namelist()) == len(expected)
        assert set(z.namelist()) == set(expected)
        for name, path in expected.items():
            assert z.read(name) == path.read_bytes(), name
        assert all(i.date_time == (1980, 1, 1, 0, 0, 0) for i in z.infolist())
installer = root / 'installer/0xfx-1.3.0-source-x86_64-setup.exe'
assert pefile.PE(str(installer)).FILE_HEADER.Machine == 0x14c
with tempfile.TemporaryDirectory() as tmp:
    subprocess.run(['7z', 'x', '-bd', '-o' + tmp, str(installer)], check=True, stdout=subprocess.DEVNULL)
    extracted = Path(tmp)
    expected_paths = set()
    count = 0
    for path in payload.rglob('*'):
        if path.is_file():
            relative = path.relative_to(payload)
            if relative.parts[0] in {'CLAP', 'VST3'}:
                relative = Path('$COMMONFILES64') / relative
            expected_paths.add(relative.as_posix())
            assert (extracted / relative).read_bytes() == path.read_bytes(), relative
            count += 1
    assert {p.relative_to(extracted).as_posix() for p in extracted.rglob('*') if p.is_file()} == expected_paths
results['installer'] = {'sha256': hashlib.sha256(installer.read_bytes()).hexdigest(),
                        'matching_files': count, 'kind': 'operator NSIS; includes console'}
results['execution'] = 'data-only; no Windows payload or cross-produced helper executed'
results['vst3_uid_storage_hex'] = ['584678306f63706d3030303100000000', '58467830646574693030303100000000']
results['archives'] = {name: {'sha256': hashlib.sha256((root / name).read_bytes()).hexdigest(),
                              'bytes': (root / name).stat().st_size}
                       for name in ['0xfx-windows-x86_64.zip', '0xfx-source.zip']}
report.write_text(json.dumps(results, indent=2) + '\n')
print('Verified four x86-64 PEs, VST3 UID bytes, full ZIP contents and exact NSIS paths/bytes:', count, 'files')
