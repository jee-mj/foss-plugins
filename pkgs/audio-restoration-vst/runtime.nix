{ lib, stdenvNoCC, gccStdenv, fetchurl, autoPatchelfHook, python3, cudaPackages, zlib
, provider ? "cpu"
}:
assert builtins.elem provider [ "cpu" "cuda" ];
let
  version = "1.24.4";
  archiveName = "onnxruntime-linux-x64${lib.optionalString (provider == "cuda") "-gpu"}-${version}";
in
stdenvNoCC.mkDerivation {
  pname = "audio-restoration-onnxruntime-${provider}-bin";
  inherit version;
  src = fetchurl {
    url = "https://github.com/microsoft/onnxruntime/releases/download/v${version}/${archiveName}.tgz";
    hash = if provider == "cpu" then "sha256-OiEfvqJSweZikGWPG3NbdyBWFJ8oMh5xwwiULNtUt0c="
      else "sha256-xfgE/10jm0NvpZ6fL7KIo59+uVUvamNsi3HnkukaiAg=";
  };
  nativeBuildInputs = [ autoPatchelfHook python3 ];
  buildInputs = [ gccStdenv.cc.cc.lib zlib ] ++ lib.optionals (provider == "cuda") (with cudaPackages; [
    cuda_cudart libcublas libcufft libcurand cudnn libnvjitlink
  ]);
  preUnpack = ''
    python3 ${./audit-archive.py} "$src" > archive-members.txt
  '';
  dontConfigure = true;
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/include/onnxruntime" "$out/share/doc/$pname"
    cp -r include/. "$out/include/onnxruntime/"
    cp -a lib/libonnxruntime.so* lib/libonnxruntime_providers_shared.so "$out/lib/"
    ${lib.optionalString (provider == "cuda") ''
      cp lib/libonnxruntime_providers_cuda.so "$out/lib/"
    ''}
    # TensorRT is not the selected provider and must not acquire its closure.
    cp LICENSE ThirdPartyNotices.txt VERSION_NUMBER GIT_COMMIT_ID "$out/share/doc/$pname/"
    cp ../archive-members.txt "$out/share/doc/$pname/"
    runHook postInstall
  '';
  passthru = {
    inherit provider;
    provenance = "official-model-free-binary";
    sourceRevision = "2d924974ef147392ced8409d36bd6d2e7fcc8a74";
    archiveAuditScript = ./audit-archive.py;
  };
  meta = {
    description = "Official model-free ONNX Runtime binary and headers for AudioRestorationVST";
    homepage = "https://github.com/microsoft/onnxruntime";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
