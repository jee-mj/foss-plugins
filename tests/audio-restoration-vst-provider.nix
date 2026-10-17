{ callPackage, runCommand, lib, gccStdenv, python3, binutils, archiveAudit ? false, cudaLoad ? false
, audio-restoration-vst ? callPackage ../pkgs/audio-restoration-vst {
    juceRuntime = callPackage ../lib/juce-runtime.nix { };
    pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  }
}:
let
  cpu = audio-restoration-vst;
  cuda = cpu.override { provider = "cuda"; };
  rejected = provider: !(builtins.tryEval ((cpu.override { inherit provider; }).drvPath)).success;
in
if cudaLoad then runCommand "audio-restoration-vst-cuda-load" {
  plugin = cuda;
  runtime = cuda.runtime;
  nativeBuildInputs = [ python3 binutils gccStdenv.cc ];
} ''
  python3 - <<'PY'
  import ctypes
  import os
  import subprocess
  from pathlib import Path
  plugin = Path(os.environ['plugin'])
  runtime = Path(os.environ['runtime'])
  artifacts = list(plugin.glob('lib/vst3/*.vst3/Contents/x86_64-linux/*.so'))
  assert len(artifacts) == 1, artifacts
  assert not list(plugin.rglob('*.onnx'))
  assert not list(runtime.rglob('*.onnx'))
  assert not (runtime / 'lib/libonnxruntime_providers_tensorrt.so').exists()
  needed = subprocess.check_output(['readelf', '-d', str(artifacts[0])], text=True)
  assert 'libonnxruntime.so' in needed, needed
  loaded = ctypes.CDLL(str(artifacts[0]), mode=os.RTLD_NOW)
  assert loaded.GetPluginFactory
  core = ctypes.CDLL(str(runtime / 'lib/libonnxruntime.so'), mode=os.RTLD_NOW)
  assert core.OrtGetApiBase
  print('CUDA VST3 RTLD_NOW/GetPluginFactory and ORT core symbol passed; no model/session/device execution')
  PY
  # The CUDA EP requires ORT's Provider_SetHost handshake before its initializers
  # run. Use the public options getter to trigger the real bridge loader, without
  # creating a provider factory (which upstream implements with cudaMalloc).
  cat > load-provider.cpp <<'CPP'
  #include <onnxruntime_cxx_api.h>
  #include <cassert>
  #include <dlfcn.h>
  #include <iostream>
  int main(int argc, char** argv) {
    assert(argc == 2);
    Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "audio-restoration-load-check");
    const auto& api = Ort::GetApi();
    OrtCUDAProviderOptionsV2* options = nullptr;
    Ort::ThrowOnError(api.CreateCUDAProviderOptions(&options));
    Ort::AllocatorWithDefaultOptions allocator;
    char* text = nullptr;
    Ort::ThrowOnError(api.GetCUDAProviderOptionsAsString(options, allocator, &text));
    assert(text && std::string(text).find("device_id=0") != std::string::npos);
    allocator.Free(text);
    api.ReleaseCUDAProviderOptions(options);
    void* ep = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!ep) { std::cerr << dlerror() << '\n'; return 1; }
    assert(dlsym(ep, "GetProvider"));
    // As upstream does on Linux, do not dlclose the CUDA EP.
    std::cout << "ORT CUDA EP loaded through host handshake/options serialization; RTLD_NOW/GetProvider symbol passed; no factory/session/model/device execution\n";
  }
  CPP
  c++ -std=c++17 -I${cuda.runtime}/include/onnxruntime load-provider.cpp \
    -L${cuda.runtime}/lib -Wl,-rpath,${cuda.runtime}/lib -lonnxruntime -ldl -o load-provider
  ./load-provider "$runtime/lib/libonnxruntime_providers_cuda.so"
  touch "$out"
'' else if archiveAudit then runCommand "audio-restoration-vst-cuda-archive-audit" {
  src = cuda.runtime.src;
  pname = cuda.runtime.pname;
  nativeBuildInputs = [ python3 binutils ];
} ''
  python3 ${cuda.runtime.archiveAuditScript} "$src" > archive-members.txt
  mkdir runtime
  tar -xzf "$src" --strip-components=1 -C runtime
  cd runtime
  ${cuda.runtime.installPhase}
  test ! -e "$out/lib/libonnxruntime_providers_tensorrt.so"
  for library in "$out"/lib/*.so*; do
    if test -L "$library"; then continue; fi
    readelf -d "$library" >> "$out/elf-dynamic.txt"
  done
'' else
assert cpu.provider == "cpu";
assert !cpu.cudaSupport;
assert cpu.providerCmakeFlag == "-DONNXRUNTIME_USE_CUDA=OFF";
assert cpu.runtime.version == "1.24.4";
assert cpu.runtime.provenance == "official-model-free-binary";
assert lib.elem cpu.providerCmakeFlag cpu.cmakeFlags;
assert lib.elem "-DENABLE_GPU_ACCELERATION=OFF" cpu.cmakeFlags;
assert cuda.provider == "cuda";
assert cuda.cudaSupport;
assert cuda.providerCmakeFlag == "-DONNXRUNTIME_USE_CUDA=ON";
assert (cpu.override {
  provider = "cuda";
  cudaPackages = throw "Provider mode inspection must not force the CUDA package set";
}).providerCmakeFlag == "-DONNXRUNTIME_USE_CUDA=ON";
assert cpu.src == cuda.src;
assert builtins.isString ((cpu.override {
  cudaPackages = throw "CPU evaluation must not force the CUDA package set";
}).drvPath);
assert rejected "rocm";
assert rejected "migraphx";
assert rejected "hip";
runCommand "audio-restoration-vst-provider-contract" {
  nativeBuildInputs = [ gccStdenv.cc python3 ];
} ''
  cp -r ${cpu.src} source
  chmod -R u+w source
  cd source
  # Exercise the same production patch, not an independently rewritten branch.
  ${cpu.postPatch}
  python3 - <<'PY'
  import subprocess
  import sys
  import tarfile
  # Zero-byte metadata fixture: no model payload is acquired or generated.
  with tarfile.open('unexpected-model.tgz', 'w:gz') as archive:
      archive.addfile(tarfile.TarInfo('runtime/models/unexpected.onnx'))
  result = subprocess.run([sys.executable, '${cpu.runtime.archiveAuditScript}', 'unexpected-model.tgz'], capture_output=True, text=True)
  assert result.returncode != 0 and 'unexpected payload' in result.stderr, result
  print('Archive allowlist rejects a model member before extraction')
  PY
  python3 - <<'PY'
  from pathlib import Path
  source = Path('Source/DSP/OnnxDenoiser.cpp').read_text()
  def body_after(marker):
      start = source.index('{', source.index(marker)) + 1
      depth = 1
      end = start
      while depth:
          if source[end] == '{': depth += 1
          if source[end] == '}': depth -= 1
          end += 1
      return source[start:end - 1]

  cuda = body_after('else if (provider == Provider::cuda)')
  session = body_after('bool OnnxDenoiser::tryCreateSessionForProvider')
  assert session.index('if (!providerReady)') < session.index('std::make_unique<Ort::Session>') < session.index('activeProvider = provider;')
  assert 'catch (const std::exception& e)' in session and 'session.reset();' in session
  fallback = body_after('std::vector<OnnxDenoiser::Provider> OnnxDenoiser::getProviderFallbackOrder() const')
  Path('probe.cpp').write_text(r"""
  #include <onnxruntime_cxx_api.h>
  #include <algorithm>
  #include <cassert>
  #include <iostream>
  #include <vector>
  // CPU ORT does not export the legacy CUDA convenience symbol. Bridge only
  // that ABI to the real ORT API-table operation; no return status is mocked.
  OrtStatus* ORT_API_CALL OrtSessionOptionsAppendExecutionProvider_CUDA(OrtSessionOptions* options, int deviceId) noexcept {
    OrtCUDAProviderOptions cudaOptions{};
    cudaOptions.device_id = deviceId;
    return Ort::GetApi().SessionOptionsAppendExecutionProvider_CUDA(options, &cudaOptions);
  }
  struct OnnxDenoiser {
    enum class Provider { autoSelect, cpu, dml, qnn, cuda, rocm, coreml };
    Provider preferredProvider = Provider::cuda;
    bool allowFallback = false;
    std::vector<Provider> getProviderFallbackOrder() const;
  };
  std::vector<OnnxDenoiser::Provider> OnnxDenoiser::getProviderFallbackOrder() const {
  """ + fallback + r"""
  }
  bool registerCuda() {
    using Provider = OnnxDenoiser::Provider;
    Ort::SessionOptions sessionOptions;
    bool providerReady = true;
    try {
  """ + cuda + r"""
      return providerReady;
    } catch (const std::exception& e) {
      std::cout << "Expected registration failure: " << e.what() << '\n';
      return false;
    }
  }
  int main() {
    using Provider = OnnxDenoiser::Provider;
    Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "audio-restoration-registration-check");
    assert(std::string(OrtGetApiBase()->GetVersionString()) == "1.24.4");
    OnnxDenoiser denoiser;
    for (bool fallback : { false, true }) {
      denoiser.allowFallback = fallback;
      bool reachedCpu = false;
      bool registeredCuda = false;
      for (auto provider : denoiser.getProviderFallbackOrder()) {
        if (provider == Provider::cuda) {
          registeredCuda = registerCuda();
          assert(!registeredCuda);
        }
        if (provider == Provider::cpu) reachedCpu = true;
      }
      assert(reachedCpu == fallback);
    }
    std::cout << "Failed CUDA registration throws; disabled fallback excludes CPU; enabled fallback reaches CPU (no model/session/GPU)\n";
  }
  """)
  PY
  g++ -std=c++17 -DONNX_RUNTIME_USE_CUDA=1 \
    -I${lib.getDev cpu.runtime}/include/onnxruntime probe.cpp \
    -L${lib.getLib cpu.runtime}/lib -Wl,-rpath,${lib.getLib cpu.runtime}/lib \
    -lonnxruntime -o probe
  ./probe
  python3 - <<'PY'
  from pathlib import Path
  source = Path('Source/DSP/OnnxDenoiser.cpp').read_text()
  assert 'Ort::ThrowOnError (OrtSessionOptionsAppendExecutionProvider_CUDA (sessionOptions, 0));' in source, 'CUDA status must be released through ThrowOnError'
  PY
  # Compile the real upstream CUDA append path against the selected ORT headers.
  # This does not link/load CUDA, create a session, or establish GPU execution.
  g++ -std=c++17 -fsyntax-only \
    -DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED=1 -DJUCE_STANDALONE_APPLICATION=0 \
    -DENABLE_ONNX_RUNTIME=1 -DONNX_RUNTIME_USE_CUDA=1 \
    -I${cpu.juceSource}/modules -I${lib.getDev cpu.runtime}/include/onnxruntime \
    Source/DSP/OnnxDenoiser.cpp
  touch "$out"
''
