# AUDIO-072 — ToneTwistPlugs

Assessment date: 2026-10-17. Repository: `brummer10/ToneTwistPlugs`.
Pinned source: `5fac29094050eecf665479921e6ebbd3595b2281`; official GitHub commit/tree/contents APIs, inspecting actual wrappers and DSP implementations.

## Outcome and actual products

**complete; ai_role: none; execution_mode: not-applicable.** The [root Makefile](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/Makefile), lines 95–101 and installation targets, builds six products. All have non-neural CPU components and independent backend records:

| Component | Product / runtime path | Pinned implementation |
| --- | --- | --- |
| `metaltone` | MetalTone: pre/distortion/post stages | [callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/MetalTone/PluginMetalTone.cpp), [pre](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/MetalTone/MetalTone_pre.cc), [distortion](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/MetalTone/MetalTone_dist.cc), [post](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/MetalTone/MetalTone_post.cc) |
| `collision-drive` | CollisionDrive: circuit/filter processing and resampling | [callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/CollisionDrive/PluginCollisionDrive.cpp), [DSP](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/CollisionDrive/CollisionDrive.cc) |
| `rumor` | Rumor: generated filter/recurrence and static nonlinear table | [callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/Rumor/PluginRumor.cpp), [DSP](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/Rumor/Rumor.cc) |
| `tube-screamer` | TubeScreamer: explicit filters and nonlinearity | [callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/TubeScreamer/PluginTubeScreamer.cpp), [DSP](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/TubeScreamer/TubeScreamer.cc) |
| `valve-caster` | ValveCaster with internal booster | [callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/ValveCaster/PluginValveCaster.cpp), [DSP](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/ValveCaster/ValveCaster.cc), [booster](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/ValveCaster/ValveCasterBooster.cc) |
| `boob-tube` | BoobTube with regular/60V modes sharing CPU requirements | [callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/BoobTube/PluginBoobTube.cpp), [regular DSP](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/BoobTube/BoobTube.cc), [60V DSP](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/BoobTube/BoobTube60V.cc) |

`NewPedal` is present as a development template; [its callback](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/NewPedal/PluginNewPedal.cpp) was inspected, but it is not in the built/installed product list and receives no invented public product identity.

Each real callback directly calls `compute` on audio buffers. Inspected implementations use generated Faust recurrences, explicit coefficient arithmetic, nonlinear lookup tables and resampling. Circuit/pedal modeling and static tables do not make this a neural runtime. These findings are source-backed, not inferred from README descriptions. [MetalTone's Makefile](https://github.com/brummer10/ToneTwistPlugs/blob/5fac29094050eecf665479921e6ebbd3595b2281/plugins/MetalTone/Makefile) also identifies the DPF DSP wrapper compilation path.

## Integration and limits

Six Linux CPU backend records (`dpf-faust-cpp`, except `tube-screamer` uses `dpf-cpp-dsp`), architecture unknown. All `not-packaged`; exports/runtime IDs null; pins/model refs empty. Generated DSP is compiled C++, not proof of a fetched Faust runtime. No neural or GPU-audio provider identified in these processing/build paths; Windows/macOS format targets do not establish Wine acceleration.

All six validation stages per backend are `not-run`. No AMD GPU route is asserted; future AMD GPU model/provider/host execution must remain `not-run-policy` because campaign hardware policy excludes it.

Next: pin DPF/resampler inputs and verify all six products/formats independently, including BoobTube voltage and ValveCaster booster switching. Root license metadata remains informational: inspect individual file/dependency grants and preserve notices and consumer judgement; no blanket suite relicense or technical block is introduced.
