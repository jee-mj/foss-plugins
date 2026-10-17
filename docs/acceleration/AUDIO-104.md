# AUDIO-104 — Comp76Fx suite

Assessment: **complete; ai_role none; execution_mode not-applicable**.
Official API pin: `BurningTreeC/comp76fx@b8a8348276d9d9251e8a821ba3b3440d7496d8f3`.

## Product-level identities

| Component | Source identity | DSP differences |
| --- | --- | --- |
| `rev-a` | [rev_a/src/lib.rs](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/rev_a/src/lib.rs), CLAP `com.burningtreec.comp76fx.rev-a`, AU subtype C76A | Bluestripe, JFET/earlier switch bank, noisier circuit voicing |
| `rev-d` | [rev_d/src/lib.rs](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/rev_d/src/lib.rs), CLAP `com.burningtreec.comp76fx.rev-d`, AU subtype C76D | Low-noise Blackface, Class A output |
| `rev-f` | [rev_f/src/lib.rs](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/rev_f/src/lib.rs), CLAP `com.burningtreec.comp76fx.rev-f`, AU subtype C76F | Low-noise circuit, push-pull Class AB output |

All three have distinct VST3 identifiers too. [Shared plugin body](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/core/src/plugin.rs) routes samples through `Channel`/dry delay and exports each revision via a macro. [DSP](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/core/src/dsp/mod.rs) and [revision constants](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/core/src/dsp/revisions.rs) encode circuit/switch/sidechain/transistor values, not learned networks. Separate components preserve product identities even though runtime requirements coincide.

[Cargo workspace](https://github.com/BurningTreeC/comp76fx/blob/b8a8348276d9d9251e8a821ba3b3440d7496d8f3/Cargo.toml) pins nice-plug revision `e60b5db09d8606c3dc3e93f982847a00bce17325`, with vendored UI/AUv2 adapters and shared core/revision crates. No neural framework/provider dependency in inspected manifests or processing path. GUI rendering is not classified as neural GPU acceleration.

No NN backend/model references or vendor GPU requirement established. Native Linux CLAP/VST3 packaging is a lead; Windows, macOS and Wine need separate artifact/host checks. No compilation, executable tests, load or host execution performed. GPL and third-party notices remain unchanged and not freshly audited. Next: preserve all three identities and pin Cargo/vendor sources in authorized native packaging.
