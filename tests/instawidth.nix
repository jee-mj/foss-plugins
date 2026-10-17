{ runCommand, instawidth, python3, patchelf }:

# Reject misplaced bundles, missing LV2 metadata, broken runtime lookup, and
# libraries without the entrypoints a host needs. No display or audio device.
runCommand "foss-plugins-instawidth-artifacts" {
  plugin = instawidth;
  nativeBuildInputs = [ python3 patchelf ];
} ''
  test -s "$plugin/lib/lv2/InstaWidth.lv2/manifest.ttl"
  test -s "$plugin/lib/lv2/InstaWidth.lv2/dsp.ttl"
  test -s "$plugin/lib/lv2/InstaWidth.lv2/ui.ttl"
  test -s "$plugin/share/doc/instawidth/LICENSE"
  test ! -e "$plugin/bin"
  python3 - <<'PY'
  import ctypes
  import os
  import subprocess
  from pathlib import Path

  root = Path(os.environ["plugin"])
  for relative, entries in [
      ("lib/vst3/InstaWidth.vst3/Contents/x86_64-linux/InstaWidth.so", ["GetPluginFactory"]),
      ("lib/lv2/InstaWidth.lv2/libInstaWidth.so", ["lv2_descriptor", "lv2ui_descriptor"]),
  ]:
      binary = root / relative
      library = ctypes.CDLL(str(binary), mode=os.RTLD_NOW)
      for entry in entries:
          assert getattr(library, entry), (relative, entry)
          print(f"dlopen + entrypoint OK: {relative}: {entry}")
      rpath = subprocess.check_output(["patchelf", "--print-rpath", str(binary)], text=True).strip().split(":")
      for soname in ["libX11.so.6", "libXcursor.so.1", "libXinerama.so.1", "libXrandr.so.2"]:
          resolved = next((Path(d) / soname for d in rpath if (Path(d) / soname).is_file()), None)
          assert resolved is not None, (relative, soname)
          ctypes.CDLL(str(resolved), mode=os.RTLD_NOW)
  assert "libInstaWidth.so" in (root / "lib/lv2/InstaWidth.lv2/manifest.ttl").read_text()
  PY
  touch "$out"
''
