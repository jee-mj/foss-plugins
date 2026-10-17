{ callPackage, runCommand, python3, patchelf, binutils
, basilica-miserere ? callPackage ../pkgs/basilica-miserere {
    juceRuntime = callPackage ../lib/juce-runtime.nix { };
    pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  }
}:
# Catch incomplete bundles, wrong-platform binaries, unresolved direct/dlopen
# dependencies, absent entrypoints, and lost embedded public fonts/presets.
runCommand "basilica-miserere-native-artifacts" {
  plugin = basilica-miserere;
  upstream = basilica-miserere.src;
  nativeBuildInputs = [ python3 patchelf binutils ];
} ''
  mkdir -p "$out"
  export receipt="$out/verification.json"
  python3 - <<'PY'
  import ctypes
  import hashlib
  import json
  import os
  import subprocess
  from pathlib import Path

  root = Path(os.environ['plugin'])
  upstream = Path(os.environ['upstream'])
  relative = 'lib/vst3/Miserere.vst3/Contents/x86_64-linux/Miserere.so'
  binary = root / relative
  data = binary.read_bytes()
  assert data[:6] == b'\x7fELF\x02\x01', 'expected ELF64 little-endian'
  assert int.from_bytes(data[18:20], 'little') == 62, 'expected x86-64'
  assert list(root.glob('lib/vst3/*.vst3')) == [root / 'lib/vst3/Miserere.vst3']
  assert not (root / 'bin').exists()
  assert not list(root.rglob('*.onnx'))
  exports = subprocess.check_output(['nm', '-D', '--defined-only', str(binary)], text=True)
  for entry in ['GetPluginFactory', 'ModuleEntry', 'ModuleExit']:
      assert any(line.split()[-1] == entry for line in exports.splitlines()), entry
  needed = subprocess.check_output(['patchelf', '--print-needed', str(binary)], text=True).splitlines()
  assert needed, 'expected dynamic runtime dependencies'
  # RTLD_NOW resolves all relocations. Do not call the factory, initialize a
  # module, create a plugin/audio instance, or initialize any GUI subsystem.
  loaded = ctypes.CDLL(str(binary), mode=os.RTLD_NOW | os.RTLD_LOCAL)
  assert loaded.GetPluginFactory
  rpath = subprocess.check_output(['patchelf', '--print-rpath', str(binary)], text=True).strip().split(':')
  runtime = {}
  for soname in ['libX11.so.6', 'libXcursor.so.1', 'libXinerama.so.1', 'libXrandr.so.2', 'libGL.so.1']:
      resolved = next((Path(d) / soname for d in rpath if (Path(d) / soname).is_file()), None)
      assert resolved is not None, soname
      ctypes.CDLL(str(resolved), mode=os.RTLD_NOW | os.RTLD_LOCAL)
      runtime[soname] = str(resolved)
  embedded = {}
  assets = sorted(upstream.glob('presets/factory/*.json')) + [upstream / 'resources/i18n/de.txt']
  assets += sorted(upstream.glob('resources/fonts/*.ttf'))
  assert len(assets) == 16, assets
  for asset in assets:
      payload = asset.read_bytes()
      assert payload in data, f'missing embedded asset: {asset}'
      embedded[str(asset.relative_to(upstream))] = hashlib.sha256(payload).hexdigest()
  notices = root / 'share/doc/basilica-miserere'
  for installed, original in [('LICENSE-Miserere', upstream / 'LICENSE'),
                              ('OFL-EBGaramond.txt', upstream / 'resources/fonts/OFL-EBGaramond.txt')]:
      assert (notices / installed).read_bytes() == original.read_bytes()
  assert (notices / 'LICENSE-JUCE').stat().st_size > 0
  result = dict(plugin=str(root), binary=relative, sha256=hashlib.sha256(data).hexdigest(),
                format='VST3', architecture='ELF64 x86-64', needed=needed,
                runtime=runtime, embedded=embedded,
                checks=['ELF', 'exports', 'RTLD_NOW', 'JUCE dlopen libraries', 'embedded assets', 'notices'],
                scope='experimental local native build; no GUI/audio instance or host acceptance test')
  Path(os.environ['receipt']).write_text(json.dumps(result, indent=2) + '\n')
  print(json.dumps(result, indent=2))
  PY
''
