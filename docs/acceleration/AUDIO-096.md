# AUDIO-096 — MPVST

Assessment: **blocked-evidence; ai_role unknown; execution_mode unknown** for the complete externally assembled suite. The inspected host is scripting infrastructure, not automatically NN inference.
Official API source pin: `PyDevices/mpvst@04573f58141e847a2eab95393ab0ea8e6e8e6142`.

## Established components

- `instrument-script-host`: [processor](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/src/plugin/source/processor.cpp) dispatches MIDI and audio via a sidecar. [Default instrument](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/lib/default_instrument.py) is silent unless explicitly enabled; no model inference in this default.
- `effect-script-host`: same processor has distinct input-enabled effect mode; [default effect](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/lib/default_effect.py) passes audio through. Script content determines DSP requirements.
- `named-product-catalog`: [catalog generator](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/lib/mpvst_catalog.py) obtains separate class identities, macros, patches and source paths from external `audioeffects`/`audioinstruments` modules. It is not a neural model catalog.

## Evidence blocker and next action

[Bootstrap source](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/scripts/bootstrap.sh) requires sibling `micropython-pydevices`, `audiocomponents`, `audiodsp`, `audioif`, `pydevices`, `ulab`, and installs unversioned TestPyPI component packages. The host revision does not identify the exact shipped module-source tuple. [Provenance checker](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/tools/engine-provenance.py) explicitly uses an external `pydevices-build.json` record for this purpose. That record and the corresponding frozen product catalog have not been established for this assessment. Therefore a complete product-by-product inference/backend conclusion for the bundled suite would overclaim the inspected host source.

Next: obtain the release's official textual provenance and product catalog, resolve full dependency revisions, then inspect each differing product's actual DSP source through official APIs. Do not run bootstrap or the engine to obtain them. User-added scripts cannot inherit a blanket NN/backend conclusion.

Native Linux and Windows sidecar packaging paths exist ([CMake](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/CMakeLists.txt), [Linux packaging](https://github.com/PyDevices/mpvst/blob/04573f58141e847a2eab95393ab0ea8e6e8e6142/scripts/package-linux.sh)); compilation and sidecar/host execution were not run. No GPU route asserted. License/SDK notices remain informational and unchanged, not this evidence blocker.
