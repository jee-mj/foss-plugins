{ lib, runCommand, python3, binutils, packageSet }:

let
  packages = packageSet.freePackages;
  names = [ "reevr" "wolf-shaper" "vaporizer2" ];
in
assert builtins.all (name:
  builtins.all (license: license.free or false)
    (lib.toList packages.${name}.meta.license)
) names;
runCommand "foss-plugins-nixpkgs-audio-formats" {
  nativeBuildInputs = [ python3 binutils ];
  reevr = packages.reevr;
  wolf = packages.wolf-shaper;
  vaporizer = packages.vaporizer2;
} ''
  python3 - <<'PY'
  import os
  import struct
  import subprocess
  from pathlib import Path

  # Static inspection only: never dlopen or execute these upstream binaries.
  expected = {
      'reevr': {
          'lib/vst3/REEV-R.vst3/Contents/x86_64-linux/REEV-R.so': 'GetPluginFactory',
          'lib/lv2/REEV-R.lv2/libREEV-R.so': 'lv2_descriptor',
      },
      'wolf': {
          'lib/vst/wolf-shaper-vst.so': 'main',
          'lib/lv2/wolf-shaper.lv2/wolf-shaper_dsp.so': 'lv2_descriptor',
          'lib/lv2/wolf-shaper.lv2/wolf-shaper_ui.so': 'lv2ui_descriptor',
          'lib/dssi/wolf-shaper-dssi.so': 'dssi_descriptor',
          'bin/wolf-shaper': None,
      },
      'vaporizer': {
          'lib/vst3/VASTvaporizer2.vst3/Contents/x86_64-linux/VASTvaporizer2.so': 'GetPluginFactory',
          'lib/lv2/VASTvaporizer2.lv2/libVASTvaporizer2.so': 'lv2_descriptor',
          'lib/clap/VASTvaporizer2.clap': 'clap_entry',
      },
  }
  report = []
  for name, files in expected.items():
      root = Path(os.environ[name])
      for relative, entry in files.items():
          binary = root / relative
          header = binary.read_bytes()[:20]
          assert header[:6] == b'\x7fELF\x02\x01', relative
          assert struct.unpack_from('<H', header, 18)[0] == 62, relative
          if entry:
              symbols = subprocess.check_output(
                  ['readelf', '--dyn-syms', '--wide', str(binary)], text=True)
              assert any(line.split()[-1].split('@')[0] == entry
                         and ' UND ' not in line for line in symbols.splitlines() if line.split()), relative
          report.append(f'{name}: {relative}: ELF64 x86-64; export={entry}')
      for manifest in (root / 'lib/lv2').glob('*/manifest.ttl'):
          assert manifest.stat().st_size > 0, manifest
  # The pinned native Wolf package does not provide Windows' VST3/CLAP formats.
  assert not (Path(os.environ['wolf']) / 'lib/vst3').exists()
  assert not (Path(os.environ['wolf']) / 'lib/clap').exists()
  Path(os.environ['out']).write_text('\n'.join(report) + '\n')
  print('\n'.join(report))
  PY
''
