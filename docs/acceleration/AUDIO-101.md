# AUDIO-101 — Nota

Assessment: **complete; ai_role inference; execution_mode background-job**.
Official GitHub API pin: `nota-daw/nota@11771f8ab93b6c40e236e1c8ecf87c7f86d984eb`.

## Application and actual inference components

- `daw-host`: native application/engine and plugin hosting. [Engine build](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/native/nota.engine/CMakeLists.txt) builds an engine shared library, JUCE hosting and separate scan worker; hosting another plugin does not transfer that plugin's NN/GPU requirements to Nota.
- `pentad-plugin`: the same CMake file contains **off-by-default** `NOTA_BUILD_PENTAD_VST3`, a debug VST3 wrapper around header-only Pentad DSP. [Pentad.h](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/native/nota.engine/src/Pentad.h) implements oscillator voices, ADSRs, nonlinear filters, BLEP edges and HIIR downsampling, not neural inference. This source option is distinct from the delivered DAW and from clip AI; no inference dependency is linked to this target. It does not establish a shipped Nota effect plugin or successful build.
- `stem-separation`: [StemSeparator](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/Ai/StemSeparator.cs) executes local htdemucs ONNX with waveform and spectrogram inputs and four stems. It performs explicit C# STFT/iSTFT, normalization and overlap-add outside the graph.
- `pitch-transcription`: [PitchTranscriber](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/Ai/PitchTranscriber.cs) runs Spotify basic-pitch ONNX on 22.05 kHz windows and decodes notes/onsets.

[ClipAi](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/Ai/ClipAi.cs) separates engine-thread read/apply steps from model work; stems may take tens of seconds. AI features require explicitly installed model/runtime assets; they are not mandatory neural processing in every plugin callback.

## Runtime/model provenance and GPU disposition

[Infrastructure project](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/Nota.Infrastructure.csproj) pins `Microsoft.ML.OnnxRuntime.Managed` **1.23.2**, not the native library. [OnnxRuntimeLoader](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/Ai/OnnxRuntimeLoader.cs) dynamically resolves a user-installed native runtime and constructs a CPU session with no CUDA/MIGraphX/DirectML provider append calls.

[ModelCatalog](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/ModelStore/ModelCatalog.cs) fixes official ORT 1.23.2 CPU archives, hashes and sizes for Linux x64/aarch64, Windows x64/arm64, macOS x86_64/arm64. Machine backend rows enumerate the x86_64 Linux/Windows research routes; the other CPU targets are source-supported manifest entries, not locally tested platforms. [ModelStore](https://github.com/nota-daw/nota/blob/11771f8ab93b6c40e236e1c8ecf87c7f86d984eb/src/managed/Nota.Infrastructure/ModelStore/ModelStore.cs) installs only on explicit request and verifies pinned size/hash before staging. No download was requested in this campaign.

| Model | Provenance | Source-declared bytes / SHA-256 | Terms recorded upstream |
| --- | --- | --- | --- |
| htdemucs | nota-daw/nota-models release `htdemucs-v1`, exported without STFT | 174264717 / `04c2b1a149788d048f710a6140446a72f7b4bab3171bc42189176a64ed609c78` | Meta Demucs v4, MIT; declaration not a fresh legal audit |
| basic-pitch | Spotify `v0.4.0` `nmp.onnx` | 230444 / `2c3c1d144bfa61ad236e92e169c13535c880469a12a047d4e73451f2c059a0ec` | Apache-2.0, declared in ModelCatalog |

Hashes/sizes are inspected source declarations, **not acquired-byte verification**. Model repository commits are unresolved and remain null in model references; plugin source revision is full and pinned.

Linux NVIDIA ORT CUDA and AMD ORT MIGraphX for stem separation are **port-required research candidates**, not upstream implementations: provider selection, matching managed/native ABI, immutable runtime bundle, deployment and graph/node placement must be implemented and measured. The source's CPU archive cannot become a GPU build by metadata change. No ORT ROCm route is asserted. Basic-pitch also has no GPU integration; no performance case for porting it is established. Native Windows uses CPU sessions too; DirectML and Wine are unimplemented/unverified routes, not inferred from ONNX. No Mac CoreML/MPS integration is implied.

All evaluation/build/load/execution stages not-run; AMD candidate model/provider/host stages are not-run-policy because AMD hardware execution is excluded. Existing copyright retained. Next: package the CPU application/runtime without implicit model downloads if authorized; evaluate optional stem-separation provider ports separately from hosting and transcription.
