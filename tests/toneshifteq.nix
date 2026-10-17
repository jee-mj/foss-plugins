{ runCommand, packageSet, python3 }:

assert packageSet.freePackages ? toneshifteq;
assert packageSet.freePackages.toneshifteq.version == "1.3.0";
runCommand "foss-plugins-toneshifteq-artifacts" {
  plugin = packageSet.freePackages.toneshifteq;
  nativeBuildInputs = [ python3 ];
} ''
  test -s "$plugin/lib/clap/toneshifteq.clap"
  test -s "$plugin/lib/vst3/Toneshifteq.vst3/Contents/x86_64-linux/Toneshifteq.so"
  bundle="$plugin/lib/lv2/ToneShiftEQ.lv2"
  for name in manifest.ttl toneshifteq.ttl toneshifteq.so toneshifteq_ui.so; do
    test -s "$bundle/$name"
  done
  test ! -e "$plugin/bin"
  python3 - <<'PY'
  import ctypes
  import os
  from pathlib import Path

  root = Path(os.environ["plugin"])
  for relative, entry in [
      ("lib/clap/toneshifteq.clap", "clap_entry"),
      ("lib/vst3/Toneshifteq.vst3/Contents/x86_64-linux/Toneshifteq.so", "GetPluginFactory"),
      ("lib/lv2/ToneShiftEQ.lv2/toneshifteq.so", "lv2_descriptor"),
      ("lib/lv2/ToneShiftEQ.lv2/toneshifteq_ui.so", "lv2ui_descriptor"),
  ]:
      library = ctypes.CDLL(str(root / relative), mode=os.RTLD_NOW)
      assert getattr(library, entry), (relative, entry)
      print(f"dlopen + entrypoint OK: {relative}: {entry}")
  PY
  touch "$out"
''
