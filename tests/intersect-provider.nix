{ runCommand, stdenv, binutils, unzip, intersect, archiveAudit ? false }:

# A model-free ORT ABI/load check, never a provider-execution test.
if archiveAudit then
  # Exercise the real runtime artifact selection without downloading its GPU
  # closure. Output libraries are deliberately unpatched and never loaded here.
  runCommand "intersect-${intersect.provider}-archive-audit" {
    src = intersect.ortRuntime.src;
    nativeBuildInputs = [ unzip binutils ];
  } ''
    unzip -q "$src"
    ${intersect.ortRuntime.installPhase}
    test ! -e "$out/lib/libonnxruntime_providers_tensorrt.so"
    test -s "$out/lib/libonnxruntime.so.1.24.2"
    for file in "$out"/lib/*.so*; do
      if test -L "$file"; then continue; fi
      readelf -d "$file" >> "$out/elf-dynamic.txt"
    done
  ''
else
runCommand "intersect-provider-api" {
  nativeBuildInputs = [ stdenv.cc ];
} ''
  # CUDA selection must not drag the unused TensorRT EP/dependencies along.
  test ! -e ${intersect.ortRuntime}/lib/libonnxruntime_providers_tensorrt.so
  cat > probe.cpp <<'CPP'
  #include <dlfcn.h>
  #include <cstring>
  #include <iostream>
  #include <onnxruntime_c_api.h>
  int main(int argc, char** argv) {
    if (argc != 2) return 1;
    void* library = dlopen(argv[1], RTLD_NOW | RTLD_LOCAL);
    if (!library) { std::cerr << dlerror() << '\n'; return 2; }
    auto getBase = reinterpret_cast<const OrtApiBase* (*)()>(dlsym(library, "OrtGetApiBase"));
    if (!getBase) return 3;
    const auto* base = getBase();
    if (std::strcmp(base->GetVersionString(), "1.24.2")) return 4;
    const auto* api = base->GetApi(ORT_API_VERSION);
    if (!api || !api->SessionOptionsAppendExecutionProvider_CUDA ||
        !api->SessionOptionsAppendExecutionProvider_MIGraphX) return 5;
    OrtEnv* env = nullptr;
    if (auto* status = api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "intersect-package-check", &env)) {
      std::cerr << api->GetErrorMessage(status) << '\n';
      api->ReleaseStatus(status); return 6;
    }
    api->ReleaseEnv(env);
    std::cout << "ORT 1.24.2 API " << ORT_API_VERSION << " + CreateEnv passed (no model/session/GPU)\n";
  }
  CPP
  c++ -I${intersect.ortHeaders}/include probe.cpp -ldl -o probe
  ./probe ${intersect.ortRuntime}/lib/libonnxruntime.so
  touch "$out"
''
