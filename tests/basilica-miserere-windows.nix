{ callPackage, runCommand, python3 }:
let
  package = callPackage ../pkgs/basilica-miserere-windows { };
  repack = package.override { repackSalt = "independent-repack"; };
in
runCommand "basilica-miserere-windows-artifacts" {
  nativeBuildInputs = [ (python3.withPackages (p: [ p.pefile ])) ];
  inherit package repack;
  # Independently runnable without the blocked Windows compilation. This proves
  # ZIP mechanics only, not the existence or reproducibility of a real plugin.
  passthru.packagingFixture = runCommand "miserere-zip-mechanics-only" {
    nativeBuildInputs = [ python3 ];
  } ''
    mkdir -p fixture/VST3/Miserere.vst3/Contents/x86_64-win fixture/Notices
    python - <<'PY'
    from pathlib import Path
    Path('fixture/VST3/Miserere.vst3/Contents/x86_64-win/fixture.bin').write_bytes(bytes(range(256)))
    Path('fixture/Notices/fixture.txt').write_text('Synthetic fixture; not a Windows payload.\n')
    PY
    python ${../pkgs/basilica-miserere-windows/package.py} fixture first.zip
    chmod -R 700 fixture
    touch -t 202610171200 fixture/Notices/fixture.txt
    python ${../pkgs/basilica-miserere-windows/package.py} fixture second.zip
    python - <<'PY'
    import hashlib, os, zipfile
    from pathlib import Path
    first = Path('first.zip').read_bytes()
    assert first == Path('second.zip').read_bytes()
    with zipfile.ZipFile('first.zip') as z:
        assert z.namelist() == ['Notices/fixture.txt', 'VST3/Miserere.vst3/Contents/x86_64-win/fixture.bin']
        assert z.read(z.namelist()[1]) == bytes(range(256))
        assert z.read(z.namelist()[0]) == b'Synthetic fixture; not a Windows payload.\n'
        for info in z.infolist():
            assert info.date_time == (1980, 1, 1, 0, 0, 0)
            assert info.external_attr >> 16 == 0o100644
    Path(os.environ['out']).write_text('ZIP mechanics fixture only; byte-identical after mtime/mode changes: '
                                     + hashlib.sha256(first).hexdigest() + '\n')
    PY
  '';
} ''
  python - <<'PY'
  import hashlib, os, zipfile
  from pathlib import Path
  import pefile

  root = Path(os.environ['package'])
  payload = root / 'payload'
  binary = payload / 'VST3/Miserere.vst3/Contents/x86_64-win/Miserere.vst3'
  pe = pefile.PE(str(binary))
  assert pe.FILE_HEADER.Machine == 0x8664
  assert pe.OPTIONAL_HEADER.Magic == 0x20b
  assert pe.FILE_HEADER.Characteristics & 0x2000
  exports = {s.name for s in pe.DIRECTORY_ENTRY_EXPORT.symbols}
  assert {b'GetPluginFactory', b'InitDll', b'ExitDll'} <= exports, exports
  allowed = {'kernel32.dll', 'msvcrt.dll', 'user32.dll', 'gdi32.dll',
             'ole32.dll', 'oleaut32.dll', 'uuid.dll', 'comdlg32.dll',
             'shell32.dll', 'shlwapi.dll', 'advapi32.dll', 'winmm.dll',
             'ws2_32.dll', 'version.dll', 'imm32.dll', 'dwmapi.dll',
             'ntdll.dll', 'opengl32.dll', 'comctl32.dll', 'winhttp.dll'}
  imports = {i.dll.decode().lower() for i in pe.DIRECTORY_ENTRY_IMPORT}
  assert imports <= allowed, imports - allowed
  assert not list(payload.rglob('*.exe'))
  for name in ['LICENSE-Miserere', 'LICENSE-JUCE', 'OFL-EBGaramond.txt',
               'BUILD-INFO.txt', 'LICENSE-MCF-Gthread', 'MinGW-w64/COPYING',
               'GNU-runtime-licenses/gcc-exception-3.1.txt']:
      assert (payload / 'Notices' / name).stat().st_size > 100, name
  bundle = payload / 'VST3/Miserere.vst3'
  assert (bundle / 'desktop.ini').is_file()
  assert (bundle / 'Plugin.ico').stat().st_size > 0
  report = [f'PE32+ AMD64 DLL; exports={sorted(exports)}; imports={sorted(imports)}']
  for filename, folder in [('basilica-miserere-0.7.0-windows-x86_64.zip', payload),
                           ('basilica-miserere-0.7.0-source.zip', root / 'source')]:
      archive = root / filename
      expected = {p.relative_to(folder).as_posix(): p.read_bytes()
                  for p in folder.rglob('*') if p.is_file()}
      with zipfile.ZipFile(archive) as z:
          assert set(z.namelist()) == set(expected)
          assert len(z.namelist()) == len(expected)
          for name, data in expected.items():
              assert z.read(name) == data, name
              assert z.getinfo(name).date_time == (1980, 1, 1, 0, 0, 0)
      assert archive.read_bytes() == (Path(os.environ['repack']) / filename).read_bytes()
      report.append(f'independent packaging byte-identical: {filename}: '
                    + hashlib.sha256(archive.read_bytes()).hexdigest())
  for path in ['upstream/src/PluginProcessor.cpp', 'JUCE/modules/juce_core/juce_core.h',
               'packaging/pkgs/basilica-miserere-windows/default.nix',
               'packaging/pkgs/basilica-miserere-windows/adapt.py',
               'packaging/pkgs/basilica-miserere-windows/package.py',
               'packaging/flake.nix', 'packaging/flake.lock', 'mcfgthreads/LICENSE.TXT']:
      assert (root / 'source' / path).is_file(), path
  report.append('Data-only inspection; no Windows execution; repack repeat is not a second compilation.')
  Path(os.environ['out']).write_text('\n'.join(report) + '\n')
  print('\n'.join(report))
  PY
''
