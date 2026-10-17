{ lib, stdenv, fetchurl, unzip, autoPatchelfHook, cudaPackages, rocmPackages
, provider ? "cpu"
}:
let
  bundles = {
    cpu = { hash = "935bcfe2a545ab5ce9ae528fd2a1d5076faf32decdae5ddbe815e45999fb47da"; bytes = 8093658; };
    cuda12 = { hash = "8c3bf32ec93d87085253a3ccf1ef96d93ea22c547802705b5b3addc7d3a2a988"; bytes = 205347957; };
    migraphx = { hash = "f03788631da52c9c0aeadd58b04056d512474fcee8a8c8e8da8479cdf26adae6"; bytes = 9866383; };
  };
  bundle = bundles.${provider} or (throw "INTERSECT: supported package providers are cpu, cuda12, migraphx");
  gpuLibs = if provider == "cuda12" then (with cudaPackages; map lib.getLib [
    cuda_cudart libcublas libcufft libcurand cudnn
  ]) else if provider == "migraphx" then (with rocmPackages; [
    clr migraphx
  ]) else [];
in stdenv.mkDerivation {
  pname = "intersect-ort-${provider}";
  version = "1.24.2";
  src = fetchurl {
    url = "https://github.com/tucktuckg00se/intersect-ort-providers/releases/download/ort-1.24.2/onnxruntime-linux-x64-${provider}.zip";
    sha256 = bundle.hash;
  };
  nativeBuildInputs = [ unzip autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ] ++ gpuLibs;
  sourceRoot = ".";
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    mkdir -p "$out"
    cp -a lib include "$out/"
  '' + lib.optionalString (provider == "cuda12") ''
    # Upstream repacks Microsoft's complete GPU archive, including TensorRT.
    # INTERSECT calls CUDA, never TensorRT; do not import that unrelated closure.
    rm "$out/lib/libonnxruntime_providers_tensorrt.so"
  '';
  # libcuda is provided by the consumer's driver; no driver is bundled or probed.
  autoPatchelfIgnoreMissingDeps = lib.optional (provider == "cuda12") "libcuda.so.1";
  # ORT loads provider DSOs by path next to its core library. Provider DT_NEEDED
  # dependencies are patched locally, never through a DAW-wide environment.
  passthru = {
    inherit provider;
    archiveBytes = bundle.bytes;
    archiveSha256 = bundle.hash;
    runtimeId = "intersect-ort-1.24.2-linux-x64-${provider}"
      + lib.optionalString (provider == "cuda12")
        "-cudart-${cudaPackages.cuda_cudart.version}-cudnn-${cudaPackages.cudnn.version}"
      + lib.optionalString (provider == "migraphx")
        "-rocm-${rocmPackages.clr.version}-migraphx-${rocmPackages.migraphx.version}";
    ortRevision = "058787ceead760166e3c50a0a4cba8a833a6f53f";
  };
  meta = {
    description = "Pinned official INTERSECT ONNX Runtime ${provider} bundle";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
