"""Build-time adaptation of the pinned source: offline assets and private runtime."""
from pathlib import Path
import re
import sys

runtime, provider = sys.argv[1:]


def replace_body(path, signature, body):
    source = Path(path).read_text()
    pattern = re.escape(signature) + r"\s*\{.*?^\}"
    source, count = re.subn(pattern, lambda _: signature + "\n{\n" + body + "\n}", source,
                            count=0, flags=re.DOTALL | re.MULTILINE)
    assert count == 1, (path, signature, count)
    Path(path).write_text(source)


# Replace the complete downloader bodies, including manifest fetches. Local
# manifests remain readable, but cannot cause model/runtime network acquisition.
for filename in ["StemModelDownloadJob.cpp", "OrtBundleDownloadJob.cpp"]:
    path = Path("src/audio") / filename
    source = path.read_text()
    signature = re.search(r"bool downloadFileToTarget \(.*?\)\n\{", source, re.DOTALL)[0][:-2]
    replace_body(path, signature,
                 '    errorMessage = "Downloads disabled in this package; install assets manually";\n'
                 '    return false;')

replace_body("src/audio/StemSeparation.cpp", "juce::String getAvailableGpuProviderName()",
             '    return "' + {"cpu": "", "cuda12": "CUDA", "migraphx": "MIGraphX"}[provider] + '";')
replace_body("src/audio/StemSeparation.cpp",
             "juce::File resolveActiveOrtLibraryFile (const juce::File& ortRoot)",
             '    return juce::File ("' + runtime + '/lib/libonnxruntime.so");')
