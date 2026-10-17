{ callPackage, runCommand, python3, patchelf
, audio-restoration-vst ? callPackage ../pkgs/audio-restoration-vst {
    juceRuntime = callPackage ../lib/juce-runtime.nix { };
    pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  }
}:
runCommand "audio-restoration-vst-artifacts" {
  plugin = audio-restoration-vst;
  exportReferencesGraph = [ "plugin-closure" audio-restoration-vst ];
  nativeBuildInputs = [ python3 patchelf ];
} ''
  python3 - <<'PY'
  import ctypes
  import os
  import re
  import subprocess
  from pathlib import Path

  root = Path(os.environ['plugin'])
  plugins = list(root.glob('lib/vst3/*.vst3/Contents/x86_64-linux/*.so'))
  assert len(plugins) == 1, plugins
  assert not list(root.rglob('*.onnx')), 'models must be acquired separately'
  assert not (root / 'bin').exists()
  closure = Path('plugin-closure').read_text()
  assert not re.search(r'-(?:cuda\d|cuda[_-]|cudnn-|libcublas-|libcufft-|libcurand-|libcusparse-|nccl-|migraphx-|miopen-|rocblas-|rocm-|hip-|clr-)', closure), closure
  print('CPU transitive runtime closure contains no CUDA/cuDNN/ROCm/MIGraphX packages')
  plugin = plugins[0]
  needed = subprocess.check_output(['patchelf', '--print-needed', str(plugin)], text=True)
  assert 'libonnxruntime.so' in needed, needed
  assert not any(x in needed.lower() for x in ['cuda', 'rocm', 'hip', 'migraphx']), needed
  loaded = ctypes.CDLL(str(plugin), mode=os.RTLD_NOW)
  assert loaded.GetPluginFactory
  rpath = subprocess.check_output(['patchelf', '--print-rpath', str(plugin)], text=True).strip().split(':')
  for soname in ['libX11.so.6', 'libXcursor.so.1', 'libXinerama.so.1', 'libXrandr.so.2', 'libGL.so.1']:
      resolved = next((Path(d) / soname for d in rpath if (Path(d) / soname).is_file()), None)
      assert resolved is not None, soname
      ctypes.CDLL(str(resolved), mode=os.RTLD_NOW)
  print('VST3 entrypoint, ONNX DT_NEEDED, JUCE runtime libraries, and model-free output verified')
  PY
  touch "$out"
''
