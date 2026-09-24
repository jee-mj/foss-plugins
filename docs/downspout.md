# Downspout 0.16.2: source licensing and capability audit

Reviewed 2026-09-24. **Licensing verdict: suitable for free-package publication,
provided the applicable third-party notices accompany the binaries.** No
nonfree license blocker was found in the reviewed Linux VST3 build inputs.
This is not a claim that every file in the upstream repository is MIT, nor a
runtime security certification. **Campione is a default-on local control server
with destructive file-editing capabilities.** Treat that separately from license
eligibility.

## Pin, scope, and evidence

- Upstream: <https://github.com/danja/downspout>.
- Release: `v0.16.2`; commit:
  `0514385b0adc55ef9a4f592a5d6b412e0758809f`.
- `git rev-parse HEAD 'v0.16.2^{commit}'` returned that same commit twice in a
  separate audit checkout. The checkout was unmodified.
- All upstream paths below are relative to that pinned tree. Resolve them at
  <https://github.com/danja/downspout/tree/0514385b0adc55ef9a4f592a5d6b412e0758809f>.
- Reviewed the upstream CMake wiring, license notices, embedded-resource loading,
  source capability call sites, and relevant test bodies. Graph parsing has gaps
  in DPF macro-heavy wrappers; findings use source text, not absence of graph
  edges. Literal searches supplemented the symbol index.
- Local integration scope is `pkgs/downspout/default.nix`: Linux x86-64, VST3,
  Campione and Sidecar included, screenshot apps and AI coordinator OFF,
  VelociLoops forced to a nonexistent directory, and a Campione picker patch.
  Installation is an explicit allowlist, not everything CMake can build.
- This audit did **not** build or load the installed VST3s. An attempted isolated
  Debug core-test configuration stopped immediately because `cmake` was not on
  this audit shell's PATH. There is no passing test result from this audit.
  Package-build/CTest results must be supplied by the integration verification.

The expected **46 installed bundle basenames** are:

```text
campione bassgen p_mix e_mix m_mix t_mix mixgen loopdelay lightverb melgen
rift orchid ambo drumgen drumkit syrinx cadence arpgen counterpointer sidecar
gremlin gremlin_driver ground floozy basilico canticle moka luma paunchlad
lifeform xoxolo tuney_vst harmonic_atlas conductor drift mnemosyne polymeter
oracle mosaic resonance_garden orbit guardian chipper skream worms magneto
```

Other upstream targets can still compile without being installed. In particular,
**Midiscribe is not in this list**; do not attribute its MIDI-file export behavior
to the shipped package unless the allowlist changes.

## Build-input provenance and license inventory

The vendored files below are pinned by the parent Downspout commit, including
the copied DPF/Pugl trees; this audit does not invent separate submodule commits.
System C/C++ runtime, pthread, X11/extensions, OpenGL and D-Bus are linked system
dependencies, not undisclosed bundled SDKs. Their package licenses remain
applicable independently.

| Component / provenance | Paths and build use | License / publication requirement |
| --- | --- | --- |
| Downspout, Danny Ayers (2026) | Root `LICENSE`; `plugins/*/{src,include}`, shared `plugins/generative-common/include`, `include/`, `src/common/sampleprofile/`. Plugin CMake files select DSP/UI translation units and portable core libraries. | MIT. Preserve root notice; do not use it to erase vendor notices. |
| Tuney-derived implementation, Tom Ritchford (2025) | `plugins/tuney-vst/docs/TUNEY-LICENSE.md`; `plugins/tuney-vst/src/tuney_vst_engine.cpp`. | MIT with the additional original-author notice. The name “Tuney” here is not evidence of a cloud API dependency. |
| DPF / DGL, Filipe Coelho and contributors | `third_party/DPF/LICENSE`, `LICENSING.md`, `cmake/DPF-plugin.cmake`, `distrho/DistrhoPluginMain.cpp`, `DistrhoUIMain.cpp`, `distrho/src/DistrhoPluginVST3.cpp`, `DistrhoUIVST3.cpp`, DGL sources and `distrho/extra` utility headers. | ISC for framework code; preserve applicable per-file copyrights as well as the root DPF notice. The exceptions below are real additional components. |
| travesty VST3-compatible C API, Filipe Coelho (2021–2022) | `third_party/DPF/distrho/src/travesty/{base,align_push,align_pop,audio_processor,bstream,component,edit_controller,events,factory,host,message,unit,view}.h`. These are the VST3 wrapper's interface headers. | ISC permission headers, including `base.h:1–16`; DPF `LICENSING.md` explicitly identifies this implementation. **No official Steinberg VST3 SDK is needed by this build.** VST3 format alone does not introduce a proprietary SDK license here. |
| Pugl, David Robillard and contributors | `third_party/DPF/dgl/src/pugl-upstream/COPYING`, `include/pugl/`, `src/{common,internal,x11,x11_gl}.c` and associated headers, included through DPF `dgl/src/pugl.cpp`. | ISC for this runtime path; retain file-level authors. Pugl also carries `LICENSES/{0BSD,ISC,MIT}.txt` for its wider tree; those do not mean every runtime file is triple-licensed. |
| NanoVG and fontstash, Mikko Mononen | `third_party/DPF/dgl/src/nanovg/LICENSE.txt`, `nanovg.c`, `nanovg*.h`, `fontstash.h:1–16`; included by `dgl/src/NanoVG.cpp`. | zlib-style license. Preserve notice in source distributions, mark altered sources, do not misrepresent origin. Include the notice with package attributions as well. |
| stb_image | `third_party/DPF/dgl/src/nanovg/stb_image.h:210–216`, compiled via NanoVG. | This pinned copy has a **public-domain dedication plus perpetual irrevocable copy/distribute/modify fallback**, not merely an assumed modern stb MIT header. Preserve the actual text. |
| stb_truetype, Sean Barrett (2017) | `third_party/DPF/dgl/src/nanovg/stb_truetype.h:4971–5010`, fontstash font rasterizer. | Choice of MIT or public-domain/Unlicense. MIT is a straightforward redistribution choice; retain its copyright and permission text. |
| **Embedded DejaVu Sans font**, Bitstream / Tavmjong Bah / DejaVu contributors | `third_party/DPF/dgl/src/resources/DejaVuSans.ttf`, `LICENSE-DejaVuSans.ttf.txt`, generated `dgl/src/Resources.cpp`, declarations in `Resources.hpp`; `NanoVG::loadSharedResources()` calls `nvgCreateFontMem` on `dejavusans_ttf`. | Bitstream Vera and Arev font terms, with DejaVu changes in the public domain. **Not MIT or ISC.** Redistribution as part of this software package is permitted. Retain full copyright, trademark and permission notices; observe reserved-name conditions if modifying fonts and prohibition on selling the font alone. Neither condition blocks this plugin bundle. |
| libSOFD X11 file picker, Robin Gareus (2014) | `third_party/DPF/distrho/extra/sofd/libsofd.{c,h}`; `FileBrowserDialogImpl.cpp`, included by DGL when `USE_FILE_BROWSER` is enabled. | MIT notice at the beginning of `libsofd.c`. This remains relevant when replacing zenity with the DPF fallback. |
| cpp-httplib 0.53.1, Yuji Hirose (2026) | `third_party/cpp-httplib/httplib.h:1–12`; directly included by `plugins/campione/src/campione_mcp_server.cpp`; Campione core links pthread. | Header identifies MIT. Preserve its copyright and supply the MIT permission text in the binary notice collection; the vendored header's short label is not a substitute for shipping that text. |
| JSON for Modern C++ 3.12.0, Niels Lohmann (2013–2026) and embedded contributors | `third_party/nlohmann/json.hpp`, directly included by Campione MCP. `:348–354` identifies Hedley/Evan Nemerson (CC0); `:18866–18868` identifies Björn Hoehrmann's MIT code; `:18891–18919` identifies Florian Loitsch's MIT Grisu2 code. | MIT plus the embedded component notices. Retain these copyrights, not just Lohmann's. The header's Abseil/C++11 fallback at `:3412–3448` is MIT AND Apache-2.0; the C++20 build takes standard C++14-or-newer utilities instead, but retain that notice and Apache terms if redistributing the full header/source. All are free licenses. |

### Assets and excluded license surfaces

`dpf_add_plugin` defaults to OpenGL UI and shared resources. The plugin CMake
files do not request `NO_SHARED_RESOURCES`; `dpf__add_dgl_opengl` adds
`Resources.cpp`. Thus **the font is embedded in plugin shared libraries**, not
something that can be ignored because no loose `.ttf` is installed. UI source
has `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` fallback branches, but these
are guarded by `DGL_NO_SHARED_RESOURCES` and are not the normal selected build.
The reviewed plugin UI code draws controls with NanoVG; searches found no
additional plugin image/font embedding calls. Audio generators construct their
content in code; sample loaders read user-supplied files.

Do not copy the entire upstream tree into the binary output:

- `tests/freesound-samples/`, its `manifest.json`, example rendered WAVs,
  screenshots under `docs/pages/assets/`, DPF example/test artwork, and the
  repository's other demonstration assets are **not selected VST3 resources**.
  Their presence is not a licensing blocker for these binaries. This finding is
  not permission to repackage all those assets under root MIT.
- `third_party/freesound-js/` and `scripts/campione-freesound-helper.js` are not
  compiled or installed by the selected plugin targets. No Freesound download
  client is called by the reviewed Campione plugin code.
- DPF's LADSPA/DSSI LGPL headers, VST2 headers, CLAP headers, JACK/RtAudio/RtMidi
  standalone paths, WebView/CHOC, and examples are not this VST3-only runtime
  path. Do not infer their inclusion from the vendor directory alone.
- VelociLoops/REX2 is optional external source discovery in root CMake. The
  package must keep it disabled, including the `$HOME/github/VelociLoops`
  autodetection route. This audit does not license an externally supplied copy.
- `tools/ai-coordinator/` is explicitly disabled, not merely omitted from the
  install step. Its separate cloud client and service are outside this output.

The package installs **19 notice files** under `share/licenses/downspout`,
including the font, libSOFD, Tuney, HTTP/JSON embedded notices and chosen stb
terms. The guarded `collect-licenses.py` extracts notices from the pinned source
and fails on missing anchors. It also retains the embedded Raw Material Software
ISC grant in `distrho/extra/ScopedPointer.hpp` and the 2008–2010 Bjoern Hoehrmann
MIT attribution for fontstash's UTF-8 decoder. Root MIT metadata or this audit
document alone would not satisfy these obligations.

## Capabilities and operational policy

### Campione: enabled-by-default MCP listener and persistent writes

Source anchors: `plugins/campione/src/dpf/CampionePlugin.cpp`,
`plugins/campione/src/campione_mcp_server.cpp`, `campione_sample_loader.cpp`,
`campione_patch_io.cpp`, and `plugins/campione/include/campione_params.hpp`.

- The constructor does **not** start networking. `activate()` (`:718–729`)
  starts `CampioneMcpServer` once on DSP activation, with `mcpEnabled_ = true`.
  Parameter `mcp_enabled` is boolean, automatable, and defaults to 1
  (`initParameter`, `:224–231`). Upstream's comment says scan/controller
  instances do not activate; this is an intended host behavior, not a universal
  guarantee about all scanners.
- `CampioneMcpServer::serve()` (`:262–297`) binds IPv4 **127.0.0.1**, trying
  **7220 through 7229** with a fresh server per failed bind. It installs POST
  handlers on `/` and `/mcp`. The handler/dispatcher has no token authentication,
  per-user authorization, session requirement, Origin check, or workspace path
  restriction. Loopback limits network reachability; it is not a local-user
  security boundary. Do not port-forward or proxy it to a wider network.
- Tools can inspect/load zones and paths, capture input audio, change parameters,
  preview/remove/clear zones, import/slice samples, and save/load patches.
  `normalize_zone`, `trim_zone`, `fade_zone`, and `reverse_zone` call
  `mcpEditZone()` (`CampionePlugin.cpp:1233–1258`), which saves to the zone's
  **original source WAV path**. `saveWavZone()` opens a binary output stream.
  This is destructive source-file editing, not just non-destructive DAW state.
  `save_patch` accepts a caller-selected path; privileges are those of the host.
- Ordinary UI/state operations also write files: recording, slicing, wavetable
  import, patch saving, and autosaving selected zone changes. The actual pinned
  default is **`$HOME/.vst3/campione-data`**, or `/tmp/.vst3/campione-data` if HOME
  is absent (`kDefaultDataDir`). Some MCP tool prose still says
  `~/campione_recordings`; prefer the implementation. `data_dir` handling creates
  the directory and may load `campione_autosave.ttl`; later changes may overwrite
  that autosave. Disabling MCP does not disable these UI/file capabilities.
- Turning MCP off calls `stop()` and resets the server. No explicit plugin
  destructor is defined: member `mcp_` is destroyed before the earlier-declared
  plugin state, invoking server destruction, `stop()` and thread join. There is
  no matching stop in a plugin `deactivate()` override, so do not assume host
  bypass, stopped transport, or UI closure removes the listener.
- Lifecycle caution: `start()` launches a thread while `serve()` replaces
  `svr_`; `stop()` accesses `svr_` without a shared lifecycle lock. Immediate
  activation/off/unload is a source-level race concern requiring stress tests,
  not a demonstrated runtime failure in this audit. Do not claim safe teardown
  merely because a join exists. If first activation occurs with MCP disabled,
  enabling later does not start it until another activation unless
  `mcpStarted_` was already set.

**Recommended policy:** allow free-package availability, but require explicit
operator acceptance before activating Campione in a trusted DAW session. For a
no-network deployment, isolate the plugin/host or use a separately reviewed
default-off/disabled-server patch; coordinator OFF and the zenity patch do not
disable Campione MCP. Use disposable copies of samples and a dedicated writable
data directory, with unrelated data read-only where practical. Do not expose it
as an automatically trusted agent tool. Agent access should require a separate
capability decision for reading paths, recording, and overwriting files.

### Sidecar: local default, optional loopback client

`plugins/sidecar/src/dpf/SidecarPlugin.cpp` defines `SourceMode::local = 0` and
initializes both the member and parameter default to Local. Construction creates
a local fallback phrase. Generating/retrying in Local uses local algorithms.
**It is not a default-on cloud client or listener.**

In Server mode, generation/retry starts a worker that sends an unauthenticated
plain HTTP POST to **`127.0.0.1:37371/openai`**. The request includes generation
controls and MIDI-derived guide pitch classes/range, not raw captured audio.
It neither starts nor bundles the coordinator. A separately run coordinator
can forward data to a cloud service, so localhost does not imply the complete
workflow stays offline. Keep Local selected unless the operator explicitly
authorizes that service and its data handling. Host-restored/automated Source
parameters can select Server.

The raw socket request has no explicit receive deadline/cancellation; destruction
joins an outstanding worker. A peer that accepts and stalls can therefore delay
unload. Exercise unavailable, malformed, stalled and disconnected peers during
host acceptance; the core phrase tests do not cover this wrapper lifecycle.

### Other file/network behavior

The literal source sweep found no additional application-level network clients
or listeners in the **46 installed plugins** beyond Campione and Sidecar. This
does not exclude normal X11/D-Bus UI IPC or system-library behavior. Rift's sample
loader reads selected WAV files. DPF's libSOFD file browser can persist recent
files under `$XDG_DATA_HOME/<appname>/recent`, falling back to
`$HOME/.local/share/<appname>/recent`; a read-only sample picker is not necessarily
zero-write UI behavior.

For future expansion, Midiscribe is noteworthy: `plugins/midiscribe/src/dpf/
MidiscribePlugin.cpp::run()` calls `MidiscribeCore::writeFile()` on the write
trigger. `plugins/midiscribe/src/midiscribe_core.hpp:99–117` uses
`std::ios::trunc`; default `exportPath` is `/tmp/midiscribe.mid`. It does blocking
file I/O from the processing path and can overwrite an existing export file.
It is buildable upstream but **excluded from this package's install allowlist**.

## Integration verification

The source audit above and package verification are separate activities. The
final derivation built successfully with **53 CTest tests passed, zero failed**,
assertions enabled, and `--no-tests=error`. Its integration check verified **46
VST3 bundles**, nonempty Linux shared libraries, installed license notices, and
absence of standalone binaries, LV2 and CLAP output directories. Both Campione
picker call sites are patched; a build-time guard rejects remaining `::popen`
calls in that UI source. No upstream installer is invoked.

For an uncommitted checkout (so Nix includes the new files without staging):

```sh
nix build --no-link --max-jobs 1 --cores 4 path:.#downspout
nix flake check path:.
```

After the new files are tracked, the ordinary `.#downspout` flake reference works
as well. No site-lab configuration or host profile was changed.

## Tests reviewed and remaining acceptance checklist

`plugins/campione/tests/campione_core_tests.cpp` contains eleven core checks:
note on/off, gap fill, voice cap, loop wrap, playback rate, zone/parameter
serialization, empty deserialization, channel filtering, and missing REX2 input.
They do **not** instantiate the DPF wrapper or test MCP sockets, authentication,
destructive edits, port exhaustion, or rapid startup/shutdown. Sidecar's six core
tests cover phrase validation/determinism, text/JSON serialization, scheduled
notes and mute; they do not test its socket worker or unload. Assertions must
remain enabled when running these tests.

- [x] Build the pinned source plus reviewed patches; run CTest with assertions
  enabled and record the results separately from this source audit.
- [x] Verify exactly the 46 expected `.vst3` bundles, nonempty Linux shared
  libraries, installed notices, and absence of coordinator, helper scripts,
  sample collections and accidentally installed extra plugin targets.
- [ ] Verify no VelociLoops detection and no unintended runtime font dependency.
  Open representative UIs, including Campione and shared generative panels.
- [x] Review **both** zenity call sites in pinned `CampioneUI.cpp`: the main
  Load action around `:509–553` and `triggerZenityOrFallback()` at `:2225–2269`.
  The final patch covers both; the initial patch covered only the first.
- [ ] Exercise context-menu load/import as well as main Load, cancellation,
  spaces/non-ASCII filenames and repeated open/close; document single-file
  fallback behavior rather than promising zenity's multi-selection.
- [ ] In an isolated host, verify scan/controller behavior, first activation,
  MCP-off before/after activation, transport stop, bypass/deactivation, UI close,
  unload and reload. Check listeners actually disappear when expected.
- [ ] Exercise multiple Campione instances and all-ten-ports-busy behavior;
  verify IPv4 loopback-only binding and no unintended externally reachable
  socket. Stress immediate activation/disable/unload and active-request teardown.
- [ ] With disposable samples only, verify source overwrite semantics, patch
  save/load, recording/slice/import output and autosave location. Verify denied
  writes fail safely and shared data directories do not unexpectedly overwrite
  another instance's work.
- [ ] Confirm Sidecar Local emits no application network requests; separately
  authorize and test Server mode against a controlled loopback service, including
  stalled-peer unload. Do not use a production cloud credential for this test.
- [ ] Test DAW audio/MIDI routing, transport, saved-state restoration, rendering,
  editor lifetime and multi-instance isolation. Compilation and core tests alone
  are not host acceptance or real-time safety evidence.
