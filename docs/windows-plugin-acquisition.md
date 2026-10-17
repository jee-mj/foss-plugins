# Windows plugin acquisition manifest

Research snapshot: **2026-10-17**. This portable manifest records **24 unique
acquisition candidates** for eventual Windows DAW use under Wine. No artifact
was downloaded, installed or tested by this documentation task.

See the [catalog guide](audio-catalog.md) for the distinction between cataloged,
packaged, selected, acquired, built and runtime-tested software, and the
[104-repository catalog](../catalog/audio-104.json) for wider discovery.

## Finite scope and evidence

This batch is the **original 13 Basilica products**, plus the **original 14
Wine/both catalog proposals**, minus three shared identities:
**13 + 14 − 3 = 24**. The catalog's later target changes do not silently add
candidates to this dated acquisition batch. The ten Basilica products outside
the 104 captured repositories receive no invented AUDIO IDs.

- **22 candidates** have selected official GitHub release assets: **20
  non-installer ZIP candidates**, **1 installer ZIP** (Caravan) and **1 EXE
  installer** (OpenVoxTuner).
- **21 selected assets** have an upstream GitHub SHA-256 digest. Caravan's
  digest is explicitly **null**.
- **2 candidates** have unresolved manual/external acquisition routes:
  Giannitune and TimeLagFilter. No release version, asset filename, download
  URL, size or digest is fabricated for either.

The selected URLs below are the literal official `browser_download_url` values
in the supplied research, not guessed paths, mirrors or moving `latest` links.
All 22 selected releases were non-prereleases. Sizes are exact API byte counts.
Digests are upstream GitHub API values, shown with the `sha256:` algorithm
prefix; **they are not locally computed hashes or detached signatures**.

Archive names, README descriptions, release notes and installer source are
upstream evidence. A non-installer ZIP is a manual-copy **candidate**, not
proof of portability, inspected contents or compatibility. All 24 candidates
remain **not acquired by this manifest**, integration **not-started**, build
and runtime verification **not-tested**, and Wine compatibility **unknown**.
No prior local files, installed state or deployment are asserted.

## Original Basilica suite — 13 selected archives

Upstream documentation reports Windows x64 VST3/standalone distribution with
no established Linux release route. These selected Windows ZIPs have not been
inspected; exact plugin bundles, runtime dependencies and host behavior remain
unverified. AGPL evidence is informational for acquisition, not a compatibility
finding. Pre-1.0 versions and reported unsigned binaries remain upstream facts.

| Canonical ID / product | AUDIO alias | Exact release tag | Official asset URL / exact filename | Bytes | Upstream digest |
| --- | --- | --- | --- | ---: | --- |
| BA-001 Overture | — | `v0.5.0` | [overture-v0.5.0-windows.zip](https://github.com/basilica-audio/Overture/releases/download/v0.5.0/overture-v0.5.0-windows.zip) | 27860534 | `sha256:2f9cdde01ae637524075037909f7af6293d211a6d15e36ab5c7eb7b1483c1380` |
| BA-002 Tenebrae | — | `v0.5.0` | [tenebrae-v0.5.0-windows.zip](https://github.com/basilica-audio/Tenebrae/releases/download/v0.5.0/tenebrae-v0.5.0-windows.zip) | 10056412 | `sha256:bf42442e8074a36c94025ea1d3796540a03e715f41cad2946fe074dedd330e71` |
| BA-003 Nave | — | `v0.5.0` | [nave-v0.5.0-windows.zip](https://github.com/basilica-audio/Nave/releases/download/v0.5.0/nave-v0.5.0-windows.zip) | 27724646 | `sha256:06a94573ee3e812f8db2d6645040b4bb5d5f1c464204e22cebc3d07b233c179f` |
| BA-004 Silentium | AUDIO-058 | `v0.5.0` | [silentium-v0.5.0-windows.zip](https://github.com/basilica-audio/Silentium/releases/download/v0.5.0/silentium-v0.5.0-windows.zip) | 31439781 | `sha256:6b06eb92892da9f619bf2a9bdf8b3d748edda88ca7cec4b4a44300a6d69109e3` |
| BA-005 Requiem | — | `v0.5.0` | [requiem-v0.5.0-windows.zip](https://github.com/basilica-audio/Requiem/releases/download/v0.5.0/requiem-v0.5.0-windows.zip) | 9935453 | `sha256:d55ddc215490bb259a6ee0cdf71d89e0758f40a34c37750e88c8e59ec3b7a434` |
| BA-006 Seraph | AUDIO-007 | `v0.4.0` | [seraph-v0.4.0-windows.zip](https://github.com/basilica-audio/Seraph/releases/download/v0.4.0/seraph-v0.4.0-windows.zip) | 3556855 | `sha256:c93bb0e6af3b7eb89e502ca0d8d0a43060bb12f5971aa5f789050f7b03d799d9` |
| BA-007 Aureate | — | `v0.5.0` | [aureate-v0.5.0-windows.zip](https://github.com/basilica-audio/Aureate/releases/download/v0.5.0/aureate-v0.5.0-windows.zip) | 5208166 | `sha256:205c2039a021b73066696e89a92fc11e3b55a3b4857b5dde717022ef117ca810` |
| BA-008 Firmament | — | `v0.4.0` | [firmament-v0.4.0-windows.zip](https://github.com/basilica-audio/Firmament/releases/download/v0.4.0/firmament-v0.4.0-windows.zip) | 6979784 | `sha256:18f49efc1e818cbcb6b952e85d7f7ab3365f44753ae5f0362a6bf7fe520e84f8` |
| BA-009 Triptych | — | `v0.6.0` | [triptych-v0.6.0-windows.zip](https://github.com/basilica-audio/Triptych/releases/download/v0.6.0/triptych-v0.6.0-windows.zip) | 3552215 | `sha256:6fa1e00e8e459f179a69f9b2ae442da65022f7a0234e839172f786053d0b7cff` |
| BA-010 Apotheosis | — | `v0.6.1` | [apotheosis-v0.6.1-windows.zip](https://github.com/basilica-audio/Apotheosis/releases/download/v0.6.1/apotheosis-v0.6.1-windows.zip) | 61472785 | `sha256:ae2c3306afe53560f36f7a2e03851b4e5eca64d12e4a4e6ff96201c2c2bd6d00` |
| BA-011 Crypta | — | `v0.4.1` | [crypta-v0.4.1-windows.zip](https://github.com/basilica-audio/Crypta/releases/download/v0.4.1/crypta-v0.4.1-windows.zip) | 5370059 | `sha256:97cab64dfdcb11d9c4a0af857554859e0853b95ea9c34b94fc4e80e1b93b0441` |
| BA-012 Lancet | — | `v0.5.0` | [lancet-v0.5.0-windows.zip](https://github.com/basilica-audio/Lancet/releases/download/v0.5.0/lancet-v0.5.0-windows.zip) | 3049837 | `sha256:27bacbae84453224bee68f0c8ae4fe9c26582c34217f550a2d8400a6dec3540c` |
| BA-013 Miserere | AUDIO-003 | `v0.7.0` | [miserere-v0.7.0-windows.zip](https://github.com/basilica-audio/Miserere/releases/download/v0.7.0/miserere-v0.7.0-windows.zip) | 3548566 | `sha256:a1730eb2978eab5e8db6d2bfb433d2afc0070c519298b254acc2e5ae5c7a0ac0` |

Crypta `v0.4.1` has its Windows ZIP and checksum sidecar; there is no need to
substitute `v0.4.0` for this Windows selection. The sidecar was not fetched and
its own asset digest must not be confused with the ZIP digest.

## Additional catalog proposals — 9 selected assets

These AUDIO IDs have no BA alias. Caravan preserves the original `both`
proposal: native Linux source comparison plus Windows fallback. The remaining
eight preserve their original `wine` proposal.

| ID / product | Exact release tag | Official asset URL / exact filename | Bytes | Upstream digest |
| --- | --- | --- | ---: | --- |
| AUDIO-018 Dihtortion | `v2.0.0` | [Dihtortion-2.0.0-win64.zip](https://github.com/ClyntiaAikaHanaa/Dihtortion/releases/download/v2.0.0/Dihtortion-2.0.0-win64.zip) | 4853200 | `sha256:c6ffc21d51360eb06023ec39032870bc2d2ed36973b5cd12c4aeebaf3faaeef2` |
| AUDIO-025 Lazerator | `v1.1.0` | [Lazerator-1.1.0-win64.zip](https://github.com/ClyntiaAikaHanaa/Lazerator/releases/download/v1.1.0/Lazerator-1.1.0-win64.zip) | 2785364 | `sha256:3acb6650f604cd9d0772296529432e22118fe407c54413876c047d86580ddc86` |
| AUDIO-039 GuitarStrumSequencer | `v1.1.1` | [GuitarStrumSequencer-Windows.zip](https://github.com/allenloves/GuitarStrumSequencer/releases/download/v1.1.1/GuitarStrumSequencer-Windows.zip) | 2875294 | `sha256:482b2b8c86b25aa30665900e1707eac21e089449f124c66a00664d4008a94a97` |
| AUDIO-043 Dispenser | `v1.0.0` | [Dispenser.vst3.zip](https://github.com/wheatBread1306/Dispenser/releases/download/v1.0.0/Dispenser.vst3.zip) | 2086031 | `sha256:012179f0b615473da8a79c348c23e6be5462797cc4a8c6c05079d6f525deec0e` |
| AUDIO-048 OpenVoxTuner | `v0.1.71` | [OpenVoxTuner_Windows_Installer.exe](https://github.com/EiffelBS/OpenVoxTuner/releases/download/v0.1.71/OpenVoxTuner_Windows_Installer.exe) | 4835691 | `sha256:5c5e66fb6efaa03cd8d120a70b25f0d289715d8e76a0be3af1b5ed49b48f1c82` |
| AUDIO-052 Caravan | `1.0.1` | [caravan-windows-installer.zip](https://github.com/biferdou/Caravan/releases/download/1.0.1/caravan-windows-installer.zip) | 9159140 | **null — not provided by GitHub** |
| AUDIO-054 MegaCrusher | `v1.0.2` | [MegaCrusher-1.0.2-win-x64.zip](https://github.com/lluisestape-upc/MegaCrusher/releases/download/v1.0.2/MegaCrusher-1.0.2-win-x64.zip) | 2349374 | `sha256:5f909be8d2ec8116523d5c084ed22a442a8d7526b8c6a6d2ffba7dbb0d9f768e` |
| AUDIO-098 AX330G | `v0.12.0.25` | [AX330G-0.12.0.25-windows-x64.zip](https://github.com/neglectware/ax330g/releases/download/v0.12.0.25/AX330G-0.12.0.25-windows-x64.zip) | 3310571 | `sha256:363db751844f76ee3b26c75e4759248b59cd96df0fdb3d4d50b29ecaa2b61736` |
| AUDIO-102 VDX7 | `v1.2.0` | [VDX7-1.2.0-Windows-x64-Manual.zip](https://github.com/RobCZart82/VDX7-JUCE/releases/download/v1.2.0/VDX7-1.2.0-Windows-x64-Manual.zip) | 32854139 | `sha256:7656d0795e50bd26bb52994f70ee4fdf4423759dc1b88fea581a66020e28a6d2` |

### Payload and usability qualifications

- **Dihtortion:** Windows x64 VST3 ZIP; cabinet/room IR loading needs testing.
- **Lazerator:** Win64 VST3/standalone targets. ZIP selected over Setup EXE;
  complete payload and dependencies remain uninspected.
- **GuitarStrumSequencer:** release notes explicitly identify Windows VST3
  x64. Requires host MIDI output/routing into a separate instrument; it is not
  a sampled guitar.
- **Dispenser:** README identifies Windows prebuilt binaries, x64 and AVX2.
  The VST3 ZIP is selected instead of the standalone ZIP. **AVX2 capability is
  a real CPU prerequisite**, not a copyright issue.
- **OpenVoxTuner:** **installer-only Windows fallback**; no portable Windows
  archive attached. The [tagged installer source](https://github.com/EiffelBS/OpenVoxTuner/blob/v0.1.71/installer/OpenVoxTuner.iss)
  declares `ArchitecturesInstallIn64BitMode=x64compatible` and 64-bit VST3
  destinations. Optional OpenVoxKey/standalone components are not separate
  acquired products here. `AppVersion=0.1.0` is stale relative to tag
  `v0.1.71`; record actual installed/plugin versions later. ARA2 and MIDI
  integration need independent host checks; source declarations do not prove
  the EXE payload architecture.
- **Caravan:** **installer ZIP, not confirmed portable**. Upstream specifies
  Windows 10+ 64-bit VST3; no portable alternative is attached. Tag `1.0.1`
  differs from the release body's `v0.1.0`. GitHub supplies no ZIP digest;
  independent checksum evidence remains unchecked. Linux source comparison
  remains a separate route.
- **MegaCrusher:** explicit win-x64 VST3 archive/build route; preserve the
  project's GPL/AGPL dependency evidence when considering distribution.
- **AX330G:** Windows x64 VST3 ZIP. Upstream says Windows releases from 0.9.0
  onward are untested; no local Wine result exists.
- **VDX7:** manual-install Windows x64 VST3 ZIP selected over Setup EXE.
  **Requires a legally obtained, user-supplied original DX7 Mk I v1.8 ROM.**
  No firmware acquisition or packaging is included. AU and standalone are
  source targets, not shipped Windows plugin formats in this selection.

## Two unresolved acquisition records

| ID / repository | Observed official route | Exact release/asset metadata | Missing evidence |
| --- | --- | --- | --- |
| AUDIO-004 Giannitune — `jonnygucci1/Giannitune` | [Official README](https://github.com/jonnygucci1/Giannitune/blob/master/README.md) links the [Gumroad product page](https://jonnygucci.gumroad.com/l/giannitune). | Release version, selected filename, binary download URL, bytes and digest **unset/unverified**; no GitHub releases. | README documents Windows 10+ x64 VST3 and one installer per platform. Resolve the actual Windows artifact/version and metadata through the official external route; the product page is a lead, not a verified binary URL. |
| AUDIO-042 TimeLagFilter — `sauraen/timelagfilter` | [Official README](https://github.com/sauraen/timelagfilter/blob/master/README.md) directs to `bin/TimeLagFilter.dll` for x64 and `TimeLagFilter32.dll` for x86. | No versioned GitHub release; selected release version, raw binary URL, filename selection, bytes and digest **unset/not applicable to a release asset**. | Pin a repository commit and examine public file metadata before acquisition. Resolve the README VST3 claim versus DLL naming and actual host format/layout; no raw binary URL was selected. |

For both, the captured latest-release API response was 404 and the release
list was empty. They are missing **selected versioned release artifacts**, not
proven impossible to obtain. OpenVoxTuner and Caravan have explicit installer
artifacts despite lacking a verified portable Windows alternative.

## Portable destination and later workflow

A consumer may choose any download location. For example,
`$HOME/Downloads/win-installer` is an **optional destination example**, with the
exact linked filename appended for each selected asset. It is not required to
exist, be public or be used by any project wrapper. This guide has not checked
or created that directory, and does not assert that any file is present there.
The unresolved records have no selected local filename.

For an eventual acquisition:

1. Choose an official artifact and record the exact URL, release and filename.
   Compare downloaded bytes with the recorded byte count and upstream digest
   where supplied; compute and record a local SHA-256 for every acquired file.
   Caravan needs a local pin because its upstream API digest is null. A
   self-computed hash identifies bytes, not independent authenticity.
2. Inspect the actual Windows PE architecture, plugin format/bundle layout,
   required resources and runtime dependencies. Preserve complete bundles.
   Record actual plugin/installed versions when labels differ.
3. **Windows host under Wine:** investigate installation/manual copying into
   the Wine environment used by a Windows x64 DAW, using that host's supported
   plugin locations. Validate scanning, GUI, audio/MIDI, sidechain where
   relevant, latency, automation and save/reopen. Wine support is untested for
   every candidate here.
4. **Native Linux host with a bridge:** use a suitable Windows-plugin bridge
   and separately validate its Wine/architecture/format/host requirements.
   Windows-DAW-under-Wine success does not establish bridged native-host
   compatibility, or vice versa. Acquisition does not itself require bridge
   synchronization or any private runtime CLI.

These are future workflow descriptions, not operations performed by this
documentation. An archive or installer removes no CPU, IR, MIDI-routing or ROM
prerequisite. Native Linux alternatives, when evidenced, remain independent
download/source routes described by the catalog.

## Copyright and consumer judgement

Missing or unclear license evidence is **informational, not an automatic
technical implementation or acquisition gate** under this catalog's user
policy. Consumers are encouraged to review evidence and exercise their own
judgement about use, modification and distribution. Unknown is not a grant,
and explicit EULA, redistribution, activation, dependency and firmware terms
remain facts; catalog inclusion does not override them.

**AI-assisted development, AI processing and generated material never imply a
copyright exemption or copyright-free code, models, samples or outputs.**
Repository licenses and model/content/dependency terms can differ. The catalog
tracks copyright as `not-audited`, with consumer judgement required and no
automatic implementation gate.

## Accounting

| Category | Count |
| --- | ---: |
| Original Basilica records | 13 |
| Original catalog Wine/both records represented | 14 |
| Shared BA/AUDIO identities, counted once | 3 |
| Unique candidates | **24** |
| Selected release assets | **22** |
| Selected assets with upstream digests | **21** |
| Selected assets with null upstream digest | **1** |
| Unresolved manual/external records | **2** |
| Artifacts acquired by this documentation task | **0** |

The selected URLs, tags, sizes and upstream digests reproduce the supplied
2026-10-17 acquisition research. No fresh upstream release search or binary
inspection is implied.
