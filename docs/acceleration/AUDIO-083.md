# AUDIO-083 — Oiko Audio

Assessment: **complete** · AI role: **none** · execution: **not-applicable**.
Source: `oikoaudio/oikoaudio@79a34e08d65510f006939aab4fca7ebae2f8bd2f`.
The three `wow/`, `weft/` and `inton/v0.5.0-beta.3` release tags all resolve to this commit. Release metadata lists separate Linux x86_64, Windows x86_64 and macOS universal artifacts for each; no artifact was fetched.

## Per-product assessment

- **Weft:** spectral-plugin builds realfft plans, uses NicePlug STFT and applies spectral-dsp gain masks. Its numerical processing prepares FFT windows and tables. Particle/mask and MIDI-harmonic operations are DSP, not NN inference.
- **Wow:** `wow-dsp/src/modulation.rs` explicitly implements bounded deterministic modulation trajectories for a variable-delay reader, including smooth random modulation. No learned model is involved.
- **Inton:** tuning/project-state control, a C++ tuning parser built through `oiko-tuning/build.rs`, and dynamically loaded official ODDsound MTS-ESP master ABI. Parsing, dynamic loading and MTS calls run on the control thread, not the audio process callback. This is not an ML runtime and differs materially from Weft/Wow's audio DSP.

## Upstream assessment evidence

- [Workspace/build dependencies](https://github.com/oikoaudio/oikoaudio/blob/79a34e08d65510f006939aab4fca7ebae2f8bd2f/Cargo.toml)
- [Weft STFT plugin](https://github.com/oikoaudio/oikoaudio/blob/79a34e08d65510f006939aab4fca7ebae2f8bd2f/plugins/weft/crates/spectral-plugin/src/lib.rs)
- [Weft gain masks](https://github.com/oikoaudio/oikoaudio/blob/79a34e08d65510f006939aab4fca7ebae2f8bd2f/plugins/weft/crates/spectral-dsp/src/lib.rs)
- [Wow modulation](https://github.com/oikoaudio/oikoaudio/blob/79a34e08d65510f006939aab4fca7ebae2f8bd2f/plugins/wow/crates/wow-dsp/src/modulation.rs)
- [Inton MTS ABI/loading](https://github.com/oikoaudio/oikoaudio/blob/79a34e08d65510f006939aab4fca7ebae2f8bd2f/plugins/inton/crates/inton-core/src/mts.rs)
- [Tuning parser build](https://github.com/oikoaudio/oikoaudio/blob/79a34e08d65510f006939aab4fca7ebae2f8bd2f/crates/oiko-tuning/build.rs)

No neural backend/model references are recorded. GUI graphics dependencies do not imply inference acceleration. All campaign stages remain not-run; upstream releases/tests are provenance only. Rights: retain MIT OR Apache-2.0 and separate bundled/upstream notices; MTS dependency rights need their own review, not an inferred grant.

Next action: establish three distinct CPU artifact identities, review Inton's MTS runtime availability and beta automation compatibility before packaging.
