{ runCommand, peakeater, python3, patchelf }:

# Catches missing/misplaced bundles, missing LV2 metadata, unresolved runtime
# libraries (including JUCE's dlopen dependencies), and absent format entrypoints.
runCommand "foss-plugins-peakeater-artifacts" {
  plugin = peakeater;
  nativeBuildInputs = [ python3 patchelf ];
} ''
  test -s "$plugin/lib/vst3/peakeater.vst3/Contents/x86_64-linux/peakeater.so"
  test -s "$plugin/lib/clap/peakeater.clap"
  test -s "$plugin/lib/lv2/peakeater.lv2/libpeakeater.so"
  test -s "$plugin/lib/lv2/peakeater.lv2/manifest.ttl"
  test -s "$plugin/lib/lv2/peakeater.lv2/dsp.ttl"
  test -s "$plugin/lib/lv2/peakeater.lv2/ui.ttl"
  test ! -e "$plugin/bin"
  python3 - <<'PY'
  import ctypes
  import os
  import subprocess
  from pathlib import Path

  root = Path(os.environ["plugin"])
  for relative, entry in [
      ("lib/vst3/peakeater.vst3/Contents/x86_64-linux/peakeater.so", "GetPluginFactory"),
      ("lib/clap/peakeater.clap", "clap_entry"),
      ("lib/lv2/peakeater.lv2/libpeakeater.so", "lv2_descriptor"),
      ("lib/lv2/peakeater.lv2/libpeakeater.so", "lv2ui_descriptor"),
  ]:
      library = ctypes.CDLL(str(root / relative), mode=os.RTLD_NOW)
      assert getattr(library, entry), (relative, entry)
      print(f"dlopen + entrypoint OK: {relative}: {entry}")
  # JUCE loads these by soname; ordinary DT_NEEDED checks miss them.
  rpath = subprocess.check_output(
      ["patchelf", "--print-rpath", str(root / "lib/clap/peakeater.clap")], text=True
  ).strip().split(":")
  for soname in ["libX11.so.6", "libXcursor.so.1", "libXinerama.so.1", "libXrandr.so.2"]:
      resolved = next((Path(directory) / soname for directory in rpath if (Path(directory) / soname).is_file()), None)
      assert resolved is not None, soname
      ctypes.CDLL(str(resolved), mode=os.RTLD_NOW)
      print(f"runtime soname OK: {soname}")
  assert "libpeakeater.so" in (root / "lib/lv2/peakeater.lv2/manifest.ttl").read_text()
  PY
  touch "$out"
''
