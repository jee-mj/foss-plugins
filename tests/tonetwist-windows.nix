{ callPackage, runCommand, python3, _7zz, nsis }:
let
  package = callPackage ../pkgs/tonetwist-windows { };
  repack = package.override { repackSalt = "independent-repack"; };
  python = python3.withPackages (p: [ p.pefile ]);
in runCommand "tonetwist-windows-artifacts" {
  nativeBuildInputs = [ python _7zz ];
  plugin = package;
  installer = package.installer;
  repacked = repack;
  repackedInstaller = repack.installer;
  nsisHelper = "${nsis}/share/nsis/Plugins/x86-unicode/System.dll";
} ''
  python - <<'PY'
  import hashlib
  import os
  from pathlib import Path
  import subprocess
  import zipfile
  import pefile

  root = Path(os.environ['plugin'])
  payload = root / 'payload'
  products = ['metaltone', 'collisiondrive', 'rumor', 'tubescreamer', 'valvecaster', 'boobtube']
  required = {}
  for name in products:
      required[f'VST3/{name}.vst3/Contents/x86_64-win/{name}.vst3'] = b'GetPluginFactory'
      required[f'CLAP/{name}.clap'] = b'clap_entry'
  allowed_imports = {
      'kernel32.dll', 'msvcrt.dll', 'user32.dll', 'gdi32.dll', 'opengl32.dll',
      'comdlg32.dll', 'shell32.dll', 'ole32.dll', 'advapi32.dll', 'winmm.dll', 'ntdll.dll',
      'msimg32.dll', 'dwmapi.dll', # Cairo Win32 drawing and Pugl window composition.
  }
  report = []

  def verify_pe(pe, relative, entry):
      assert pe.FILE_HEADER.Machine == 0x8664, relative
      assert pe.OPTIONAL_HEADER.Magic == 0x20b, relative
      assert pe.FILE_HEADER.Characteristics & 0x2000, relative
      assert not pe.OPTIONAL_HEADER.DATA_DIRECTORY[4].Size, relative
      assert pe.FILE_HEADER.TimeDateStamp == 0, relative
      exports = {s.name for s in pe.DIRECTORY_ENTRY_EXPORT.symbols}
      required_exports = {entry}
      if relative.startswith('VST3/'):
          required_exports |= {b'InitDll', b'ExitDll'}
      assert required_exports <= exports, (relative, required_exports - exports)
      delay_directory = pe.OPTIONAL_HEADER.DATA_DIRECTORY[13]
      assert not (delay_directory.VirtualAddress or delay_directory.Size), (relative, 'delay imports')
      assert not getattr(pe, 'DIRECTORY_ENTRY_DELAY_IMPORT', []), (relative, 'parsed delay imports')
      imports = {i.dll.decode().lower() for i in pe.DIRECTORY_ENTRY_IMPORT}
      assert imports <= allowed_imports, (relative, imports - allowed_imports)
      return imports

  def verify_bundles(base):
      actual = {p.relative_to(base).as_posix() for category in ['VST3', 'CLAP']
                for p in (base / category).rglob('*') if p.is_file()}
      assert actual == set(required), ('missing/unexpected bundles', actual ^ set(required))
      for relative, entry in required.items():
          pe = pefile.PE(str(base / relative))
          imports = verify_pe(pe, relative, entry)
          report.append(f'{relative}: PE32+ AMD64 DLL; export={entry.decode()}; imports={sorted(imports)}; sha256=' + hashlib.sha256((base / relative).read_bytes()).hexdigest())

  verify_bundles(payload)
  failures = []
  vst3 = 'VST3/metaltone.vst3/Contents/x86_64-win/metaltone.vst3'
  # Mutate real parsed PE metadata, never load a plugin or execute a payload.
  for mutation in ['delay-import-directory', 'InitDll', 'ExitDll']:
      pe = pefile.PE(str(payload / vst3))
      if mutation == 'delay-import-directory':
          pe.OPTIONAL_HEADER.DATA_DIRECTORY[13].VirtualAddress = 0x1000
          pe.OPTIONAL_HEADER.DATA_DIRECTORY[13].Size = 32
      else:
          pe.DIRECTORY_ENTRY_EXPORT.symbols = [
              symbol for symbol in pe.DIRECTORY_ENTRY_EXPORT.symbols
              if symbol.name != mutation.encode()]
      try:
          verify_pe(pe, vst3, b'GetPluginFactory')
      except AssertionError:
          pass
      else:
          failures.append('accepted PE mutation: ' + mutation)
  clap_notice = payload / 'Notices/LICENSE-CLAP'
  # Exact verified notice includes attribution, permission, retention and disclaimer.
  notice_hash = '50bf21def6095d5e50999675203ae1cd03a6333859bf5fa7c2238909b04dd7d3'
  if not clap_notice.is_file():
      failures.append('missing complete attributed CLAP MIT notice')
  elif hashlib.sha256(clap_notice.read_bytes()).hexdigest() != notice_hash:
      failures.append('incomplete or changed CLAP MIT grant/attribution')
  assert not failures, failures
  assert (root / 'source/LICENSE-CLAP').read_bytes() == clap_notice.read_bytes()
  report.append('complete attributed CLAP MIT grant verified in payload/source; '
                'delay-import and missing InitDll/ExitDll mutations rejected')
  # A missing product must fail before a partial suite can be accepted.
  import tempfile
  import shutil
  with tempfile.TemporaryDirectory() as tmp:
      damaged = Path(tmp) / 'payload'
      shutil.copytree(payload, damaged)
      for directory in [damaged, *damaged.rglob('*')]:
          if directory.is_dir():
              directory.chmod(0o755)
      (damaged / 'CLAP/boobtube.clap').unlink()
      try:
          verify_bundles(damaged)
      except AssertionError:
          pass
      else:
          raise AssertionError('accepted missing BoobTube bundle')
  assert not list(payload.rglob('*.exe'))
  for notice in ['BUILD-INFO.txt', 'LICENSE-REVIEW.md', 'LICENSE-DPF',
                 'LICENSE-MCF-Gthread', 'LICENSE-DejaVuSans', 'MinGW-w64/COPYING',
                 'GNU-runtime-licenses/gcc-exception-3.1.txt']:
      assert (payload / 'Notices' / notice).stat().st_size > 100, notice
  for source in ['upstream/Makefile', 'dpf/Makefile.plugins.mk', 'pugl/COPYING',
                 'default.nix', 'package.py', 'installer.nsi', 'flake.lock', 'dependencies.json']:
      assert (root / 'source' / source).is_file(), source
  archive = next(root.glob('tonetwist-*-windows-x86_64.zip'))
  expected = {p.relative_to(payload).as_posix(): p.read_bytes()
              for p in payload.rglob('*') if p.is_file()}
  with zipfile.ZipFile(archive) as z:
      assert len(z.namelist()) == len(expected)
      assert set(z.namelist()) == set(expected)
      for name, data in expected.items():
          assert z.read(name) == data, name
  exe = next(Path(os.environ['installer']).glob('*-setup.exe'))
  setup = pefile.PE(str(exe))
  assert setup.FILE_HEADER.Machine in (0x14c, 0x8664)
  assert not setup.OPTIONAL_HEADER.DATA_DIRECTORY[4].Size, 'unexpected Authenticode signature'
  subprocess.run(['7zz', 'x', str(exe), '-oextracted', '-y', '-mmt=4', '-bd'], check=True)
  embedded = {p.relative_to('extracted').as_posix(): p.read_bytes()
              for p in Path('extracted').rglob('*') if p.is_file()}
  destinations = {'VST3': '$COMMONFILES64/VST3', 'CLAP': '$COMMONFILES64/CLAP',
                  'Notices': '$COMMONFILES64/ToneTwist/Notices'}
  expected_embedded = {'$PLUGINSDIR/System.dll': Path(os.environ['nsisHelper']).read_bytes()}
  for name, data in expected.items():
      category, relative = name.split('/', 1)
      expected_embedded[destinations[category] + '/' + relative] = data

  def verify_installer(files):
      assert set(files) == set(expected_embedded), set(files) ^ set(expected_embedded)
      for name, data in expected_embedded.items():
          assert hashlib.sha256(files[name]).digest() == hashlib.sha256(data).digest(), name

  verify_installer(embedded)
  for destination in expected_embedded:
      misplaced = dict(embedded)
      misplaced['extra-parent/' + destination] = misplaced.pop(destination)
      try:
          verify_installer(misplaced)
      except AssertionError:
          pass
      else:
          raise AssertionError(f'accepted misplaced installer path: {destination}')
  for first, second in [(archive, Path(os.environ['repacked']) / archive.name),
                        (exe, Path(os.environ['repackedInstaller']) / exe.name)]:
      assert first.read_bytes() == second.read_bytes(), first.name
      report.append('byte-identical independent packaging (shared source compilation): '
                    + first.name + ': ' + hashlib.sha256(first.read_bytes()).hexdigest())
  report.append('all six products / 12 DLLs verified; missing bundle and all extra-parent installer paths rejected; exact ZIP/installer bytes matched; unsigned operator installer')
  Path(os.environ['out']).write_text('\n'.join(report) + '\n')
  print('\n'.join(report))
  PY
''
