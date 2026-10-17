# AUDIO-029 — AssEffect

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `Wamphyre/AssEffect`, pinned `8874a1f00ed30cc04e6bbfa6876d29da8f6d9575`; official commits/tree/contents APIs inspected.

One non-neural lo-fi product: the callback calls `LoFiEngine::process`, using oversampling, tanh saturation, filters, envelope/memory effects, noise, modulated delays and quantization. Device/machine presets do not select CUDA devices. CMake explicitly rejects non-Linux systems, declares VST3, links JUCE DSP and optionally enables CPU-native optimization; absent local JUCE it requests 8.0.10. No inference framework or GPU DSP implementation was found in this processing/build path.

Pinned upstream assessment evidence:
- [Callback dispatch](https://github.com/Wamphyre/AssEffect/blob/8874a1f00ed30cc04e6bbfa6876d29da8f6d9575/Source/PluginProcessor.cpp)
- [Actual lo-fi DSP](https://github.com/Wamphyre/AssEffect/blob/8874a1f00ed30cc04e6bbfa6876d29da8f6d9575/Source/LoFiEngine.cpp)
- [Linux-only build and CPU options](https://github.com/Wamphyre/AssEffect/blob/8874a1f00ed30cc04e6bbfa6876d29da8f6d9575/CMakeLists.txt)

Backends empty because no neural/GPU provider is evidenced. Next action: evaluate the native Linux CPU VST3 dependency closure and mono/stereo host behavior. Windows/Wine is not established by this Linux-only recipe. All evaluation/build/load/model_execution/provider_execution/host stages are **not-run**. Future AMD hardware stages must be **not-run-policy**. Existing BSD/JUCE rights concerns are preserved and are not a technical gate.
