{ callPackage }:

let
  pluginArtifacts = callPackage ../lib/plugin-artifacts.nix { };
  juceRuntime = callPackage ../lib/juce-runtime.nix { };

  projucer = callPackage ./rdpiano/projucer.nix { };
in
rec {
  # The free package set: clean open-source with verified licences.
  freePackages = {
    amsynth = callPackage ./amsynth { inherit pluginArtifacts; };
    modal-synth = callPackage ./modal-synth { inherit pluginArtifacts juceRuntime; };
    space-dust-synthesizer = callPackage ./space-dust-synthesizer { inherit pluginArtifacts juceRuntime; };
    squelchbox = callPackage ./squelchbox { inherit pluginArtifacts; };
    ultramaster-kr106 = callPackage ./ultramaster-kr106 { inherit pluginArtifacts juceRuntime; };

    # Phase 1 accept-source: GPL-3.0 / Apache-2.0, complete source, reviewed.
    setekh = callPackage ./setekh { inherit pluginArtifacts juceRuntime; };
    neuralnote = callPackage ./neuralnote { inherit pluginArtifacts juceRuntime; };
    ripplerx = callPackage ./ripplerx { inherit pluginArtifacts juceRuntime; };
  };

  # The unfree/impure gate: experimental, missing-license, or binary-only.
  unfreePackages = {
    mechanodd = callPackage ./mechanodd { inherit pluginArtifacts juceRuntime; };
    rdpiano = callPackage ./rdpiano { inherit pluginArtifacts projucer; };

    # accept-experimental: requires Ollama at runtime, localhost network surface.
    cavey = callPackage ./cavey { inherit pluginArtifacts juceRuntime; };

    # blocked-pending-upstream: missing LICENSE file in repo (README claims MIT).
    openkick = callPackage ./openkick { inherit pluginArtifacts juceRuntime; };

    # blocked-pending-upstream: lumena submodule license unverified.
    lumen = callPackage ./lumen { inherit pluginArtifacts juceRuntime; };

    # binary-only-manual-approval: proprietary EULA-governed freeware.
    mt-power-drum-kit = callPackage ./mt-power-drum-kit { inherit pluginArtifacts; };
  };

  freePackageNames = builtins.attrNames freePackages;
  unfreePackageNames = builtins.attrNames unfreePackages;
}
