{ runCommand, python3, intersect }:

# Catches missing/wrong-format artifacts and unresolved plugin dependencies.
runCommand "intersect-artifacts" {
  plugin = intersect;
  provider = intersect.provider;
  exportReferencesGraph = [ "plugin-closure" intersect ];
  nativeBuildInputs = [ python3 ];
} ''
  test -s "$plugin/lib/vst3/INTERSECT.vst3/Contents/x86_64-linux/INTERSECT.so"
  test ! -e "$plugin/bin"
  python3 - <<'PY'
  import ctypes
  import os
  import re
  from pathlib import Path
  root = Path(os.environ["plugin"])
  library = ctypes.CDLL(str(root / "lib/vst3/INTERSECT.vst3/Contents/x86_64-linux/INTERSECT.so"), mode=os.RTLD_NOW)
  assert library.GetPluginFactory
  assert not list(root.rglob("*.onnx"))
  if os.environ["provider"] == "cpu":
      closure = Path("plugin-closure").read_text()
      assert not re.search(r"-(?:cuda\d|cudnn-|libcublas-|libcufft-|libcurand-|migraphx-|miopen-|rocblas-|clr-)", closure), closure
      print("CPU runtime closure contains no CUDA/cuDNN/ROCm/MIGraphX packages")
  print("VST3 dlopen/GetPluginFactory passed; no bundled model")
  PY
  touch "$out"
''
