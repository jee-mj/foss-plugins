# AUDIO-018 — Dihtortion

- Repository: `ClyntiaAikaHanaa/Dihtortion`
- Commit: `00e4e3bfd6904385e1328abd4f1cdf5b24686cc9`
- Assessment: **complete**; AI role **none**; execution **not-applicable**.

[AsymmetricFolder.h](https://github.com/ClyntiaAikaHanaa/Dihtortion/blob/00e4e3bfd6904385e1328abd4f1cdf5b24686cc9/Source/AsymmetricFolder.h) implements analytic waveshaping including tanh/atan and folding curves. [PluginProcessor.cpp](https://github.com/ClyntiaAikaHanaa/Dihtortion/blob/00e4e3bfd6904385e1328abd4f1cdf5b24686cc9/Source/PluginProcessor.cpp) configures oversampling, filtering, cabinet IR convolution and separate room IR convolution. “Model” selection here selects cabinet IRs, not neural weights. Components: `amp-wavefolder`, `cabinet-convolution`, `room-convolution`, all non-neural DSP.

[CMakeLists.txt](https://github.com/ClyntiaAikaHanaa/Dihtortion/blob/00e4e3bfd6904385e1328abd4f1cdf5b24686cc9/CMakeLists.txt) fetches JUCE 7.0.12 and links JUCE audio/DSP code. No NN framework or GPU provider established. Windows x64 remains the catalog artifact/Wine lead; native Linux needs separate source/platform work. Neither route implies GPU support. IR assets are content, not inference model references.

No backend provider proposed; pins/models arrays remain unneeded. All evaluation/build/load/model/provider/host validation **not-run**. Future AMD hardware model/provider/host stages must be **not-run-policy** because AMD execution is outside the campaign. Next: freeze dependencies and inspect Windows package/host behavior without changing catalog identity or copyright; existing IR/license concerns remain informational.
