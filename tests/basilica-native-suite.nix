{ callPackage, runCommand, python3, patchelf, binutils, name, plugin ? callPackage ../pkgs/basilica-native-suite/package.nix {
    inherit name;
    juceRuntime = callPackage ../lib/juce-runtime.nix { };
    pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  }
}:
let
  compatibility = callPackage ../pkgs/basilica-native-suite/nave-compatibility.nix { };
in
runCommand "basilica-${name}-native-artifacts" {
  nativeBuildInputs = [ python3 patchelf binutils ];
} (''
  mkdir -p "$out"
  VERIFY_SCRIPT=${../pkgs/basilica-native-suite/verify.py} python3 ${../pkgs/basilica-native-suite/test_verify.py}
  export receipt="$out/verification.json"
  python3 ${../pkgs/basilica-native-suite/verify.py} ${plugin} ${name} ${plugin.src}
'' + (if name == "Nave" then ''
  python3 - <<'PY'
  import hashlib
  import json
  import os
  from pathlib import Path
  receipt = json.loads(Path('${compatibility}/verification.json').read_text())
  downstream = Path('${plugin}/share/doc/basilica-nave/downstream')
  assert hashlib.sha256((downstream/'PluginProcessor.cpp').read_bytes()).hexdigest() == receipt['modifiedSha256']
  assert hashlib.sha256((downstream/'nave-scalar-minimum.patch').read_bytes()).hexdigest() == receipt['patchSha256']
  assert (downstream/'NOTICE-Nave.md').stat().st_size > 0
  upstream = Path('${plugin.src}')
  binary = Path('${plugin}/lib/vst3/Nave.vst3/Contents/x86_64-linux/Nave.so').read_bytes()
  assets = sorted(upstream.glob('presets/factory/*.json'))
  assets += [upstream/'resources/i18n/de.txt']
  # Exactly the four GUI assets declared by upstream CMake. The two committed
  # toggle filmstrips are not used by Nave's zero-toggle layout.
  assets += [upstream/'resources/gui'/name for name in (
      'knob_brass_strip_160px_128f.png', 'knob_brass_strip_320px_128f.png',
      'faceplate_nave_900x600.png', 'faceplate_nave_1800x1200.png')]
  assets += [upstream/'docs/assets/icon-256.png']
  assert len(assets) == 16, 'expected all sixteen declared Nave binary assets'
  hashes = {}
  for asset in assets:
      payload = asset.read_bytes()
      assert payload in binary, asset.name
      hashes[str(asset.relative_to(upstream))] = hashlib.sha256(payload).hexdigest()
  (Path(os.environ['out'])/'assets.json').write_text(json.dumps(hashes,indent=2)+'\n')
  PY
  cp ${compatibility}/verification.json "$out/compatibility.json"
  cp -r ${compatibility}/overload-reproduction "$out/overload-reproduction"
'' else ""))
