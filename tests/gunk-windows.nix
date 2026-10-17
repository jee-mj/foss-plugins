{ callPackage, runCommand, python3, p7zip, nsis }:
let
  package = callPackage ../pkgs/gunk-windows { };
in {
  notices = runCommand "gunk-binary-notice-closure" { nativeBuildInputs = [ python3 ]; } ''
    python - <<'PY'
    import hashlib, json, os, re
    from pathlib import Path
    original = Path('${package.sources.juce}/modules')
    notices = Path('${package}/payload/Notices')
    aggregate_path = notices / 'JUCE-component-source-notices.txt'
    index_path = notices / 'JUCE-component-source-index.json'
    assert aggregate_path.is_file(), 'missing lossless binary notice aggregate'
    stream = aggregate_path.read_bytes()
    index = json.loads(index_path.read_text())
    assert index['format'] == 'juce-component-source-notices-v1'
    assert not (notices / 'JUCE-module-sources').exists(), 'duplicate per-source binary entries'
    # These modules have translation units in the actual Windows build log.
    modules = ['juce_core', 'juce_data_structures', 'juce_events', 'juce_graphics',
               'juce_gui_basics', 'juce_gui_extra', 'juce_audio_basics',
               'juce_audio_devices', 'juce_audio_formats', 'juce_audio_processors',
               'juce_audio_utils', 'juce_dsp', 'juce_audio_plugin_client']
    expected = {p.relative_to(original).as_posix(): p.read_bytes()
                for module in modules for p in (original / module).rglob('*') if p.is_file()}
    records = index['records']
    assert len(records) == len(expected) == 2026
    assert [r['path'] for r in records] == sorted(expected)
    reconstructed = {}
    previous_end = 0
    for record in records:
        path, offset, length = record['path'], record['offset'], record['length']
        assert type(offset) is int and type(length) is int
        assert previous_end <= offset and 0 <= length and offset + length <= len(stream)
        assert path.encode('utf-8') in stream[previous_end:offset], path
        data = stream[offset:offset + length]
        assert data == expected[path], path
        assert hashlib.sha256(data).hexdigest() == record['sha256'], path
        assert (Path('${package}/source/juce/modules') / path).read_bytes() == data, path
        reconstructed[path] = data
        previous_end = offset + length
    assert index['file_count'] == len(records)
    assert index['source_bytes'] == sum(map(len, expected.values()))
    assert index['stream_bytes'] == len(stream) < 128 * 1024 * 1024
    license_files = [p for p in expected if re.search(r'(?i)(licen[cs]e|copying|copyright|readme)', Path(p).name)]
    assert license_files
    assert all(expected[p] in stream for p in license_files)
    fstring = 'juce_audio_processors/format_types/VST3_SDK/base/source/fstring.cpp'
    text = reconstructed[fstring].decode('utf-8')
    assert reconstructed[fstring].split(b'#include', 1)[0] in stream
    for clause in ['(c) 2023, Steinberg Media Technologies GmbH, All Rights Reserved',
                   'Redistribution and use in source and binary forms, with or without modification,',
                   'Redistributions of source code must retain the above copyright notice,',
                   'Redistributions in binary form must reproduce the above copyright notice,',
                   'Neither the name of the Steinberg Media Technologies nor the names of its',
                   'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"',
                   'WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.',
                   'OF THE POSSIBILITY OF SUCH DAMAGE.']:
        assert clause in text, clause
    # Full file equality above retains complete grants/disclaimers, not just these labels.
    required = ['juce_audio_processors/format_types/juce_VST3Headers.h',
                'juce_audio_processors/format_types/VST3_SDK/base/LICENSE.txt',
                'juce_audio_processors/format_types/VST3_SDK/public.sdk/LICENSE.txt',
                'juce_audio_processors/format_types/VST3_SDK/pluginterfaces/LICENSE.txt',
                'juce_graphics/image_formats/pnglib/LICENSE',
                'juce_graphics/image_formats/pnglib/png.h',
                'juce_graphics/image_formats/jpglib/README',
                'juce_core/zip/zlib/zlib.h',
                'juce_graphics/fonts/juce_Typeface.cpp']
    evidence = {p: hashlib.sha256(reconstructed[p]).hexdigest() for p in required}
    assert 'base/source/fstring.cpp' in reconstructed[required[0]].decode('utf-8')
    assert (Path('${package}/payload/Notices/SURGE-NOTICE').read_bytes() ==
            Path('${package.sources.upstream}/Wavetables/Surge/NOTICE').read_bytes())
    report = {'inspection': 'lossless raw-byte aggregate; all records reconstructed exactly; legal text retained contiguously',
              'modules': modules, 'matching_files': len(records),
              'source_bytes': index['source_bytes'], 'aggregate_bytes': len(stream),
              'index_bytes': index_path.stat().st_size,
              'license_readme_files_verified': len(license_files),
              'aggregate_sha256': hashlib.sha256(stream).hexdigest(),
              'index_sha256': hashlib.sha256(index_path.read_bytes()).hexdigest(),
              'steinberg_fstring_sha256': hashlib.sha256(reconstructed[fstring]).hexdigest(),
              'component_evidence_sha256': evidence}
    Path(os.environ['out']).write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    PY
  '';

  installer = runCommand "gunk-nsis-data-only" {
    nativeBuildInputs = [ p7zip (python3.withPackages (p: [ p.pefile ])) ];
  } ''
    7z x -ounpacked ${package.installer}/gunk-0.2.2-windows-x86_64-setup.exe
    python - <<'PY'
    import hashlib, importlib.util, json, os
    from pathlib import Path
    import pefile
    exe = Path('${package.installer}/gunk-0.2.2-windows-x86_64-setup.exe')
    pe = pefile.PE(str(exe))
    # NSIS has an x86 bootstrapper carrying an x64 VST3, not an x64 bootstrapper.
    assert pe.FILE_HEADER.Machine == 0x14c
    extracted = Path('unpacked')
    spec = importlib.util.spec_from_file_location('check_installer', '${../pkgs/gunk-windows/check_installer.py}')
    check = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(check)
    payload = Path('${package}/payload')
    helper = Path('${nsis}/share/nsis/Plugins/x86-unicode/System.dll')
    count = check.validate(payload, extracted, helper)
    assert count == 224 and count + 1 <= 2048
    def rejected(label):
        try:
            check.validate(payload, extracted, helper)
        except AssertionError:
            return
        raise AssertionError('validator accepted mutation: ' + label)
    manifest = extracted / '$LOCALAPPDATA/Programs/Common/VST3/JQ Gunk.vst3/Contents/Resources/moduleinfo.json'
    wrong = extracted / '$LOCALAPPDATA/Programs/Common/VST3/JQ Gunk.vst3/Contents/WrongParent/moduleinfo.json'
    wrong.parent.mkdir()
    manifest.rename(wrong)
    rejected('same basename and bytes under wrong parent')
    wrong.rename(manifest)
    wrong.write_bytes(manifest.read_bytes())
    rejected('extra duplicate under wrong parent')
    wrong.unlink()
    wrong.parent.rmdir()
    extra = extracted / '$PLUGINSDIR/Unexpected.dll'
    extra.write_bytes(helper.read_bytes())
    rejected('unexpected helper')
    extra.unlink()
    system = extracted / '$PLUGINSDIR/System.dll'
    original_helper = system.read_bytes()
    system.write_bytes(b'changed helper')
    rejected('changed known helper')
    system.write_bytes(original_helper)
    assert check.validate(payload, extracted, helper) == count
    report = {'inspection': 'NSIS statically extracted; never executed',
              'matching_payload_files': count,
              'matching_helper': '$PLUGINSDIR/System.dll',
              'helper_sha256': hashlib.sha256(helper.read_bytes()).hexdigest(),
              'path_contract': ['$LOCALAPPDATA/Programs/Common/VST3/', '$APPDATA/JQGunk/',
                                '$LOCALAPPDATA/Programs/JQGunk/Notices/'],
              'negative_cases_rejected': ['wrong parent', 'extra wrong-parent copy', 'unexpected helper', 'changed known helper'],
              'sha256': hashlib.sha256(exe.read_bytes()).hexdigest()}
    Path(os.environ['out']).write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    PY
  '';

  repack = runCommand "gunk-independent-repack" { nativeBuildInputs = [ python3 ]; } ''
    python ${../pkgs/gunk-windows/package.py} ${package}/payload manual.zip
    python ${../pkgs/gunk-windows/package.py} ${package}/source source.zip
    cmp manual.zip ${package}/gunk-windows-x86_64.zip
    cmp source.zip ${package}/gunk-source.zip
    touch "$out"
  '';

  # Catches archive omissions and nondeterministic metadata independently of compilation.
  packaging = runCommand "gunk-windows-zip-contract" { nativeBuildInputs = [ python3 ]; } ''
    mkdir -p fixture/VST3/Example.vst3/Contents/x86_64-win fixture/Notices
    printf 'synthetic fixture, not a PE\n' > fixture/VST3/Example.vst3/Contents/x86_64-win/example.bin
    printf 'fixture notice\n' > fixture/Notices/LICENSE
    python ${../pkgs/gunk-windows/package.py} fixture one.zip
    chmod -R 700 fixture
    touch -t 202610171200 fixture/Notices/LICENSE
    python ${../pkgs/gunk-windows/package.py} fixture two.zip
    python - <<'PY'
    import zipfile
    from pathlib import Path
    assert Path('one.zip').read_bytes() == Path('two.zip').read_bytes()
    with zipfile.ZipFile('one.zip') as z:
        assert z.namelist() == ['Notices/LICENSE', 'VST3/Example.vst3/Contents/x86_64-win/example.bin']
        assert z.read('Notices/LICENSE') == b'fixture notice\n'
        assert z.read(z.namelist()[1]) == b'synthetic fixture, not a PE\n'
        assert all(i.date_time == (1980, 1, 1, 0, 0, 0) for i in z.infolist())
        assert all(i.external_attr >> 16 == 0o100644 for i in z.infolist())
    PY
    touch "$out"
  '';

  # A successful evaluation is not an artifact test: this requires a real build.
  artifacts = runCommand "gunk-windows-artifacts" {
    nativeBuildInputs = [ (python3.withPackages (p: [ p.pefile ])) ];
    inherit package;
  } ''
    python - <<'PY'
    import hashlib, json, os, re, zipfile
    from pathlib import Path
    import pefile
    root = Path(os.environ['package'])
    payload = root / 'payload'
    bundle = payload / 'VST3/JQ Gunk.vst3'
    binary = bundle / 'Contents/x86_64-win/JQ Gunk.vst3'
    pe = pefile.PE(str(binary))
    assert pe.FILE_HEADER.Machine == 0x8664
    assert pe.OPTIONAL_HEADER.Magic == 0x20b
    assert pe.FILE_HEADER.Characteristics & 0x2000
    exports = {s.name for s in pe.DIRECTORY_ENTRY_EXPORT.symbols}
    assert {b'GetPluginFactory', b'InitDll', b'ExitDll'} <= exports
    system = {'kernel32.dll', 'msvcrt.dll', 'user32.dll', 'gdi32.dll',
              'ole32.dll', 'oleaut32.dll', 'uuid.dll', 'comdlg32.dll',
              'shell32.dll', 'shlwapi.dll', 'advapi32.dll', 'winmm.dll',
              'ws2_32.dll', 'version.dll', 'imm32.dll', 'dwmapi.dll',
              'ntdll.dll', 'opengl32.dll', 'comctl32.dll', 'winhttp.dll',
              'dxgi.dll', 'wininet.dll', 'wsock32.dll'}
    for dll in [binary, *bundle.rglob('*.dll')]:
        image = pefile.PE(str(dll))
        imports = {i.dll.decode().lower() for i in
                   getattr(image, 'DIRECTORY_ENTRY_IMPORT', []) +
                   getattr(image, 'DIRECTORY_ENTRY_DELAY_IMPORT', [])}
        shipped = {p.name.lower() for p in dll.parent.glob('*.dll')}
        assert imports <= system | shipped, (dll.name, imports - system - shipped)
    # JUCE 7's SDK generator emits trailing commas (JSON5-style).
    manifest = json.loads(re.sub(r',\s*([}\]])', r'\1',
                               (bundle / 'Contents/Resources/moduleinfo.json').read_text()))
    assert manifest['Name'] == 'JQ Gunk' and manifest['Version'] == '0.2.2'
    assert {c['CID'] for c in manifest['Classes']} == {
        'ABCDEF019182FAEB4A716F644A51476B', 'ABCDEF011234ABCD4A716F644A51476B',
        'ABCDEF01C0DEF00D4A716F644A51476B'}
    # This is upstream's copied native manifest, not Windows factory enumeration.
    # FUIDs may be dynamically initialized; contiguous bytes in a PE are not required.
    assert (payload / 'Notices/LICENSE').stat().st_size > 1000
    assert (root / 'source/upstream/Source/PluginProcessor.cpp').is_file()
    for source in ['juce/modules/juce_core/juce_core.h', 'q/LICENSE',
                   'aubio/COPYING', 'infra/CMakeLists.txt', 'mcfgthreads/LICENSE.TXT',
                   'gcc-source.tar.xz', 'mingw-w64-source.tar.bz2',
                   'packaging/flake.nix', 'packaging/flake.lock',
                   'packaging/pkgs/gunk-windows/default.nix',
                   'packaging/pkgs/gunk-windows/sources.nix',
                   'packaging/pkgs/gunk-windows/package.py',
                   'packaging/pkgs/gunk-windows/installer.nsi',
                   'packaging/pkgs/gunk-windows/INSTALL.txt',
                   'packaging/pkgs/gunk-windows/spike-flake.nix',
                   'packaging/pkgs/gunk-windows/check_installer.py',
                   'packaging/pkgs/gunk-windows/collect_notices.py',
                   'packaging/pkgs/gunk-windows/NOTICE-CLOSURE.md',
                   'packaging/tests/gunk-windows.nix']:
        assert (root / 'source' / source).stat().st_size > 0, source
    assert len(list((payload / 'AppData/JQGunk/Factory Presets').glob('*.jqgpreset'))) == 10
    assert list((payload / 'AppData/JQGunk/Wavetables').rglob('*.wav'))
    for notice in ['LICENSE-JUCE.md', 'LICENSE-aubio', 'LICENSE-Q', 'LICENSE-MCF-Gthread',
                   'BUILD-INFO.txt', 'SURGE-NOTICE', 'MinGW-w64/COPYING']:
        assert (payload / 'Notices' / notice).stat().st_size > 100, notice
    for name, folder in [('gunk-windows-x86_64.zip', payload), ('gunk-source.zip', root / 'source')]:
        with zipfile.ZipFile(root / name) as z:
            expected = {p.relative_to(folder).as_posix(): p.read_bytes()
                        for p in folder.rglob('*') if p.is_file()}
            assert len(z.namelist()) == len(expected)
            assert set(z.namelist()) == set(expected)
            assert all(z.read(n) == data for n, data in expected.items())
            if name == 'gunk-windows-x86_64.zip':
                assert len(z.namelist()) == 224 and len(z.namelist()) <= 2048
                assert max(i.file_size for i in z.infolist()) < 128 * 1024 * 1024
    report = {'execution': 'data-only; no Windows execution',
              'machine': hex(pe.FILE_HEADER.Machine),
              'plugin_sha256': hashlib.sha256(binary.read_bytes()).hexdigest(),
              'plugin_size': binary.stat().st_size,
              'pe_timestamp': pe.FILE_HEADER.TimeDateStamp,
              'manual_members': len(list(p for p in payload.rglob('*') if p.is_file())),
              'largest_manual_member_bytes': max(p.stat().st_size for p in payload.rglob('*') if p.is_file()),
              'exports': sorted(e.decode() for e in exports if e),
              'imports': sorted(i.dll.decode() for i in pe.DIRECTORY_ENTRY_IMPORT),
              'delay_imports': sorted(i.dll.decode() for i in getattr(pe, 'DIRECTORY_ENTRY_DELAY_IMPORT', [])),
              'cids': sorted(c['CID'] for c in manifest['Classes']),
              'sha256': {name: hashlib.sha256((root / name).read_bytes()).hexdigest()
                         for name in ['gunk-windows-x86_64.zip', 'gunk-source.zip']}}
    Path(os.environ['out']).write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    PY
  '';
}
