{ runCommand, sub-orbit, python3, patchelf }:

# Reject a missing/misnamed VST3, unresolved runtime dependencies, or an absent
# host entrypoint. Loading the library does not create a GUI or audio device.
runCommand "foss-plugins-sub-orbit-artifacts" {
  plugin = sub-orbit;
  nativeBuildInputs = [ python3 patchelf ];
} ''
  test -s "$plugin/share/doc/sub-orbit/LICENSE"
  test -s "$plugin/share/doc/sub-orbit/NOTICE"
  test ! -e "$plugin/bin"
  python3 - <<'PY'
  import ctypes
  import os
  import subprocess
  from pathlib import Path

  root = Path(os.environ["plugin"])
  binary = root / "lib/vst3/SUB ORBIT.vst3/Contents/x86_64-linux/SUB ORBIT.so"
  library = ctypes.CDLL(str(binary), mode=os.RTLD_NOW)
  assert library.GetPluginFactory
  print("dlopen + GetPluginFactory OK: SUB ORBIT.vst3")
  rpath = subprocess.check_output(["patchelf", "--print-rpath", str(binary)], text=True).strip().split(":")
  for soname in ["libX11.so.6", "libXcursor.so.1", "libXinerama.so.1", "libXrandr.so.2"]:
      resolved = next((Path(d) / soname for d in rpath if (Path(d) / soname).is_file()), None)
      assert resolved is not None, soname
      ctypes.CDLL(str(resolved), mode=os.RTLD_NOW)
      print(f"runtime soname OK: {soname}")
  PY
  touch "$out"
''
