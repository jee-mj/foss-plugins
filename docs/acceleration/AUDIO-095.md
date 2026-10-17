# AUDIO-095 — WetCompressor

Assessment: **complete; ai_role none; execution_mode not-applicable**.
Official API pin: `yonie/WetCompressor@7a731ee62e5c9681819049daf615730af6bb1ded`.

- [Processor](https://github.com/yonie/WetCompressor/blob/7a731ee62e5c9681819049daf615730af6bb1ded/WetCompressor/source/wetcompprocessor.cpp) passes audio and external key channels to `engine.processStereo()`.
- [Engine](https://github.com/yonie/WetCompressor/blob/7a731ee62e5c9681819049daf615730af6bb1ded/WetCompressor/source/compengine.cpp) computes transformer, FET gain-cell, feedback sidechain and amplifier stages explicitly, with independent filtered noise. [Header](https://github.com/yonie/WetCompressor/blob/7a731ee62e5c9681819049daf615730af6bb1ded/WetCompressor/source/compengine.h) identifies the analog signal path and external sidechain.
- [Build](https://github.com/yonie/WetCompressor/blob/7a731ee62e5c9681819049daf615730af6bb1ded/WetCompressor/CMakeLists.txt) includes `fetcore.h`, engine and VST3 SDK; Apple AU wrapper is conditional. No model runtime integration found in this path.

`wet-compressor` is conventional CPU DSP, not NN inference. No vendor GPU dependency established. Native Linux is a source lead; external-sidechain bus support needs actual host acceptance, and Wine is untested. All campaign compilation/load/execution stages unrun. Copyright metadata preserved. Next: verify SDK pin, native artifacts and sidechain behavior when authorized.
