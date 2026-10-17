{ callPackage, runCommand, python3, _7zz, nsis }:
let
  package = callPackage ../pkgs/toneshifteq-windows { };
  python = python3.withPackages (p: [ p.pefile ]);
  repack = package.override { repackSalt = "independent-repack"; };
  recompile = package.override { compileSalt = "independent-source-compilation"; };
  # Only the delivered lock and recipe select the archived build's package set.
  archivedLock = (builtins.fromJSON
    (builtins.readFile (package.outPath + "/source/packaging/flake.lock"))).nodes.nixpkgs.locked;
  archivedPkgs = import (builtins.fetchTree archivedLock) { system = "x86_64-linux"; };
  archived = archivedPkgs.callPackage
    (package.outPath + "/source/packaging/pkgs/toneshifteq-windows") { };
  archivedRecompile = archived.override { compileSalt = "archived-source-compilation-round1"; };
in assert archived.drvPath == package.drvPath;
runCommand "toneshifteq-windows-artifacts" {
  nativeBuildInputs = [ python _7zz ];
  plugin = package;
  installer = package.installer;
  repacked = repack;
  repackedInstaller = repack.installer;
  recompiled = recompile.plugin;
  archived = archivedRecompile;
  archivedInstaller = archivedRecompile.installer;
  nsisHelper = "${nsis}/share/nsis/Plugins/x86-unicode/System.dll";
  recordFile = ../pkgs/toneshifteq-windows/verification.json;
} ''
  python - <<'PY'
  import os
  import hashlib
  import subprocess
  import zipfile
  from pathlib import Path
  import pefile
  root = Path(os.environ['plugin'])
  payload = root / 'payload'
  report = []
  required = {
      'CLAP/toneshifteq.clap': {b'clap_entry'},
      'VST3/Toneshifteq.vst3/Contents/x86_64-win/Toneshifteq.vst3':
          {b'GetPluginFactory', b'InitDll', b'ExitDll'},
  }
  allowed_imports = {
      'kernel32.dll', 'msvcrt.dll', 'user32.dll', 'gdi32.dll', 'comdlg32.dll',
      'shell32.dll', 'ole32.dll', 'advapi32.dll', 'winmm.dll', 'ntdll.dll',
      'msimg32.dll', 'dwmapi.dll',
  }
  actual = {p.relative_to(payload).as_posix() for category in ['CLAP', 'VST3']
            for p in (payload / category).rglob('*') if p.is_file()}
  assert actual == set(required), actual ^ set(required)

  def verify_pe(path, exports, pe=None):
      if pe is None:
          pe = pefile.PE(str(path))
      assert pe.FILE_HEADER.Machine == 0x8664, path
      assert pe.OPTIONAL_HEADER.Magic == 0x20b, path
      assert pe.FILE_HEADER.Characteristics & 0x2000, path
      assert not pe.FILE_HEADER.TimeDateStamp, path
      assert not pe.OPTIONAL_HEADER.DATA_DIRECTORY[4].Size, path
      assert not pe.OPTIONAL_HEADER.DATA_DIRECTORY[13].Size, path
      assert not pe.OPTIONAL_HEADER.DATA_DIRECTORY[13].VirtualAddress, path
      assert not getattr(pe, 'DIRECTORY_ENTRY_DELAY_IMPORT', []), path
      assert exports <= {s.name for s in pe.DIRECTORY_ENTRY_EXPORT.symbols}, path
      imports = {i.dll.decode().lower() for i in pe.DIRECTORY_ENTRY_IMPORT}
      assert imports <= allowed_imports, (path, imports - allowed_imports)
      return imports

  for relative, exports in required.items():
      path = payload / relative
      imports = verify_pe(path, exports)
      for name in [b'ToneShift-EQ12M', b'ToneShift-EQ12L']:
          assert name in path.read_bytes(), (relative, name)
      if relative.startswith('CLAP/'):
          for identity in [b'com.brummer10.ToneShiftEQ.Master', b'com.brummer10.ToneShiftEQ.Live']:
              assert identity in path.read_bytes(), identity
      else:
          # Windows travesty V3_ID uses COM GUID byte ordering.
          for identity in ['c5f86bf500f6ce47a5a7dd431717129a',
                           '4982dec1ae99654385a775bc91ea8d7e']:
              assert bytes.fromhex(identity) in path.read_bytes(), identity
      other = Path(os.environ['recompiled']) / relative
      assert path.read_bytes() == other.read_bytes(), ('independent compilation differs', relative)
      report.append(f'{relative}: PE32+ AMD64 DLL, exports={sorted(exports)}, '
                    f'imports={sorted(imports)}, sha256={hashlib.sha256(path.read_bytes()).hexdigest()}')

  vst3 = payload / 'VST3/Toneshifteq.vst3/Contents/x86_64-win/Toneshifteq.vst3'
  for mutation in ['InitDll', 'ExitDll', 'delay-import', 'non-system-import', 'wrong-machine']:
      pe = pefile.PE(str(vst3))
      if mutation in ['InitDll', 'ExitDll']:
          pe.DIRECTORY_ENTRY_EXPORT.symbols = [s for s in pe.DIRECTORY_ENTRY_EXPORT.symbols
                                               if s.name != mutation.encode()]
      elif mutation == 'delay-import':
          pe.OPTIONAL_HEADER.DATA_DIRECTORY[13].VirtualAddress = 0x1000
      elif mutation == 'wrong-machine':
          pe.FILE_HEADER.Machine = 0x14c
      else:
          pe.DIRECTORY_ENTRY_IMPORT[0].dll = b'libgcc_s_seh-1.dll'
      try:
          verify_pe(vst3, {b'GetPluginFactory', b'InitDll', b'ExitDll'}, pe)
      except AssertionError:
          pass
      else:
          raise AssertionError(('accepted invalid PE metadata', mutation))

  for relative in ['LICENSE-ToneShiftEQ', 'libxputty/LICENSE',
                   'libxputty/xputty/resources/LICENSE.txt',
                   'libxputty/xputty/xdgmime/xdgmime.h',
                   'libxputty/xputty/header/stb_truetype.h',
                   'EQ12/AudioFFT/COPYING.txt', 'EQ12/vst3/travesty/LICENSE',
                   'EQ12/clap/clap/clap.h',
                   'cairo/COPYING', 'pixman/COPYING', 'zlib/LICENSE',
                   'libpng/LICENSE', 'sndfile/COPYING', 'mingw/COPYING',
                   'mcfgthreads/LICENSE.TXT', 'BUILD-INFO.txt']:
      assert (payload / 'Notices' / relative).stat().st_size > 50, relative
  assert not list(payload.rglob('*.exe'))
  assert not list(payload.rglob('*.o'))
  assert not list(payload.rglob('*.lv2'))
  for relative in ['upstream/EQ12/Makefile',
                   'packaging/pkgs/toneshifteq-windows/default.nix',
                   'packaging/pkgs/toneshifteq-windows/package.py',
                   'packaging/pkgs/toneshifteq-windows/collect-notices.py',
                   'packaging/pkgs/toneshifteq-windows/installer.nsi',
                   'packaging/pkgs/toneshifteq-windows/LICENSE-REVIEW.md',
                   'packaging/flake.lock', 'dependencies.json',
                   'relink/EQ12/AudioFFT.o', 'relink/libxputty/Build/libxputty.lib']:
      assert (root / 'source' / relative).is_file(), relative
  assert not list((root / 'source').rglob('verification.json')), 'self-referential evidence shipped'
  import json
  manifest = json.loads((root / 'source/dependencies.json').read_text())
  assert set(manifest) == {'gcc', 'binutils', 'mingw', 'mcfgthreads',
                           'cairo', 'pixman', 'zlib', 'libpng', 'sndfile'}
  for name, dependency in manifest.items():
      assert dependency['hash'], name
      assert (root / 'source' / (name + '-source')).exists(), name
      for patch in dependency['patches']:
          assert patch['hash'], (name, patch)
          assert (root / 'source' / (name + '-patches') / patch['name']).is_file(), (name, patch)
  for relative in ['libxputty/xputty/resources/LICENSE.txt',
                   'libxputty/xputty/xdgmime/xdgmime.h',
                   'libxputty/xputty/header/stb_truetype.h',
                   'libxputty/xputty/header/nanosvg.h',
                   'EQ12/AudioFFT/COPYING.txt', 'EQ12/vst3/travesty/LICENSE',
                   'EQ12/clap/clap/clap.h']:
      assert (payload / 'Notices' / relative).read_bytes() == (root / 'source/upstream' / relative).read_bytes(), relative
  expected = {p.relative_to(payload).as_posix(): p.read_bytes()
              for p in payload.rglob('*') if p.is_file()}
  archive = root / 'toneshifteq-1.3.0-windows-x86_64.zip'
  with zipfile.ZipFile(archive) as z:
      assert len(z.namelist()) == len(expected)
      assert set(z.namelist()) == set(expected)
      for name, data in expected.items():
          assert z.read(name) == data, name
  exe = Path(os.environ['installer']) / 'toneshifteq-1.3.0-windows-x86_64-setup.exe'
  setup = pefile.PE(str(exe))
  assert setup.FILE_HEADER.Machine in (0x14c, 0x8664)
  assert not setup.OPTIONAL_HEADER.DATA_DIRECTORY[4].Size
  subprocess.run(['7zz', 'x', str(exe), '-oextracted', '-y', '-mmt=4', '-bd'], check=True)
  embedded = {p.relative_to('extracted').as_posix(): p.read_bytes()
              for p in Path('extracted').rglob('*') if p.is_file()}
  destinations = {'CLAP': '$COMMONFILES64/CLAP', 'VST3': '$COMMONFILES64/VST3',
                  'Notices': '$COMMONFILES64/ToneShiftEQ/Notices'}
  wanted = {'$PLUGINSDIR/System.dll': Path(os.environ['nsisHelper']).read_bytes()}
  for name, data in expected.items():
      category, relative = name.split('/', 1)
      wanted[destinations[category] + '/' + relative] = data

  def verify_installer(files):
      assert set(files) == set(wanted), set(files) ^ set(wanted)
      for name, data in wanted.items():
          assert files[name] == data, name

  verify_installer(embedded)
  for destination in wanted:
      damaged = dict(embedded)
      damaged['extra-parent/' + destination] = damaged.pop(destination)
      try:
          verify_installer(damaged)
      except AssertionError:
          pass
      else:
          raise AssertionError(('accepted wrong destination', destination))
  for first, second, proof in [
      (archive, Path(os.environ['repacked']) / archive.name, 'independent repack'),
      (exe, Path(os.environ['repackedInstaller']) / exe.name, 'independent repack'),
      (archive, Path(os.environ['archived']) / archive.name, 'archived-recipe source compilation'),
      (exe, Path(os.environ['archivedInstaller']) / exe.name, 'archived-recipe source compilation')]:
      assert first.read_bytes() == second.read_bytes(), ('independent repack differs', first)
      report.append('byte-identical ' + proof + ': ' + first.name + ': ' + hashlib.sha256(first.read_bytes()).hexdigest())
  for relative in required:
      assert (payload / relative).read_bytes() == (Path(os.environ['archived']) / 'payload' / relative).read_bytes(), relative
  report.append('Delivered recipe evaluated with its supplied lock to the same derivation; separate archived-source compilation produced identical DLL/ZIP/installer bytes.')
  report.append('Two independently compiled bundles byte-identical; Master/Live binary names and IDs verified statically. Factory execution and host/audio acceptance not tested.')
  report.append('Exact ZIP/NSIS payload bytes and destinations verified by data extraction; all extra-parent mutations rejected; no Windows payload executed.')
  record = json.loads(Path(os.environ['recordFile']).read_text())
  assert record['paths']['manualOutput'] == str(root)
  assert record['paths']['installerOutput'] == os.environ['installer']
  assert record['paths']['manualArchive'] == str(archive)
  assert record['paths']['operatorInstaller'] == str(exe)
  assert record['paths']['archivedManualOutput'] == os.environ['archived']
  assert record['paths']['archivedInstallerOutput'] == os.environ['archivedInstaller']
  assert record['paths']['archivedRecipe'] == str(root / 'source/packaging/pkgs/toneshifteq-windows/default.nix')
  for name, pin in record['pins'].items():
      assert pin['version'] == manifest[name]['version'], name
      assert pin['hash'] == manifest[name]['hash'], name
  for artifact in record['artifacts']:
      path = root / artifact['path']
      if artifact['path'].endswith('-setup.exe'):
          path = exe
      assert hashlib.sha256(path.read_bytes()).hexdigest() == artifact['sha256'], path
  Path(os.environ['out']).write_text('\n'.join(report) + '\n')
  print('\n'.join(report))
  PY
''
