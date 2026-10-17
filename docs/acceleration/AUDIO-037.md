# AUDIO-037 — DirtyBoy

**Complete; ai_role: none; execution_mode: not-applicable.** Repository `ajsprojects/DirtyBoy`, pinned `483167b7487c2823118e836a9b648b72baaeab06`; official commits/tree/contents APIs inspected.

One distortion product. `processBlock` applies explicit sample-level drive/tanh and parameterized distortion processing, not learned weights or a neural runtime. `DirtyBoy.jucer` provides a Visual Studio 2019 exporter and JUCE module configuration. That is a concrete Windows source lead; it is not proof of the OS/ABI of an in-repository binary, native Linux support, or Wine acceptance. No neural/GPU provider is evidenced by the processor/project path.

Pinned upstream assessment evidence:
- [Actual distortion callback](https://github.com/ajsprojects/DirtyBoy/blob/483167b7487c2823118e836a9b648b72baaeab06/Source/PluginProcessor.cpp)
- [JUCE project and VS2019 exporter](https://github.com/ajsprojects/DirtyBoy/blob/483167b7487c2823118e836a9b648b72baaeab06/DirtyBoy.jucer)

Backends empty. Next action: establish reproducible CPU source dependencies and exporter output/architecture, then independently evaluate Windows host/Wine or Linux porting. All evaluation/build/load/model_execution/provider_execution/host stages **not-run**; future AMD hardware stages **not-run-policy**. No verified reuse grant in existing catalog metadata: preserve that informational concern and consumer judgement; it does not block this technical assessment.
