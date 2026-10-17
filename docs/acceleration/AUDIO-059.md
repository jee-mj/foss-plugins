# AUDIO-059 — ArSonKuPik distribution repository

Assessment: **blocked-evidence; unknown; unknown** (2026-10-17).
Pinned public repository: `masarray/vst-enhancer` at `9722ea02cb8bd291d4e03c945414ba0e0f0c0e65`.

## Actual evidence boundary
The complete recursive Git tree exposes website, release tools and documentation, not the product DSP source. [build-macos-and-publish.yml](https://github.com/masarray/vst-enhancer/blob/9722ea02cb8bd291d4e03c945414ba0e0f0c0e65/.github/workflows/build-macos-and-publish.yml) resolves proprietary `masarray/askp-vst` source via a secret, checks its exact private source/helper commits, and hands off source-free binaries. [RELEASE-PROVENANCE.md](https://github.com/masarray/vst-enhancer/blob/9722ea02cb8bd291d4e03c945414ba0e0f0c0e65/RELEASE-PROVENANCE.md) documents private v0.5.24 source `2c764f82b0fc99eaff04d918cef4f839db7509e5`, helper `30fda826fec8aeb00eba07fe0d920e85b42d4596`, and JUCE 8.0.14. That older provenance is **not** a verified identity for the catalog's v0.5.26 release.

## Block and next action
Public source cannot establish whether the private product implements inference, which models are used, or any CPU/NVIDIA/AMD provider. Website claims about learning/Gain Match cannot answer this. Obtain an authorized, exact-release DSP/build dependency disclosure or reviewable source subset from upstream. No attempt to access private source or download binaries was made. This is an evidence-access block, not a license implementation gate. No NN components or backend tuple invented; the application component denotes the distributed enhancer only. Native Windows and Wine behavior remain separately unknown. All execution stages not-run.
