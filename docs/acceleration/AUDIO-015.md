# AUDIO-015 — HayesPlugins

- Repository: `Emmet-Hayes/HayesPlugins`
- Inspected commit: `6295db156cf2f71d4a658b3198f701347bd86b9f`
- Assessment: **blocked-evidence**; AI role **unknown**; execution mode **unknown**.

## Inspected components and concrete block

[Distortion processing](https://github.com/Emmet-Hayes/HayesPlugins/blob/6295db156cf2f71d4a658b3198f701347bd86b9f/HayesDistortion/Source/HayesDistortionAudioProcessor.cpp) implements multiband filtering, clipping, compression and limiting with JUCE DSP. Its [Projucer build](https://github.com/Emmet-Hayes/HayesPlugins/blob/6295db156cf2f71d4a658b3198f701347bd86b9f/HayesDistortion/HayesDistortion.jucer) enumerates those DSP and shared UI sources. These are conventional CPU DSP, not neural inference. [Visualizer processing](https://github.com/Emmet-Hayes/HayesPlugins/blob/6295db156cf2f71d4a658b3198f701347bd86b9f/HayesVisualizer/Source/HayesVisualizerAudioProcessor.cpp) has an empty processBlock; OpenGL UI support does not establish GPU audio inference.

The [pinned Git tree](https://github.com/Emmet-Hayes/HayesPlugins/tree/6295db156cf2f71d4a658b3198f701347bd86b9f) contains mode-160000 gitlinks for the other products and JUCE, but `.gitmodules` returns 404 at this commit. Product source/build paths cannot be traversed as ordinary files in this repository. Pin inventory from the official Git tree API:

| Product | Recorded gitlink |
| --- | --- |
| BatSynth | `81d7a00c5c0f71d9b7295df53389773a52b12e2a` |
| HayesCompressor | `25bcbc06c1ed3215c879eee38f026496c2d23230` |
| HayesDelay | `dd038a18018f40e4bf8f14423da9166e1aa3095e` |
| HayesEQ | `67684c0d1e1f27ae849b84b0d6c394c4cf80c0b1` |
| HayesFDNReverb | `34aad2ad552525e84c360de8b6068755867aee2a` |
| HayesPitchShifter | `8cb18e97b9b5e7c60bd1e57c987a439be17a7b56` |
| HayesReverb | `f390dcc0df7ae72a2b6518f98eb3aa0f83913035` |
| HayesTapeDelay | `afa28934f6be36056f99a83f5306be41cc72eba1` |

Each is a separate application component pending source inspection, alongside the inspected distortion DSP and visualizer application. Names or suite README claims cannot establish their inference/backend requirements. Resolve official URLs for these exact gitlinks, inspect each processor and build at its recorded commit, and then replace the blocked suite conclusion. Do not substitute another repository's HEAD.

## Disposition

No packaged backend, runtime tuple, model or GPU route established. All evaluation/build/load/model/provider/host validation **not-run**; no build or GPU execution performed. Any future AMD model/provider/host hardware stages must be **not-run-policy**, with the campaign exclusion reason. The block concerns missing source provenance, not license metadata. Existing copyright evidence remains unchanged.
