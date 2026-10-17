{ callPackage, runCommand, python3, _7zz, nsis }:
let
  package = callPackage ../pkgs/drumcloud-windows { };
  repack = package.override { repackSalt = "independent-repack"; };
  python = python3.withPackages (p: [ p.pefile ]);
in
runCommand "drumcloud-windows-artifacts" {
  nativeBuildInputs = [ python _7zz ];
  plugin = package;
  installer = package.installer;
  repacked = repack;
  repackedInstaller = repack.installer;
  nsisHelper = "${nsis}/share/nsis/Plugins/x86-unicode/System.dll";
} ''
  python - <<'PY'
  import hashlib
  import json
  import os
  from pathlib import Path
  import subprocess
  import zipfile
  import pefile

  root = Path(os.environ['plugin'])
  payload = root / 'payload'
  required = {
      'CLAP/d_drumcloud.clap': b'clap_entry',
      'VST3/d_drumcloud.vst3/Contents/x86_64-win/d_drumcloud.vst3': b'GetPluginFactory',
  }
  allowed = {'kernel32.dll', 'msvcrt.dll', 'user32.dll', 'gdi32.dll', 'opengl32.dll',
             'comdlg32.dll', 'shell32.dll', 'ole32.dll', 'advapi32.dll', 'winmm.dll',
             'ntdll.dll', 'comctl32.dll', 'uuid.dll', 'dwmapi.dll'}
  report = []
  observed = {}
  for name, entry in required.items():
      pe = pefile.PE(str(payload / name))
      assert pe.FILE_HEADER.Machine == 0x8664, name
      assert pe.OPTIONAL_HEADER.Magic == 0x20b, name
      assert pe.FILE_HEADER.Characteristics & 0x2000, name
      exports = {s.name for s in pe.DIRECTORY_ENTRY_EXPORT.symbols}
      assert entry in exports, (name, exports)
      if name.startswith('VST3/'):
          assert {b'InitDll', b'ExitDll'} <= exports
      imports = {i.dll.decode().lower() for i in pe.DIRECTORY_ENTRY_IMPORT}
      assert imports <= allowed, (name, imports - allowed)
      assert not getattr(pe, 'DIRECTORY_ENTRY_DELAY_IMPORT', []), 'unrecorded delay imports'
      observed[name] = sorted(imports)
      report.append(f'{name}: PE32+ AMD64 DLL; exports include {entry!r}; imports={sorted(imports)}')
  assert json.loads((payload / 'Notices/PE-IMPORTS.json').read_text()) == observed
  assert not list(payload.rglob('*.exe'))
  assert not list(payload.rglob('*.dll')), 'unexpected dynamic runtime'
  for notice in ['LICENSE-DrumCloud.txt', 'LICENSE-DPF', 'DPF-LICENSING.md',
                 'LICENSE-Pugl', 'dr_libs/dr_wav.h', 'CLAP-headers/entry.h', 'LICENSE-CLAP',
                 'LICENSE-MCF-Gthread', 'GNU-runtime-licenses/gcc-exception-3.1.txt',
                 'MinGW-w64/COPYING', 'BUILD-INFO.txt', 'LICENSE-REVIEW.md']:
      assert (payload / 'Notices' / notice).stat().st_size > 50, notice
  # No source-specific assets disappear from the supplied corresponding source.
  assert (root / 'source/upstream/UI/fuimadane_wave_bg.png').stat().st_size > 800000
  assert (root / 'source/upstream/DPF/dgl/src/pugl-upstream/COPYING').is_file()
  source = root / 'source/upstream'
  for notice, original in {
      'LICENSE-DrumCloud.txt': 'LICENSE.txt',
      'LICENSE-DPF': 'DPF/LICENSE',
      'LICENSE-Pugl': 'DPF/dgl/src/pugl-upstream/COPYING',
      'SendNoteExamplePlugin.cpp': 'SendNoteExamplePlugin.cpp',
      'dr_libs/dr_wav.h': 'thirdparty/dr_libs/dr_wav.h',
      'dr_libs/dr_flac.h': 'thirdparty/dr_libs/dr_flac.h',
      'dr_libs/dr_mp3.h': 'thirdparty/dr_libs/dr_mp3.h',
      'DGL-resources/LICENSE-DejaVuSans.ttf.txt': 'DPF/dgl/src/resources/LICENSE-DejaVuSans.ttf.txt',
      'DGL-resources/DejaVuSans.ttf': 'DPF/dgl/src/resources/DejaVuSans.ttf',
  }.items():
      assert (payload / 'Notices' / notice).read_bytes() == (source / original).read_bytes(), notice

  archive = root / 'drumcloud-1.9.0-beta.8-windows-x86_64.zip'
  expected = {p.relative_to(payload).as_posix(): p.read_bytes()
              for p in payload.rglob('*') if p.is_file()}
  with zipfile.ZipFile(archive) as z:
      assert len(z.namelist()) == len(expected)
      assert set(z.namelist()) == set(expected)
      for name, data in expected.items():
          assert z.read(name) == data, name
          assert z.getinfo(name).date_time == (1980, 1, 1, 0, 0, 0)
  exe = Path(os.environ['installer']) / 'drumcloud-1.9.0-beta.8-windows-x86_64-setup.exe'
  assert pefile.PE(str(exe)).FILE_HEADER.Machine in (0x14c, 0x8664)
  subprocess.run(['7zz', 'x', str(exe), '-oextracted', '-y', '-mmt=4', '-bd'], check=True)
  embedded = {p.relative_to('extracted').as_posix(): p.read_bytes()
              for p in Path('extracted').rglob('*') if p.is_file()}
  destinations = {'CLAP': '$COMMONFILES64/CLAP', 'VST3': '$COMMONFILES64/VST3',
                  'Notices': '$COMMONFILES64/DrumCloud/Notices'}
  wanted = {'$PLUGINSDIR/System.dll': Path(os.environ['nsisHelper']).read_bytes()}
  for name, data in expected.items():
      category, relative = name.split('/', 1)
      wanted[destinations[category] + '/' + relative] = data

  def verify_placement(files):
      assert files.keys() == wanted.keys(), 'incorrect installer placement'
      for name, data in wanted.items():
          assert files[name] == data, name

  verify_placement(embedded)
  for name in ['$COMMONFILES64/CLAP/d_drumcloud.clap',
               '$COMMONFILES64/VST3/d_drumcloud.vst3/Contents/x86_64-win/d_drumcloud.vst3',
               '$COMMONFILES64/DrumCloud/Notices/LICENSE-DrumCloud.txt']:
      misplaced = dict(embedded)
      misplaced['extra-parent/' + name] = misplaced.pop(name)
      try:
          verify_placement(misplaced)
      except AssertionError:
          pass
      else:
          raise AssertionError('accepted misplaced payload: ' + name)
  report.append('NSIS archive extracted statically: exact destinations and bytes; misplaced-path mutations rejected')
  for first, second in [(archive, Path(os.environ['repacked']) / archive.name),
                        (exe, Path(os.environ['repackedInstaller']) / exe.name)]:
      assert first.read_bytes() == second.read_bytes(), first.name
      report.append('independent repack byte-identical: ' + first.name + ': sha256=' +
                    hashlib.sha256(first.read_bytes()).hexdigest())
  report.append('No plugin, installer, Windows host or Wine runtime was executed.')
  Path(os.environ['out']).write_text('\n'.join(report) + '\n')
  print('\n'.join(report))
  PY
''
