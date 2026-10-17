# AUDIO-099 — AfroVocal Presets

Assessment: **complete; ai_role external-service; execution_mode external-service** (AI execution). Official GitHub API pin: `zephvibez-lab/AfroVocal-Presets@d75bbe5bfcd7b992a7ab3352c8e271304e2de580`.

## Component boundaries

1. `vocal-strip` — conventional local DSP. [ChannelDSP and processBlock](https://github.com/zephvibez-lab/AfroVocal-Presets/blob/d75bbe5bfcd7b992a7ab3352c8e271304e2de580/Source/PluginProcessor.cpp#L70-L303) implement filters, tuning, compressor/parallel compressor, saturation, delay and reverb. No local NN inference is established.
2. `offline-preset-generator` — local application logic. [generateNextPreset/applyGeneratedPreset](https://github.com/zephvibez-lab/AfroVocal-Presets/blob/d75bbe5bfcd7b992a7ab3352c8e271304e2de580/Source/PluginProcessor.cpp#L482-L524) deterministically combine genre/mood/texture indices, factory presets and arithmetic parameter offsets across 1024 indices. The generated name begins “AI /”, but this code does not run a learned model.
3. `online-preset-assistant` — optional external inference. [AiWorker](https://github.com/zephvibez-lab/AfroVocal-Presets/blob/d75bbe5bfcd7b992a7ab3352c8e271304e2de580/Source/PluginProcessor.cpp#L306-L348) requires an explicitly supplied API key, sends prompt/system messages to `https://api.openai.com/v1/chat/completions`, requests `gpt-4o-mini` JSON, and queues returned parameters for message-thread application. This worker is outside audio processing. Empty keys and connection failures leave offline presets available. The inspected request sends text, not recorded audio buffers.

[Build](https://github.com/zephvibez-lab/AfroVocal-Presets/blob/d75bbe5bfcd7b992a7ab3352c8e271304e2de580/CMakeLists.txt) fetches JUCE 8.0.10 and links JUCE audio utilities/DSP, not ONNX/PyTorch or GPU providers. Native Linux source remains a packaging lead; Windows is separate. The remote route is recorded for each native platform with unknown server hardware/architecture, not an invented local CUDA/ROCm/DirectML backend. Wine networking and hosting remain untested.

The service model name is mutable; server revision, weights, size and vendor are not exposed by this source. No downloadable model reference is invented. Runtime pins describe the requested service identifier only. Missing repository license is informational and does not block this technical assessment; existing copyright and consumer judgement are preserved.

All validation stages not-run. No requests to the service, credentials, artifacts, builds or models acquired. Next: preserve an offline CPU default and make online egress/service terms explicit in any authorized package; test each host context separately.
